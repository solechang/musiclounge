//
//  iLLMediaPlayerViewController.m
//  iLList
//
//  Created by Jake Choi on 12/26/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import "MediaPlayerViewController.h"
#import "iLLFriendSearchSongsTableViewController.h"
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

static NSString *const clientID = @"fc8c97d1af51d72375bf565acc9cfe60";

@interface MediaPlayerViewController ()
{

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

    audioController = [[FSAudioController alloc] init];
    
    self.userPlaylistItems = [[NSMutableArray alloc] init];

    currentPlayList = [[NSMutableArray alloc] init];
    
    audioStream = [[FSAudioStream alloc] init];
    
    [self.currentPlaylistButton setEnabled:NO];
    
}

- (void) setNSManagedObjectContext {
    
    defaultContext = [NSManagedObjectContext MR_defaultContext];
}

- (void)viewWillAppear:(BOOL)animated {
    __weak typeof(self) weakSelf = self;
    audioController.onStateChange = ^(FSAudioStreamState state) {
        switch (state) {
                
            case kFsAudioStreamRetrievingURL:
                NSLog(@"1.)");
//                weakSelf.enableLogging = NO;
//                
//                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//                
//                [weakSelf showStatus:@"Retrieving URL..."];
//                
//                weakSelf.statusLabel.text = @"";
//                
//                weakSelf.progressSlider.enabled = NO;
//                weakSelf.playButton.hidden = YES;
//                weakSelf.pauseButton.hidden = NO;
//                weakSelf.paused = NO;
//                
//                [weakSelf.stateLogger logMessageWithTimestamp:@"State change: retrieving URL"];
                
                break;
                
            case kFsAudioStreamStopped:
                NSLog(@"2.)");
//                weakSelf.enableLogging = NO;
//                
//                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//                
//                weakSelf.statusLabel.text = @"";
//                
//                weakSelf.progressSlider.enabled = NO;
//                weakSelf.playButton.hidden = NO;
//                weakSelf.pauseButton.hidden = YES;
//                weakSelf.paused = NO;
//                
//                [weakSelf.stateLogger logMessageWithTimestamp:@"State change: stopped"];
                
                break;
                
            case kFsAudioStreamBuffering: {
                NSLog(@"3.)");
//                if (weakSelf.initialBuffering) {
//                    weakSelf.enableLogging = NO;
//                    weakSelf.initialBuffering = NO;
//                } else {
//                    weakSelf.enableLogging = YES;
//                }
//                
//                NSString *bufferingStatus = nil;
//                if (weakSelf.configuration.usePrebufferSizeCalculationInSeconds) {
//                    bufferingStatus = [[NSString alloc] initWithFormat:@"Buffering %f seconds...", weakSelf.audioController.activeStream.configuration.requiredPrebufferSizeInSeconds];
//                } else {
//                    bufferingStatus = [[NSString alloc] initWithFormat:@"Buffering %i bytes...", (weakSelf.audioController.activeStream.continuous ? weakSelf.configuration.requiredInitialPrebufferedByteCountForContinuousStream :
//                                                                                                  weakSelf.configuration.requiredInitialPrebufferedByteCountForNonContinuousStream)];
//                }
//                
//                [weakSelf showStatus:bufferingStatus];
//                
//                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//                weakSelf.progressSlider.enabled = NO;
//                weakSelf.playButton.hidden = YES;
//                weakSelf.pauseButton.hidden = NO;
//                weakSelf.paused = NO;
//                
//                [weakSelf.stateLogger logMessageWithTimestamp:@"State change: buffering"];
                
                break;
            }
                
            case kFsAudioStreamSeeking:
                
                NSLog(@"4.)");
//                self.enableLogging = NO;
//
//                [weakSelf showStatus:@"Seeking..."];
//                
//                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//                weakSelf.progressSlider.enabled = NO;
//                weakSelf.playButton.hidden = YES;
//                weakSelf.pauseButton.hidden = NO;
//                weakSelf.paused = NO;
//                
//                [weakSelf.stateLogger logMessageWithTimestamp:@"State change: seeking"];
                
                break;
                
            case kFsAudioStreamPlaying:
                
                NSLog(@"5.)");
                weakSelf.enableLogging = YES;

                weakSelf.musicSlider.enabled = YES;
                
                if (!weakSelf.progressUpdateTimer) {
                    weakSelf.progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                                                    target:weakSelf
                                                                                  selector:@selector(updatePlaybackProgress)
                                                                                  userInfo:nil
                                                                                   repeats:YES];
                }
                
//                if (weakSelf.volumeBeforeRamping > 0) {
//                    // If we have volume before ramping set, it means we were seeked
//                    
//#if PAUSE_AFTER_SEEKING
//                    [weakSelf pause:weakSelf];
//                    weakSelf.audioController.volume = weakSelf.volumeBeforeRamping;
//                    weakSelf.volumeBeforeRamping = 0;
//                    
//                    break;
//#else
//                    weakSelf.rampStep = 1;
//                    weakSelf.rampStepCount = 5; // 50ms and 5 steps = 250ms ramp
//                    weakSelf.rampUp = true;
//                    weakSelf.postRampAction = @selector(finalizeSeeking);
//                    
//                    weakSelf.volumeRampTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 // 50ms
//                                                                                target:weakSelf
//                                                                              selector:@selector(rampVolume)
//                                                                              userInfo:nil
//                                                                               repeats:YES];
//#endif
//                }
//                [weakSelf toggleNextPreviousButtons];
//                weakSelf.playButton.hidden = YES;
//                weakSelf.pauseButton.hidden = NO;
//                weakSelf.paused = NO;
                
//                [weakSelf.stateLogger logMessageWithTimestamp:@"State change: playing"];
                
                break;
                
            case kFsAudioStreamFailed:
                NSLog(@"6.)");
//                weakSelf.enableLogging = YES;
//                
//                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//                weakSelf.progressSlider.enabled = NO;
//                weakSelf.playButton.hidden = NO;
//                weakSelf.pauseButton.hidden = YES;
//                weakSelf.paused = NO;
//                
//                [weakSelf.stateLogger logMessageWithTimestamp:@"State change: failed"];
                
                break;
            case kFsAudioStreamPlaybackCompleted:
                NSLog(@"7.)");
//                weakSelf.enableLogging = NO;
//                
//                [weakSelf toggleNextPreviousButtons];
//                
//                [weakSelf.stateLogger logMessageWithTimestamp:@"State change: playback completed"];
                
                break;
                
            case kFsAudioStreamRetryingStarted:
                NSLog(@"8.)");
                weakSelf.enableLogging = YES;
                
//                [weakSelf showStatus:@"Attempt to retry playback..."];
                
//                [weakSelf.stateLogger logMessageWithTimestamp:@"State change: retrying started"];
                
                break;
                
            case kFsAudioStreamRetryingSucceeded:
                NSLog(@"9.)");
                weakSelf.enableLogging = YES;
                
//                [weakSelf.stateLogger logMessageWithTimestamp:@"State change: retrying succeeded"];
                
                break;
                
            case kFsAudioStreamRetryingFailed:
                NSLog(@"10.)");
//                weakSelf.enableLogging = YES;
//                
//                [weakSelf showErrorStatus:@"Failed to retry playback"];
//                
//                [weakSelf.stateLogger logMessageWithTimestamp:@"State change: retrying failed"];
                
                break;
                
            default:
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
    NSLog(@"0.)");
//
//    if (audioController.activeStream.continuous) {
//            NSLog(@"0.1)");
//        self.musicSlider.enabled = NO;
//        self.musicSlider.value = 0;
//        self.startTime.text = @"";
//    } else {
        self.musicSlider.enabled = YES;
        
        FSStreamPosition cur = audioController.activeStream.currentTimePlayed;
        FSStreamPosition end = audioController.activeStream.duration;
        
        self.musicSlider.value = cur.position;
        
        self.startTime.text = [NSString stringWithFormat:@"%i:%02i / %i:%02i",
                                         cur.minute, cur.second,
                                         end.minute, end.second];
//    }
    
//    self.bufferingIndicator.hidden = NO;
//    self.prebufferStatus.hidden = YES;
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    _progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                            target:self
                                                          selector:@selector(updatePlaybackProgress)
                                                          userInfo:nil
                                                           repeats:YES];

    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    [self checkNowPlayingPlaylistId];
    

}

