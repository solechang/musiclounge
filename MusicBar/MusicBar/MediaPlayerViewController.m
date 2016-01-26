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
    
    FSAudioStream *audioStreamForJoiner;
    NSTimer* timer;
    
    NSMutableArray *currentPlayList;
    
    NSManagedObjectContext *defaultContext;
    
    NowPlayingSong *currentSong;
    
    FSStreamPosition pos;
    
    SRWebSocket *_webSocket;
    
    
}


@property (weak, nonatomic) IBOutlet UIBarButtonItem *DJButton;

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



// DJ properties for joiner
@property (nonatomic, assign) BOOL joiningDJ;
@property (nonatomic) float seekingTimeForJoiner;
@property (nonatomic) int64_t startTimeForJoiner;
@property (nonatomic) int64_t endTimeForJoiner;
@property (nonatomic) float duplicatePreBufferSize;

@property (nonatomic,assign) BOOL joinerReadyToPlaySong;

@end

@implementation MediaPlayerViewController
#warning What to work on when I open this
//    1.) Push Notification
//    2.) Work on Friends tab because it says 'loading'

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Instantiate the audio player
    [self setNSManagedObjectContext];
    [self setUpNavigationBar];
    
    [self setUpNotifications];
    
    [self setUpData];

    [[self.currentSongArtwork layer] setBorderWidth:2.0f];
    [[self.currentSongArtwork layer] setBorderColor:[UIColor whiteColor].CGColor];
    

    [self.DJButton setEnabled:NO];
    [self.DJButton setTintColor: [UIColor clearColor]];
    
    self.songTitle.numberOfLines = 1;
    self.songTitle.adjustsFontSizeToFitWidth = YES;

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
//                                NSLog(@"1.3.)");

                
                break;
            }
                
            case kFsAudioStreamSeeking:
                
//                                NSLog(@"1.4.)");
                
                break;
                
            case kFsAudioStreamPlaying:
                
//                          NSLog(@"1.5.)");
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
                
         
                
                break;
                
            default:
                //                NSLog(@"1.11.)");
                
                break;
                
                
        }
    };
    
    
#pragma mark - Media player failure
    
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

