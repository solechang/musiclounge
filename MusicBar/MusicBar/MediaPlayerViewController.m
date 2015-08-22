//
//  iLLMediaPlayerViewController.m
//  iLList
//
//  Created by Jake Choi on 12/26/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import "MediaPlayerViewController.h"
#import "FriendSearchSongsTableViewController.h"
#import <Parse/Parse.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "AFNetworking.h"

//#import "iLLApiClient.h"

// CoreData
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"
#import "Playlist.h"
#import "Song.h"
#import "SongManager.h"
#import "NowPlaying.h"
#import "NowPlayingSong.h"

#import <SVProgressHUD/SVProgressHUD.h>

#import "FSAudioStream.h"
#import "FSAudioController.h"
#import "FSPlaylistItem.h"

#import <MediaPlayer/MediaPlayer.h>

static NSString *const clientID = @"fc8c97d1af51d72375bf565acc9cfe60";

@interface MediaPlayerViewController ()
{

    MPNowPlayingInfoCenter *nowPlayingInfo;
    
    FSAudioController *audioController;
    
    FSAudioStream *audioStream;
    NSTimer* timer;
    
    NSMutableArray *currentPlayList;
    
    NSManagedObjectContext *defaultContext;
    
    BOOL flagSong; // flags currently playing song
    
    NowPlayingSong *currentSong;
}



@property (nonatomic,strong) NSTimer *progressUpdateTimer;
@property (nonatomic,strong) NSTimer *playbackSeekTimer;
@property (nonatomic,assign) double seekToPoint;
@property (nonatomic,assign) BOOL enableLogging;
@property (nonatomic,assign) float volumeBeforeRamping;

@property (nonatomic,assign) int rampStep;
@property (nonatomic,assign) int rampStepCount;
@property (nonatomic,assign) bool rampUp;
@property (nonatomic,assign) SEL postRampAction;

@property (nonatomic,strong) NSTimer *volumeRampTimer;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *currentPlaylistButton;
@property (weak, nonatomic) IBOutlet UISlider *musicSlider;
@property (weak, nonatomic) IBOutlet UIImageView *currentSongArtwork;
@property (weak, nonatomic) IBOutlet UILabel *startTime;
@property (weak, nonatomic) IBOutlet UILabel *endTime;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (weak, nonatomic) IBOutlet UILabel *songTitle;


@end

@implementation MediaPlayerViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Instantiate the audio player
    [self setNSManagedObjectContext];
    [self setUpNavigationBar];
    [self setUpData];

    
   
}
- (void) setUpNavigationBar {
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
}

- (void) setUpData {
     audioController = [[FSAudioController alloc] init];
    
    self.userPlaylistItems = [[NSMutableArray alloc] init];

    currentPlayList = [[NSMutableArray alloc] init];
    
    [self.currentPlaylistButton setEnabled:NO];
    [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];

    [self.playButton setEnabled:NO];
}

- (void) setNSManagedObjectContext {
    
    defaultContext = [NSManagedObjectContext MR_defaultContext];
}