#pragma Setting background audio
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //End recieving events
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Make sure we can recieve remote control events
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void) registerForAudioObjectNotifications {
    
    //    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    //    [notificationCenter addObserver: self
    //                           selector: @selector (handlePlaybackStateChanged:)
    //                               name: nil //MixerHostAudioObjectPlaybackStateDidChangeNotification
    //                             object: nil//audioObject
    //     ];
}
- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                //                [self playOrStop: nil];
                
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

    NSArray *nowPlayingSongsArray = [NowPlayingSong MR_findAllSortedBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    currentPlayList = [[NSMutableArray alloc] initWithArray:nowPlayingSongsArray];
    
    
    NowPlayingSong *nowplayingSong = [currentPlayList objectAtIndex:[nowPlaying.songIndex integerValue]];
    
    // Checks if same song is playing,so the mediaplayer doesn't have to rebuffering
    if (![self checkCurrentSong: nowplayingSong]) {
        
        for (NowPlayingSong *nowPlayingSong in currentPlayList) {
            
            FSPlaylistItem *item = [[FSPlaylistItem alloc] init];
            item.title = nowPlayingSong.title;
            item.url = [NSURL URLWithString:nowPlayingSong.stream_url];
            
            [self.userPlaylistItems addObject:item];
            
        }
        
        
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
    
    [self performSegueWithIdentifier:@"currentIllistNowPlayingSegue" sender:self];
    
}

#pragma mark - Play button

- (IBAction)playButton:(id)sender {
    
}

- (IBAction)nextButton:(id)sender {
  
}
//
- (void) playSong {
    
    
    NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:defaultContext];
    
    NowPlayingSong *nowplayingSong = [currentPlayList objectAtIndex:[nowPlaying.songIndex integerValue]];
    
    currentSong = nowplayingSong;
    
    self.currentPlaylistButton.title = nowPlaying.playlistName;
    
    self.songTitle.text = nowplayingSong.title;
    
    NSString *resourceURL = [NSString stringWithFormat:@"%@.json?client_id=%@", nowplayingSong.stream_url ,clientID];
    NSURL* url = [NSURL URLWithString:resourceURL];
    

    [audioController playFromURL:url];
    
    [self.currentSongArtwork sd_setImageWithURL:[NSURL URLWithString:[self setImageSize:nowplayingSong.artwork] ] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageRefreshCached];
    
    flagSong = NO;
    


}

