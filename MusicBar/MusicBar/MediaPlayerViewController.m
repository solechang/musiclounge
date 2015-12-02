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

#define isiPhone5  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE

static NSString *const clientID = @"fc8c97d1af51d72375bf565acc9cfe60";

@interface MediaPlayerViewController ()
{

    MPNowPlayingInfoCenter *nowPlayingInfo;
    
    FSAudioController *audioController;
    
    FSAudioStream *audioStream;
    NSTimer* timer;
    
    NSMutableArray *currentPlayList;
    
    NSManagedObjectContext *defaultContext;
    
    NowPlayingSong *currentSong;
    
    FSStreamPosition pos;
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

@property (assign,nonatomic) NSInteger songCount;


@end

@implementation MediaPlayerViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Instantiate the audio player
    [self setNSManagedObjectContext];
    [self setUpNavigationBar];
    
    [self setUpNotifications];
    
    [self setUpData];
//    [self gradientSetting];
//    [self.currentSongArtwork setFrame:<#(CGRect)#>]
    [[self.currentSongArtwork layer] setBorderWidth:2.0f];
    [[self.currentSongArtwork layer] setBorderColor:[UIColor whiteColor].CGColor];
    
    
//    [[self.view layer] setBorderWidth:2.0f];
//    [[self.view layer] setBorderColor:[UIColor whiteColor].CGColor];
    
    self.songTitle.numberOfLines = 1;
    self.songTitle.adjustsFontSizeToFitWidth = YES;
//    self.currentPlaylistButton.a = YES;
    
//    [self.playButton buttonWithType:UIButtonTypeSystem];
    [self.playButton setTintColor:[UIColor whiteColor]];
    [self.nextButton setTintColor:[UIColor whiteColor]];
    [self.backButton setTintColor:[UIColor whiteColor]];

    [self setUpAudioPlayer];


}

-(void)gradientSetting {
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    
    UIColor *topColor = [UIColor colorWithRed:(49/255.0) green:(17/255.0) blue:(65/255.0) alpha:0] ;
    UIColor *bottomColor = [UIColor colorWithRed:(75/255.0) green:(31/255.0) blue:(83/255.0) alpha:1] ;
    
    gradient.colors = [NSArray arrayWithObjects:(id)[topColor CGColor], (id)[bottomColor CGColor], nil];
    [self.view.layer insertSublayer:gradient atIndex:0];
    
    
}

- (void) setUpNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityNotifications:) name:@"NextSong" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityNotifications:) name:@"BackSong" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityNotifications:) name:@"PlayAndPause" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityNotifications:) name:@"StopPlayer" object:nil];

}

- (void) activityNotifications:(NSNotification *)notification {
    

        if ([[notification name] isEqualToString:@"NextSong"]) {
            if (self.nextButton.enabled)  {
                [self nextButton:self];
            }
            
            
        } else if ([[notification name] isEqualToString:@"BackSong"]) {
            if (self.backButton.enabled)  {
                
                [self backButton:self];
            }
            
            
        } else if ([[notification name] isEqualToString:@"PlayAndPause"]) {
            [self playButton:self];
            
        } else if ([[notification name] isEqualToString:@"StopPlayer"]) {
            [self stopPlayer];
            
        }

}

-(void) setUpNavigationBar{
    
    NSDictionary *size = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Wisdom Script" size:24.0],NSFontAttributeName, nil];
    self.navigationController.navigationBar.topItem.title = @"Now Spinning";
    self.navigationController.navigationBar.titleTextAttributes = size;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
//    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    
    [self.tabBarController.tabBar setTintColor:[UIColor whiteColor]];
    
}

- (void) setUpData {
     audioController = [[FSAudioController alloc] init];
    
    self.userPlaylistItems = [[NSMutableArray alloc] init];

    currentPlayList = [[NSMutableArray alloc] init];
    
    [self.currentPlaylistButton setEnabled:YES];
    UIImage *buttonImage = [UIImage imageNamed:@"pausebutton.png"];
    [self.playButton setImage:buttonImage forState:UIControlStateNormal];
    
    self.playButton.tag = 1;

    [self.playButton setEnabled:NO];
    self.playButton.alpha = 0.5;
    
//    FSStreamPosition pos = {0};
    
}