- (void)viewWillAppear:(BOOL)animated {
    
    __weak typeof(self) weakSelf = self;
    audioController.onStateChange = ^(FSAudioStreamState state) {
        switch (state) {
                
            case kFsAudioStreamRetrievingURL:
                NSLog(@"1.1.)");
                
                break;
                
            case kFsAudioStreamStopped:
                 NSLog(@"1.2.)");
                
                break;
                
            case kFsAudioStreamBuffering: {
                NSLog(@"1.3.)");
               
                break;
            }
                
            case kFsAudioStreamSeeking:
                
                NSLog(@"1.4.)");
                
                break;
                
            case kFsAudioStreamPlaying:
                
                NSLog(@"1.5.)");
                weakSelf.enableLogging = YES;

                weakSelf.musicSlider.enabled = YES;
                
                if (!weakSelf.progressUpdateTimer) {
                    weakSelf.progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                                                    target:weakSelf
                                                                                  selector:@selector(updatePlaybackProgress)
                                                                                  userInfo:nil
                                                                                   repeats:YES];
                }
                
                if (weakSelf.volumeBeforeRamping > 0) {
                    // If we have volume before ramping set, it means we were seeked
                    
#if PAUSE_AFTER_SEEKING
                    [weakSelf pause:weakSelf];
                    weakSelf.audioController.volume = weakSelf.volumeBeforeRamping;
                    weakSelf.volumeBeforeRamping = 0;
                    
                    break;
#else
                    weakSelf.rampStep = 1;
                    weakSelf.rampStepCount = 5; // 50ms and 5 steps = 250ms ramp
                    weakSelf.rampUp = true;
                    weakSelf.postRampAction = @selector(finalizeSeeking);
                    
                    weakSelf.volumeRampTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 // 50ms
                                                                                target:weakSelf
                                                                              selector:@selector(rampVolume)
                                                                              userInfo:nil
                                                                               repeats:YES];
#endif
                }
                [weakSelf toggleNextPreviousButtons];

                
//                [weakSelf.stateLogger logMessageWithTimestamp:@"State change: playing"];

                break;
                
            case kFsAudioStreamFailed:
                NSLog(@"1.6.)");
                 [weakSelf.startTime setText:@"This song cannot be played. Please delete song :("];
                
                break;
            case kFsAudioStreamPlaybackCompleted:
                NSLog(@"1.7.)");
//                [weakSelf toggleNextPreviousButtons];
                [weakSelf nextButton:nil];
                break;
                
            case kFsAudioStreamRetryingStarted:
                NSLog(@"1.8.)");
                weakSelf.enableLogging = YES;

                
                break;
                
            case kFsAudioStreamRetryingSucceeded:
                NSLog(@"1.9.)");
                weakSelf.enableLogging = YES;

                break;
                
            case kFsAudioStreamRetryingFailed:
                NSLog(@"1.10.)");
                [weakSelf nextButton:nil];
                break;
                
            default:
                NSLog(@"1.11.)");
                break;

                
        }
    };
    
}

- (void)addUserPlaylistItems
{
    for (FSPlaylistItem *item in self.userPlaylistItems) {
        BOOL alreadyInPlaylist = NO;
        
        for (FSPlaylistItem *existingItem in self.playlistItems) {
            if ([existingItem isEqual:item]) {
                
                alreadyInPlaylist = YES;
                
                break;
            }
        }
        
        if (!alreadyInPlaylist) {
            [self.playlistItems addObject:item];
        }
    }
}


- (void)updatePlaybackProgress
{
//    NSLog(@"0.)");
//
    if (audioController.activeStream.continuous) {
//            NSLog(@"0.1)");
        self.musicSlider.enabled = NO;
        self.musicSlider.value = 0;
        self.startTime.text = @"Loading";
        self.playButton.enabled = NO;
    } else {
//        NSLog(@"0.2)");
        self.musicSlider.enabled = YES;
        self.playButton.enabled = YES;
        
        FSStreamPosition cur = audioController.activeStream.currentTimePlayed;
        FSStreamPosition end = audioController.activeStream.duration;
        
        self.musicSlider.value = cur.position;
        
        self.startTime.text = [NSString stringWithFormat:@"%i:%02i / %i:%02i",
                                         cur.minute, cur.second,
                                         end.minute, end.second];
    }
    
//    self.bufferingIndicator.hidden = NO;
//    self.prebufferStatus.hidden = YES;
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    _progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                            target:self
                                                          selector:@selector(updatePlaybackProgress)
                                                          userInfo:nil
                                                           repeats:YES];

    
      
    [self checkNowPlayingPlaylistId];
    

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Make sure we can recieve remote control events
- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                NSLog(@"prev");
                [self backButton:self];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                NSLog(@"next");
                [self nextButton:self];
                break;
                
            case UIEventSubtypeRemoteControlPlay:
                [self playButton:self];
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [self playButton:self];
                break;
                
            default:
                break;
        }
    }
}
- (void) checkNowPlayingPlaylistId {
    
    NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:defaultContext];

    if ([nowPlaying.playlistId isEqualToString:@""]) {
        
        NSLog(@"No songs to be played");
        
    } else {

        [self getSongsFromLocal: nowPlaying];
    }
    
}