- (void) setUpAudioStreamForJoiner {
    __weak typeof(self) weakSelf = self;
    
    audioStreamForJoiner.onStateChange = ^(FSAudioStreamState state) {
        switch (state) {
                
            case kFsAudioStreamRetrievingURL:
                //                NSLog(@"1.1.)");
                
                break;
                
            case kFsAudioStreamStopped:
                //                 NSLog(@"1.2.)");
                
                break;
                
            case kFsAudioStreamBuffering: {
                NSLog(@"1.3.)");
//                [weakSelf playSongForJoiner];
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
                
                
                
                break;
                
            default:
                //                NSLog(@"1.11.)");
                
                break;
                
                
        }
    };
    
    
#pragma mark - Media player failure
    
    audioStreamForJoiner.onFailure = ^(FSAudioStreamError error, NSString *errorDescription) {
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
#warning Work on DJing here for Joiner
//    [self checkPreBufferForJoiner];

    if (audioController.activeStream.continuous) {
        self.musicSlider.enabled = NO;
        self.musicSlider.value = 0;
        self.startTime.text = @"Loading";
        self.endTime.text = @"Loading";
        self.playButton.enabled = NO;
        self.playButton.alpha = 0.5;
        
    } else {
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

#pragma mark - Check prebuffer for joiner

- (void) checkPreBufferForJoiner {
    
    NSLog(@"2.) %zu",audioStreamForJoiner.prebufferedByteCount);
    
    NSLog(@"2.) %@",[NSString stringWithFormat:@"%i:%02i",
           audioStreamForJoiner.currentTimePlayed.minute, audioStreamForJoiner.currentTimePlayed.second]);
    
#warning - Check when network doesn't work
    // Check when network doesn't work
    
    if ( self.duplicatePreBufferSize == (float)audioStreamForJoiner.prebufferedByteCount && (float)audioStreamForJoiner.prebufferedByteCount != 0 && !self.joinerReadyToPlaySong) {
        self.joinerReadyToPlaySong = YES;
        
        [self sendJoinerReady];
        NSLog(@"3.) YO : %d", self.joinerReadyToPlaySong);
        
    } else {

         self.duplicatePreBufferSize = audioStreamForJoiner.prebufferedByteCount;
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Make sure we can recieve remote control events
- (BOOL)canBecomeFirstResponder {
    return YES;
}


#pragma mark - Logic for playing songs

- (void) checkNowPlayingPlaylistId {
    
    NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:defaultContext];

    if ([nowPlaying.playlistId isEqualToString:@""]) {
        
        [self setButtonsEnabled:NO];
//        NSLog(@"No songs to be played");
        
    } else if ([nowPlaying.currentlyPlayingSongId isEqualToString:@"joinLounge^&#@*!&@#"]) {
        
        // Gotta check if client who joined the host is currently hosting
        // IF NOT* then prompt user that host is not currently hosting and choose a song from a lounge to play music
       
        [self connectWebSocket];
//        [self sendJoinLoungeData :nowPlaying];
        
        
        
        
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
    [self.currentPlaylistButton setEnabled:yesOrNo];
    [self.DJButton setEnabled:yesOrNo];
}

#pragma mark - setCurrentPlayList
- (void) getSongsFromLocal: (NowPlaying* )nowPlaying {

//    NSArray *nowPlayingSongsArray = [NowPlayingSong MR_findByAttribute:@"playlistId" withValue:nowPlaying.playlistId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    NSArray *nowPlayingSongsArray = [NowPlayingSong MR_findByAttribute:@"playlistId" withValue:nowPlaying.playlistId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    currentPlayList = [[NSMutableArray alloc] initWithArray:nowPlayingSongsArray];
    
    NowPlayingSong *nowplayingSong = [currentPlayList objectAtIndex:[nowPlaying.songIndex integerValue]];
    
    
    // Checks if same song is playing,so the mediaplayer doesn't have to rebuffer
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
    
    
    
    // audioController play song
    
    if (self.joiningDJ) {
        audioStreamForJoiner.url = url;
        [self playSongForJoiner];
        
    } else {
        
        
        [audioController play];
    }

    
    [self.playButton setEnabled:YES];
    
    self.playButton.alpha = 1.0;
    
    self.playButton.tag = 1;
    UIImage *buttonImage = [UIImage imageNamed:@"pausebutton.png"];
    [self.playButton setImage:buttonImage forState:UIControlStateNormal];
    
    [self setLockScreenSongInfo :nowplayingSong];


}

#pragma marks - Joiner play song same time as DJ
- (void) playSongForJoiner {
    FSSeekByteOffset playPosition;
    playPosition.position = self.seekingTimeForJoiner;
    playPosition.start = self.startTimeForJoiner;
    playPosition.end = self.endTimeForJoiner;
    
    
//    FSStreamPosition position;
//    position.position = self.seekingTimeForJoiner;
    
//    [audioStreamForJoiner playFromOffset:playPosition];
    [audioStreamForJoiner preload];
    
//    NSLog(@"1.) %f : %d ", self.seekingTimeForJoiner , audioStreamForJoiner.configuration.maxPrebufferedByteCount);


    
//    [audioStreamForJoiner play];
    

    

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

    [self sliderChanged:self.musicSlider.value];
}

- (void)finalizeSeeking
{
    _volumeBeforeRamping = 0;
}

-(void) sliderChanged:(float)seekValue
{

    _seekToPoint = seekValue;
   
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

- (void)doSeeking:(double) seekToPoint
{
    pos.position = seekToPoint;
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

#pragma marks - Delete friend songs in local
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
#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
    
    
    NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:defaultContext];
    if (  [nowPlaying.currentlyPlayingSongId isEqualToString:@"joinLounge^&#@*!&@#"] ){
        
        
        [self sendJoinLoungeData:nowPlaying];
    
    } else {
        
        
        self.DJButton.enabled = YES;
        [self sendHostDJData];
    }
    
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    
    NSError *jsonError;
    NSData *objectData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    NSLog(@"Received \"%@\"", jsonDictionary);
    
    if ([jsonDictionary[@"action"] isEqualToString:@"requestHostInfo"]) {
        
        [self sendHostInfo:jsonDictionary[@"data"]];
        
    } else if ( [jsonDictionary[@"action"] isEqualToString:@"error"]) {
     
        [self hostIsCurrentlyNotHosting:jsonDictionary[@"data"][@"hostName"]];
        
    } else if ( [jsonDictionary[@"action"] isEqualToString:@"kickJoiner"]) {
    
        self.DJButton.title = @"DJ";
        
        [self leaveLounge];
        
        [SVProgressHUD showInfoWithStatus:@"Left lounge"];
        self.DJButton.enabled = YES;
        
    } else if( [jsonDictionary[@"action"] isEqualToString:@"processHostInfo"] ) {
        
        
        [self playReceivedSongData:jsonDictionary[@"data"]];
        
    } else if( [jsonDictionary[@"action"] isEqualToString:@"requestSongTime"] ) {
        
        
        [self sendSongTimeToJoiner:jsonDictionary[@"data"]];
        
    } else if( [jsonDictionary[@"action"] isEqualToString:@"joinerStartSong"] ) {
        
        
        [self joinerPlaySong:jsonDictionary[@"data"]];
        
    }

   
 
    
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    _webSocket = nil;
    self.DJButton.enabled = YES;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;
{
    NSLog(@"Websocket received pong");
}


- (id)initWithMessage:(NSString *)message fromMe:(BOOL)fromMe;
{
    self = [super init];
    if (self) {
       
    }
    
    return self;
}

- (void)connectWebSocket;
{

    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"ws://45.55.22.191:1337"]]];
    _webSocket.delegate = self;
    
    NSLog(@"Opening connection");
   
    [_webSocket open];
    
}


#pragma mark - Client receiving song data to play

- (void) playReceivedSongData:(NSDictionary*) songData{
    
     self.DJButton.title = @"Leave";
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        NowPlaying *nowPlayingDelete = [NowPlaying MR_findFirstInContext:localContext];
        [nowPlayingDelete MR_deleteEntityInContext:localContext];
        
        NowPlaying *nowPlaying = [NowPlaying MR_createEntityInContext:localContext];
        nowPlaying.playlistId = songData[@"currentLoungeId"];
        nowPlaying.songIndex = [NSNumber numberWithInteger:0];
        nowPlaying.playlistName = songData[@"currentLoungeName"];
        nowPlaying.updatedAt = [NSDate date];
        
        nowPlaying.currentlyPlayingSongId = songData[@""];
        
        NSArray *nowPlayingSongArrayToDelete = [NowPlayingSong MR_findAllInContext:localContext];
        
        for (NowPlayingSong *nowPlayingSongDelete in nowPlayingSongArrayToDelete) {
            
            [nowPlayingSongDelete MR_deleteEntityInContext:localContext];
            
        }
        
        NowPlayingSong *nowPlayingSong = [NowPlayingSong MR_createEntityInContext:localContext];
        
        nowPlayingSong.artwork = songData[@"songImage"];
        nowPlayingSong.hostId = songData[@"userId"];
        nowPlayingSong.hostName = songData[@"hostName"];
        nowPlayingSong.objectId = songData[@"songId"];
        nowPlayingSong.playlistId = songData[@"currentLoungeId"];
        nowPlayingSong.stream_url = songData[@"streamURL"];
        

//        nowPlayingSong.time = songsInLocal.time;
        self.seekingTimeForJoiner = [songData[@"songTime"] floatValue];
        self.startTimeForJoiner = [songData[@"startTime"] integerValue];
        self.endTimeForJoiner = [songData[@"endTime"] integerValue];
        
        nowPlayingSong.title = songData[@"songName"];
//        nowPlayingSong.uploadingUser = songsInLocal.uploadingUser;
//        nowPlayingSong.createdAt = songsInLocal.createdAt;
        
        nowPlayingSong.nowPlaying = nowPlaying;
        
    } completion:^(BOOL success, NSError *error) {
        
        if (!error) {
            NSArray *nowPlayingSongsArray = [NowPlayingSong MR_findAllInContext:defaultContext];
            
            currentPlayList = [[NSMutableArray alloc] initWithArray:nowPlayingSongsArray];
            
            self.joiningDJ = YES;
            self.joinerReadyToPlaySong = NO;
            
            audioStreamForJoiner = [[FSAudioStream alloc] init];
            [self setUpAudioStreamForJoiner];
            self.duplicatePreBufferSize = 0;
        
            [self playSong];
            
            
        } else {
            //            NSLog(@"Error 653 %@", error);
        }
     }];
    
    
    
}


#pragma mark - DJ Button
- (IBAction)DJButtonPressed:(id)sender {
    
//    SR_CONNECTING   = 0,
//    SR_OPEN         = 1,
//    SR_CLOSING      = 2,
//    SR_CLOSED       = 3,

//    NSLog(@"1.) %ld", (long)_webSocket.readyState);
    
    
    // Leave lounge
    if ([self.DJButton.title isEqualToString:@"Leave"]) {
        self.DJButton.enabled = NO;
        self.DJButton.title = @"DJ";
        
        [self leaveLounge];
        
        return;
    }
    
    if (_webSocket.readyState == (long)0) {
        // First time when the app is opened, _webSocket is not instantiated
        self.DJButton.enabled = NO;
        self.DJButton.title = @"DJing";
        [self connectWebSocket];

        
    } else  if ( _webSocket.readyState == (long)1) {
        // Websocket is opened
        self.DJButton.enabled = NO;
        self.DJButton.title = @"DJ";
        
        [self sendCloseHostData];
        
        
        
    }
}

- (void) sendCloseHostData {
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:[PFUser currentUser].objectId forKey:@"userId"];
    
    NSDictionary *tmp = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"unhostLounge", @"action",
                         data, @"data",
                         nil];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:tmp options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    [_webSocket send:jsonString];
    
    [_webSocket close];
    
}