- (void) setNSManagedObjectContext {
    
    defaultContext = [NSManagedObjectContext MR_defaultContext];
}

- (void) viewWillDisappear:(BOOL)animated {
    [SVProgressHUD dismiss];
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    _progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                            target:self
                                                          selector:@selector(updatePlaybackProgress)
                                                          userInfo:nil
                                                           repeats:YES];
    
    
    
    [self checkNowPlayingPlaylistId];

  
}

- (void) setUpAudioPlayer {
    __weak typeof(self) weakSelf = self;
    audioController.onStateChange = ^(FSAudioStreamState state) {
        switch (state) {
                
            case kFsAudioStreamRetrievingURL:
                //                NSLog(@"1.1.)");
                
                break;
                
            case kFsAudioStreamStopped:
                //                 NSLog(@"1.2.)");
                
                break;
                
            case kFsAudioStreamBuffering: {
                //                NSLog(@"1.3.)");
                
                break;
            }
                
            case kFsAudioStreamSeeking:
                
                //                NSLog(@"1.4.)");
                
                break;
                
            case kFsAudioStreamPlaying:
                
                //                NSLog(@"1.5.)");
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
                //                NSLog(@"1.6.)");
                //                 [weakSelf.songTitle setText:@"This song cannot be played right now. Please try again or delete the song from the playlist :("];
                
                break;
            case kFsAudioStreamPlaybackCompleted:
                //                NSLog(@"1.7.)");
                //                [weakSelf toggleNextPreviousButtons];
                if (weakSelf.playButton.enabled) {
                    [weakSelf nextButton:nil];
                }
                
                break;
                
            case kFsAudioStreamRetryingStarted:
                //                NSLog(@"1.8.)");
                weakSelf.enableLogging = YES;
                
                
                break;
                
            case kFsAudioStreamRetryingSucceeded:
                //                NSLog(@"1.9.)");
                weakSelf.enableLogging = YES;
                
                break;
                
            case kFsAudioStreamRetryingFailed:
                //                NSLog(@"1.10.)");
                //                if (weakSelf.playButton.enabled) {
                [SVProgressHUD dismiss];
                
                if (weakSelf.songCount == 1) {
                    
                    [weakSelf stoppingPlayerBecauseOfError];
                    
                } else {
                    [weakSelf nextButton:nil];
                }
                
                //                }
                
                break;
                
            default:
                //                NSLog(@"1.11.)");
                break;
                
                
        }
    };
    
    audioController.onFailure = ^(FSAudioStreamError error, NSString *errorDescription) {
        NSString *errorCategory;
        
        switch (error) {
            case kFsAudioStreamErrorOpen:
                errorCategory = @"Cannot open the audio stream: ";
                break;
            case kFsAudioStreamErrorStreamParse:
                errorCategory = @"Cannot read the audio stream: ";
                break;
            case kFsAudioStreamErrorNetwork:
                errorCategory = @"Network failed: cannot play the audio stream: ";
                break;
            case kFsAudioStreamErrorUnsupportedFormat:
                errorCategory = @"Unsupported format: ";
                break;
            case kFsAudioStreamErrorStreamBouncing:
                errorCategory = @"Network failed: cannot get enough data to play: ";
                break;
            default:
                errorCategory = @"Unknown error occurred: ";
                break;
        }
        
        NSString *errorStatus;
        
        if ([errorDescription containsString:@"404"] || [errorDescription containsString:@"401"] || [errorDescription containsString:@"403"]) {
            errorStatus = [[NSString alloc] initWithFormat:@"SoundCloud has disabled '%@' to be streamed \xF0\x9F\x98\x96", weakSelf.songTitle.text];
            [SVProgressHUD showErrorWithStatus:errorStatus];
            //            weakSelf.songTitle.text = errorStatus;
            
        } else {
            
            errorStatus = [[NSString alloc] initWithFormat:@"There is a network error \xF0\x9F\x98\xA8 Please try playing '%@' again", weakSelf.songTitle.text];
            [SVProgressHUD showErrorWithStatus:errorStatus];
            //            weakSelf.songTitle.text = errorStatus;
            
        }
        
    };

}