#pragma mark - setCurrentPlayList
- (void) getSongsFromLocal: (NowPlaying* )nowPlaying {

//    NSArray *nowPlayingSongsArray = [NowPlayingSong MR_findByAttribute:@"playlistId" withValue:nowPlaying.playlistId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    NSArray *nowPlayingSongsArray = [NowPlayingSong MR_findByAttribute:@"playlistId" withValue:nowPlaying.playlistId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    currentPlayList = [[NSMutableArray alloc] initWithArray:nowPlayingSongsArray];
    
    NowPlayingSong *nowplayingSong = [currentPlayList objectAtIndex:[nowPlaying.songIndex integerValue]];
    
    
    // Checks if same song is playing,so the mediaplayer doesn't have to rebuffering
    if (![self checkCurrentSong: nowplayingSong]) {
        
//        NSString *resourceURL = [NSString stringWithFormat:@"%@.json?client_id=%@", nowplayingSong.stream_url ,clientID];
//        NSURL* url = [NSURL URLWithString:resourceURL];
//        audioController.url = url;
//        [audioController playFromURL:url];
        
//        for (NowPlayingSong *nowPlaying in nowPlayingSongsArray) {
//
//            FSPlaylistItem *item = [[FSPlaylistItem alloc] init];
//            item.title = nowPlaying.title;
//
//            NSString *resourceURL = [NSString stringWithFormat:@"%@.json?client_id=%@", nowPlaying.stream_url ,clientID];
//            NSURL* url = [NSURL URLWithString:resourceURL];
//            item.url = url;
//            
//            [self.userPlaylistItems addObject:item];
//            [audioController addItem:item];
//            
//        }
        
        
        [self setCurrentPlaylist];

    }

}

#pragma mark - Check current playlist

- (BOOL) checkCurrentSong: (NowPlayingSong*) songNow {
   
    if ([currentSong.objectId isEqualToString:songNow.objectId]) {
        
        return YES;
        
    }
    
    return NO;
    
}


#pragma mark - Set current play list
- (void) setCurrentPlaylist {

  
//    [self setupTimer];
//    [self updateControls];
    
    [self.currentPlaylistButton setEnabled:YES];

    [self playSong];


}

//- (void) playRTMPIfErrorInSoundCloud {
//    
//    NSString *trackID = [self getTrackID:currentILListDictionary[@"stream_url"]];
//    
//    NSString *url = [NSString stringWithFormat:@"i1/tracks/%@/streams?client_id=%@", trackID, clientID];
//    NSLog(@"1.) %@", url);
//    flagSong = YES;
//    
//    // Checks if http_mp3_128_url exists to play music
//    [[iLLApiClient sharedClient] GET:url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
//        
//        NSDictionary *i1Response = responseObject;
//        
//        if ([i1Response objectForKey:@"http_mp3_128_url"]) {
//            
//            NSLog(@"2.) %@", i1Response);
//            
//            NSString *resourceURL = [i1Response objectForKey:@"http_mp3_128_url"];
//            
//            NSURL* url = [NSURL URLWithString:resourceURL];
//            STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];
//            [nowPlayingPlayer setDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0]];
//        } else {
//            NSString *resourceURL = currentILListDictionary[@"stream_url"];
//
//            NSURL* url = [NSURL URLWithString:resourceURL];
//            STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];
//            [nowPlayingPlayer setDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0]];
//        }
//        
//    } failure:^(NSURLSessionDataTask *task, NSError *error) {
//        
//        NSLog(@"Error: %@", error);
//    }];
//    
//}