- (void) sendHostDJData {
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:[PFUser currentUser][@"name"] forKey:@"hostName"];
    [data setObject:[PFUser currentUser].objectId forKey:@"userId"];


    
    NSDictionary *tmp = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"hostLounge", @"action",
                         data, @"data",
                         nil];

    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:tmp options:0 error:&error];
  
    NSString *jsonString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    [_webSocket send:jsonString];
    
    
}

- (void) sendJoinLoungeData:(NowPlaying*) nowPlaying {
//    NSLog(@"1.)");
    
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:nowPlaying.playlistName forKey:@"hostName"];
    [data setObject:[PFUser currentUser].objectId forKey:@"userId"];
    [data setObject:nowPlaying.playlistId forKey:@"hostId"];
    
    NSDictionary *tmp = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"joinLounge", @"action",
                         data, @"data",
                         nil];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:tmp options:0 error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    [_webSocket send:jsonString];
    
    
}

- (void) sendHostInfo:(NSDictionary*) joinerId {
   
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    NSString *stringDate = [dateFormatter stringFromDate:[NSDate date]];
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:[PFUser currentUser][@"name"] forKey:@"hostName"];
    [data setObject:[PFUser currentUser].objectId forKey:@"userId"];
    [data setObject:currentSong.stream_url forKey:@"streamURL"];
    [data setObject:currentSong.title forKey:@"songName"];
    [data setObject:[NSNumber numberWithFloat: audioController.activeStream.currentSeekByteOffset.position] forKey:@"songTime"];
    [data setObject:[NSNumber numberWithInteger:audioController.activeStream.currentSeekByteOffset.start] forKey:@"startTime"];
    [data setObject:[NSNumber numberWithInteger:audioController.activeStream.currentSeekByteOffset.end] forKey:@"endTime"];
    
    [data setObject:stringDate forKey:@"hostTime"];
    [data setObject:currentSong.playlistId forKey:@"currentLoungeId"];
    [data setObject:currentSong.nowPlaying.playlistName forKey:@"currentLoungeName"];
    [data setObject:currentSong.artwork forKey:@"songImage"];
    [data setObject:joinerId[@"joinerId"] forKey:@"joinerId"];
    [data setObject:currentSong.objectId forKey:@"songId"];
    
    
    NSDictionary *tmp = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"sendHostInfo", @"action",
                         data, @"data",
                         nil];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:tmp options:0 error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    [_webSocket send:jsonString];

}