- (void)viewDidAppear:(BOOL)animated {
  
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
        self.endTime.text = @"Loading";
        self.playButton.enabled = NO;
        self.playButton.alpha = 0.5;
        
    } else {
//        NSLog(@"0.2)");
//        self.musicSlider.enabled = YES;
        self.playButton.enabled = YES;
        self.playButton.alpha = 1.0;
        
        FSStreamPosition cur = audioController.activeStream.currentTimePlayed;
        FSStreamPosition end = audioController.activeStream.duration;
        
        self.musicSlider.value = cur.position;
        
//        self.startTime.text = [NSString stringWithFormat:@"%i:%02i / %i:%02i",
//                                         cur.minute, cur.second,
//                                         end.minute, end.second];
        self.startTime.text = [NSString stringWithFormat:@"%i:%02i",
                               cur.minute, cur.second];
//        self.endTime.text = [NSString stringWithFormat:@"%i:%02i / %i:%02i",
//                               cur.minute, cur.second,
//                               end.minute, end.second];
        
        unsigned endMin = end.minute - cur.minute;
        unsigned endSec = end.second;
        self.endTime.text = [NSString stringWithFormat:@"%i:%02i",
                             endMin, endSec];
        
    }
    
//    self.bufferingIndicator.hidden = NO;
//    self.prebufferStatus.hidden = YES;
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Make sure we can recieve remote control events
- (BOOL)canBecomeFirstResponder {
    return YES;
}




- (void) checkNowPlayingPlaylistId {
    
    NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:defaultContext];

    if ([nowPlaying.playlistId isEqualToString:@""]) {
        
        [self setButtonsEnabled:NO];
//        NSLog(@"No songs to be played");
        
    } else {
        [self setButtonsEnabled:YES];

        [self getSongsFromLocal: nowPlaying];
    }
    
}

- (void) setButtonsEnabled:(BOOL) yesOrNo {
    
    if (yesOrNo) {
        self.startTime.text = @"Loading";

    } else {
        self.startTime.text = @"";
        self.songTitle.text = @"Please choose a song in a lounge";
    }
    [self.playButton setEnabled:yesOrNo];
    [self.nextButton setEnabled:yesOrNo];
    [self.backButton setEnabled:yesOrNo];
}

#pragma mark - setCurrentPlayList
- (void) getSongsFromLocal: (NowPlaying* )nowPlaying {

//    NSArray *nowPlayingSongsArray = [NowPlayingSong MR_findByAttribute:@"playlistId" withValue:nowPlaying.playlistId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    NSArray *nowPlayingSongsArray = [NowPlayingSong MR_findByAttribute:@"playlistId" withValue:nowPlaying.playlistId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    currentPlayList = [[NSMutableArray alloc] initWithArray:nowPlayingSongsArray];
    
    NowPlayingSong *nowplayingSong = [currentPlayList objectAtIndex:[nowPlaying.songIndex integerValue]];
    
    
    // Checks if same song is playing,so the mediaplayer doesn't have to rebuffering
    if (![self checkCurrentSong: nowplayingSong]) {
    
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
    [self deleteSongFriendInLocal];
    
    
}

#pragma mark - Play button

- (IBAction)playButton:(id)sender {
    
    if (self.playButton.enabled) {
        [audioController pause];
        
        // playbutton tag: 0 = paused, 1 = playing
        if (self.playButton.tag == 1) {
            self.playButton.tag = 0;
            UIImage *buttonImage = [UIImage imageNamed:@"playbutton.png"];
            [self.playButton setImage:buttonImage forState:UIControlStateNormal];
            
            [self.musicSlider setEnabled:NO];
            
        } else {
            self.playButton.tag = 1;
            UIImage *buttonImage = [UIImage imageNamed:@"pausebutton.png"];
            [self.playButton setImage:buttonImage forState:UIControlStateNormal];
            
            [self.musicSlider setEnabled:YES];
        }
        

    }

    
}

- (IBAction)nextButton:(id)sender {
    
    [self.playButton setEnabled:NO];
    self.playButton.alpha = 0.5;
    
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
        
        if (!error) {
            [self playSong];
            
        } else {
//            NSLog(@"Error 601.)");
        }
        
    }];
    

 

}
- (void) stoppingPlayerBecauseOfError {
    [audioController stop];
    
}