- (NSString*) getTrackID: (NSString*)stream {
    NSString *param = nil;
    NSRange start = [stream rangeOfString:@"tracks/"];
    if (start.location != NSNotFound)
    {
        param = [stream substringFromIndex:start.location + start.length];
        NSRange end = [param rangeOfString:@"/stream"];
        if (end.location != NSNotFound)
        {
            param = [param substringToIndex:end.location];
        }
    }
    
    return param;
}

#pragma mark - Buttons

- (IBAction)currentPlaylistButtonPressed:(id)sender {
    
    [self performSegueWithIdentifier:@"currentPlaylistNowPlayingSegue" sender:self];
    
}

#pragma mark - Play button

- (IBAction)playButton:(id)sender {
    

    [audioController pause];

    if ([self.playButton.titleLabel.text isEqualToString:@"Pause"]) {

        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];

    } else {

        [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];

    }
   
    
}

- (IBAction)nextButton:(id)sender {
    // stopping audio player when next song plays
    [audioController stop];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:localContext];
        
        int nowPlayingIndex = [nowPlaying.songIndex intValue];
        //         if index is end of currentPlayList, set index to 0, if not increment index
        if (nowPlayingIndex == currentPlayList.count - 1 ) {
            nowPlayingIndex = 0;
            
        } else {
            nowPlayingIndex++;
            
        }
        
        nowPlaying.songIndex = [NSNumber numberWithInt:nowPlayingIndex];
        
        
    } completion:^(BOOL success, NSError *error) {
        
        if (success) {
            [self playSong];
            
        } else {
            NSLog(@"Error 503.)");
        }
        
    }];
    

 

}
//
- (void) playSong {
    
    NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:defaultContext];
    
    NowPlayingSong *nowplayingSong = [currentPlayList objectAtIndex:[nowPlaying.songIndex integerValue]];
    
    currentSong = nowplayingSong;
    
    self.currentPlaylistButton.title = nowPlaying.playlistName;
    
    self.songTitle.text = nowplayingSong.title;
    
    [self.currentSongArtwork sd_setImageWithURL:[NSURL URLWithString:[self setImageSize:nowplayingSong.artwork] ] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageRefreshCached];
    
    NSString *resourceURL = [NSString stringWithFormat:@"%@.json?client_id=%@", nowplayingSong.stream_url ,clientID];
    NSURL* url = [NSURL URLWithString:resourceURL];
    audioController.url = url;
    
    [audioController play];
    
    
    flagSong = NO;
    
    [self setLockScreenSongInfo :nowplayingSong];


}
- (void) calculateSongBySeconds {
    
    
}
- (void) setLockScreenSongInfo : (NowPlayingSong*)nowPlayingSong{
    NSLog(@"1.) %@", nowPlayingSong.time);
//    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc]initWithImage:self.currentSongArtwork];
    NSDictionary *info = @{ MPMediaItemPropertyArtist: @"",
                            MPMediaItemPropertyAlbumTitle: @"",
                            MPMediaItemPropertyTitle: self.songTitle.text,
                            MPMediaItemPropertyPlaybackDuration:nowPlayingSong.time,
                            MPNowPlayingInfoPropertyPlaybackRate: [NSNumber numberWithInt:1]
                            };
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
}

- (IBAction)backButton:(id)sender {
    // stop audio player when going back a song
    [audioController stop];
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:localContext];
        
        NSUInteger nowPlayingIndex = [nowPlaying.songIndex integerValue];

        // if index is end of currentPlayList, set index to 0, if not increment index
        if (nowPlayingIndex ==  0) {
            NSUInteger currentPlayListCount = currentPlayList.count;
            nowPlayingIndex = currentPlayListCount - 1;
            
        } else {
            nowPlayingIndex--;

        }
        
        nowPlaying.songIndex = [NSNumber numberWithInteger:nowPlayingIndex];

    } completion:^(BOOL success, NSError *error) {
        
        if (success) {
            [self playSong];
            
        } else {
            NSLog(@"Error 382.)");
        }
        
    }];

    
}
//
#pragma mark - Music slider
- (IBAction)musicSlider:(id)sender {

    [self sliderChanged];
}