- (void) hostIsCurrentlyNotHosting:(NSString*)hostName {
    
    NSString *hostNotDJString = [NSString stringWithFormat:@"%@ is not currently DJing", hostName];
    [SVProgressHUD showErrorWithStatus:hostNotDJString];
    
}

- (void) leaveLounge {
    
    self.joiningDJ = NO;
   
    NowPlayingSong *nowPlayingSong = [NowPlayingSong MR_findFirstInContext:defaultContext];
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:nowPlayingSong.hostId forKey:@"hostId"];
    [data setObject:[PFUser currentUser].objectId forKey:@"userId"];
    

    NSDictionary *tmp = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"leaveLounge", @"action",
                         data, @"data",
                         nil];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:tmp options:0 error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    [_webSocket send:jsonString];
    
    
}

- (void) sendJoinerReady {
    

    NowPlayingSong *nowPlayingSong = [NowPlayingSong MR_findFirstInContext:defaultContext];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:nowPlayingSong.hostId forKey:@"hostId"];
    [data setObject:[PFUser currentUser].objectId forKey:@"joinerId"];
    NSLog(@"87.) %@", nowPlayingSong.hostId);
    
    NSDictionary *tmp = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"joinerReady", @"action",
                         data, @"data",
                         nil];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:tmp options:0 error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    [_webSocket send:jsonString];
    
    
}
- (void) sendSongTimeToJoiner:(NSDictionary*) joinerData {
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:[NSNumber numberWithFloat: audioController.activeStream.currentSeekByteOffset.position] forKey:@"songTime"];
  
    // joiner Id
    [data setObject:joinerData[@"joinerId"] forKey:@"joinerId"];
    [data setObject:[PFUser currentUser].objectId forKey:@"hostId"];
    
    NSDictionary *tmp = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"sendHostSongTime", @"action",
                         data, @"data",
                         nil];
    
    NSError *error;
    NSData *postdata = [NSJSONSerialization dataWithJSONObject:tmp options:0 error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
    
    [_webSocket send:jsonString];
    
}

- (void)joinerPlaySong:(NSDictionary*) songTime {
     self.seekingTimeForJoiner = [songTime[@"songTime"] floatValue];
    pos.position = self.seekingTimeForJoiner ;
//    [self sliderChanged:pos.position];
    [audioStreamForJoiner seekToPosition:pos];
    [audioStreamForJoiner play];


    
}


@end