- (void) stopPlayer {
    
    if (self.playButton.tag == 1) {
        
        self.playButton.tag = 0;
        UIImage *buttonImage = [UIImage imageNamed:@"playbutton.png"];
        [self.playButton setImage:buttonImage forState:UIControlStateNormal];
        
        if ([NSThread isMainThread]) {
            // We are the main thread, just directly call:
            [audioController pause];
        } else {
            // We are not on the main thread, use GCD for the main thread:
            dispatch_async(dispatch_get_main_queue(), ^{
                [audioController pause];
            });
        }
        
    }
    
    

}

- (void) playSong {
    [SVProgressHUD dismiss];
    
    NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:defaultContext];
    
    NowPlayingSong *nowplayingSong = [currentPlayList objectAtIndex:[nowPlaying.songIndex integerValue]];
    
    currentSong = nowplayingSong;
    
    if (nowPlaying.playlistName.length > 8) {
        
        NSString *subStr = [nowPlaying.playlistName substringWithRange:NSMakeRange(0, 9)];
        NSString *displayCurrentPlaylistTitle = [NSString stringWithFormat:@"%@..", subStr];
        self.currentPlaylistButton.title = displayCurrentPlaylistTitle;
        
    } else {
        
        self.currentPlaylistButton.title = nowPlaying.playlistName;
    }
    

    
    self.songTitle.text = nowplayingSong.title;
    
    [self.currentSongArtwork sd_setImageWithURL:[NSURL URLWithString:[self setImageSize:nowplayingSong.artwork] ] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageRefreshCached];
    
//    [self.currentSongArtwork];
    
//    UIImage *myBadgedImage = [self drawImage:profileImage withBadge:badgeImage];
    
    NSString *resourceURL = [NSString stringWithFormat:@"%@.json?client_id=%@", nowplayingSong.stream_url ,clientID];
    NSURL* url = [NSURL URLWithString:resourceURL];
    audioController.url = url;
    
    self.songCount = currentPlayList.count;
    
    [audioController play];
    [self.playButton setEnabled:YES];
    
    self.playButton.alpha = 1.0;
    
    self.playButton.tag = 1;
    UIImage *buttonImage = [UIImage imageNamed:@"pausebutton.png"];
    [self.playButton setImage:buttonImage forState:UIControlStateNormal];
    
    [self setLockScreenSongInfo :nowplayingSong];


}