- (void)finalizeSeeking
{
    _volumeBeforeRamping = 0;
}

-(void) sliderChanged
{
    _seekToPoint = self.musicSlider.value;
   
    [_progressUpdateTimer invalidate], _progressUpdateTimer = nil;
    
    [_playbackSeekTimer invalidate], _playbackSeekTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                                           target:self
                                                                                         selector:@selector(seekToNewTime)
                                                                                         userInfo:nil
                                                                                          repeats:NO];

}

- (void)seekToNewTime {
    self.musicSlider.enabled = NO;
    
    // Fade out the volume to avoid pops
    _volumeBeforeRamping = audioController.volume;
    
    if (_volumeBeforeRamping > 0) {
        _rampStep = 1;
        _rampStepCount = 5; // 50ms and 5 steps = 250ms ramp
        _rampUp = false;
        _postRampAction = @selector(doSeeking);
        
        _volumeRampTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 // 50ms
                                                            target:self
                                                          selector:@selector(rampVolume)
                                                          userInfo:nil
                                                           repeats:YES];
    } else {
        // Just directly seek, volume is already 0
        [self doSeeking];
    }}

- (void)doSeeking
{
    FSStreamPosition pos = {0};
    pos.position = _seekToPoint;
    [audioController.activeStream seekToPosition:pos];
}

- (void)rampVolume
{
    if (_rampStep > _rampStepCount) {
        [_volumeRampTimer invalidate], _volumeRampTimer = nil;
        
        if (_postRampAction) {
            [self performSelector:_postRampAction withObject:nil afterDelay:0];
        }
        
        return;
    }
    
    if (_rampUp) {
        audioController.volume = (_volumeBeforeRamping / _rampStepCount) * _rampStep;
    } else {
        audioController.volume = (_volumeBeforeRamping / _rampStepCount) * (_rampStepCount - _rampStep);
    }
    
    _rampStep++;
}

-(void)toggleNextPreviousButtons
{
//    if([audioController hasNextItem] || [audioController hasPreviousItem])
//    {
//        NSLog(@"2.1.)");
//        self.nextButton.hidden = NO;
//        self.backButton.hidden = NO;
////        self.nextButton.enabled = [audioController hasNextItem];
////        self.backButton.enabled = [audioController hasPreviousItem];
//    }
//    else
//    {
//        NSLog(@"2.2.)");
//        self.nextButton.hidden = YES;
//        self.backButton.hidden = YES;
//    }
}


#pragma Set current song artwork size
- (NSString*) setImageSize:(NSString*)image {
    
    // Resizing artwork to 300 by 300 pixels
    NSString* resizeImage = [[NSString alloc] initWithString:image];
    
    resizeImage = [resizeImage stringByReplacingOccurrencesOfString:@"large" withString:@"t300x300"];
    return resizeImage;
}


//
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"currentPlaylistNowPlayingSegue"]) {
        UINavigationController *navController = [segue destinationViewController];
        FriendSearchSongsTableViewController *vc = (FriendSearchSongsTableViewController*)navController.topViewController;
        
        NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:defaultContext];
        PlaylistFriend *playlist = [PlaylistFriend MR_createEntity];
        playlist.objectId = nowPlaying.playlistId;
        
//        playlist.userName = playlistObject[@"userName"];
//        playlist.createdAt = playlistObject.createdAt;
//        playlist.songCount = playlistObject[@"SongCount"];

        vc.playlistInfo = playlist;

    }

}


@end