- (IBAction)backButton:(id)sender {

    
}
//
#pragma mark - Music slider
- (IBAction)musicSlider:(id)sender {

    [self sliderChanged];
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
//        _rampStep = 1;
//        _rampStepCount = 5; // 50ms and 5 steps = 250ms ramp
//        _rampUp = false;
//        _postRampAction = @selector(doSeeking);
//        
//        _volumeRampTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 // 50ms
//                                                            target:self
//                                                          selector:@selector(rampVolume)
//                                                          userInfo:nil
//                                                           repeats:YES];
    } else {
        // Just directly seek, volume is already 0
        [self doSeeking];
    }
}

- (void)doSeeking
{
    FSStreamPosition pos = {0};
    pos.position = _seekToPoint;
    [audioController.activeStream seekToPosition:pos];
}

//
//#pragma mark - Navigation
//
//// In a storyboard-based application, you will often want to do a little preparation before navigation
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    
//    if ([[segue identifier] isEqualToString:@"currentIllistNowPlayingSegue"]) {
//        
////        UINavigationController *navController = [segue destinationViewController];
//        
////        iLLFriendSearchSongsTableViewController *vc = (iLLFriendSearchSongsTableViewController*)navController.topViewController;
//        
////        [vc setPlaylistInfo:];
//        
//    }
//    
//}
//
#pragma Set current song artwork size
- (NSString*) setImageSize:(NSString*)image {
    
    // Resizing artwork to 300 by 300 pixels
    NSString* resizeImage = [[NSString alloc] initWithString:image];
    
    resizeImage = [resizeImage stringByReplacingOccurrencesOfString:@"large" withString:@"t300x300"];
    return resizeImage;
}


@end