- (void) setLockScreenSongInfo : (NowPlayingSong*)nowPlayingSong{
    
//    NSString *playDurationTime = [NSString stringWithFormat:@"%@",  end.minute * 60 + end.second]

    NSString *minutes = [nowPlayingSong.time componentsSeparatedByString:@":"][0];
    int minutesInt = [minutes intValue];
    
    NSString *seconds = [nowPlayingSong.time componentsSeparatedByString:@":"][1];
    int secondsInt = [seconds intValue];
    
    int totalSeconds = (60 * minutesInt) + secondsInt;
    
    NSString *totalSecondsString = [NSString stringWithFormat:@"%d", totalSeconds];
    
    NSDictionary * info;

    
    info = @{ MPMediaItemPropertyArtist: @"MusicLounge",
              MPMediaItemPropertyAlbumTitle: self.currentPlaylistButton.title,
              MPMediaItemPropertyTitle: self.songTitle.text,
              MPMediaItemPropertyPlaybackDuration:totalSecondsString,
              MPNowPlayingInfoPropertyPlaybackRate: [NSNumber numberWithInt:1]
              };
    
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;

    
//    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc]initWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[self setImageSize:nowPlayingSong.artwork]]]]];
//    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc]initWithImage:self.currentSongArtwork.image] ;
    
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_async(queue, ^{
//        
//        NSMutableDictionary *songInfo = [NSMutableDictionary dictionary];
//        UIImage *artworkImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[self setImageSize:nowPlayingSong.artwork]]]];
//        MPMediaItemArtwork *albumArt;
//        NSDictionary * info;
//        
//        
//        
//        
//        if(artworkImage)
//        {
//            albumArt = [[MPMediaItemArtwork alloc] initWithImage: artworkImage];
//            [songInfo setValue:albumArt forKey:MPMediaItemPropertyArtwork];
//            info = @{ MPMediaItemPropertyArtist: @"MusicLounge",
//                                    MPMediaItemPropertyAlbumTitle: self.currentPlaylistButton.title,
//                                    MPMediaItemPropertyTitle: self.songTitle.text,
//                                    MPMediaItemPropertyPlaybackDuration:totalSecondsString,
//                                    MPNowPlayingInfoPropertyPlaybackRate: [NSNumber numberWithInt:1],
//                                    MPMediaItemPropertyArtwork: albumArt
//                                    };
//        } else {
//
//            info = @{ MPMediaItemPropertyArtist: @"MusicLounge",
//                      MPMediaItemPropertyAlbumTitle: self.currentPlaylistButton.title,
//                      MPMediaItemPropertyTitle: self.songTitle.text,
//                      MPMediaItemPropertyPlaybackDuration:totalSecondsString,
//                      MPNowPlayingInfoPropertyPlaybackRate: [NSNumber numberWithInt:1]
//                      };
//        }
////        MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter defaultCenter];
////        infoCenter.nowPlayingInfo = songInfo;
//        
//
//
//
//        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
//
//    });
    

}

- (IBAction)backButton:(id)sender {
    
    [self.playButton setEnabled:NO];
    self.playButton.alpha = 0.5;
    
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
        
        if (!error) {
            [self playSong];
            
        } else {
//            NSLog(@"Error 702.)");
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
    }

}

- (void)doSeeking
{
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

    if ([[segue identifier] isEqualToString:@"currentPlaylistSegue"]) {
        UINavigationController *navController = [segue destinationViewController];
        FriendSearchSongsTableViewController *vc = (FriendSearchSongsTableViewController*)navController.topViewController;
        
        NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:defaultContext];
        
        PlaylistFriend *playlist = [PlaylistFriend MR_createEntity];
        playlist.objectId = nowPlaying.playlistId;
        playlist.name = nowPlaying.playlistName;
        playlist.userId = [PFUser currentUser].objectId;
        playlist.fromNowSpinning = @(YES);
        vc.playlistInfo = playlist;

    }

}
- (void) deleteSongFriendInLocal {
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        NSArray *songsInLocal = [SongFriend MR_findAllInContext:localContext];
        
        for (SongFriend *songToDelete in songsInLocal) {
            
            [songToDelete MR_deleteEntityInContext:localContext];
            
        }
        
    } completion:^(BOOL success, NSError *error) {
        
        
        if (!error) {
            [self performSegueWithIdentifier:@"currentPlaylistSegue" sender:self];
            //            NSArray *songsInLocal = [SongFriend MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
            
            //            iLListTracks = [[NSMutableArray alloc] initWithArray:songsInLocal];
            //
            //            [self.tableView reloadData];
            
            
        } else {
            
        }
        
        
    }];
    
    
}



@end
