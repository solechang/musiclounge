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

#import "TheAmazingAudioEngine.h"

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

static NSString *const clientID = @"fc8c97d1af51d72375bf565acc9cfe60";

@interface MediaPlayerViewController ()
{
    NSTimer* timer;

//    STKAudioPlayer *nowPlayingPlayer;
    
    NSMutableArray *currentPlayList;
    
    NSManagedObjectContext *defaultContext;
    
    BOOL flagSong; // flags currently playing song
    
    NowPlayingSong *currentSong;
}

@property (nonatomic, strong) AEAudioController *audioController;

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
    self.audioController = [[AEAudioController alloc]
                            initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription]
                            inputEnabled:YES];
    
    
    [self setNSManagedObjectContext];

    currentPlayList = [[NSMutableArray alloc] init];
    
    [self.currentPlaylistButton setEnabled:NO];
    
}

- (void) setNSManagedObjectContext {
    
    defaultContext = [NSManagedObjectContext MR_defaultContext];
}

- (void)viewDidAppear:(BOOL)animated {
    
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
    NSLog(@"nowPlayuing: %@", nowPlaying.playlistId);
    if ([nowPlaying.playlistId isEqualToString:@""]) {
        
        NSLog(@"No songs to be played");
        
    } else {

        [self getSongsFromLocal: nowPlaying];
    }
    
}

#pragma mark - setCurrentPlayList
- (void) getSongsFromLocal: (NowPlaying* )nowPlaying {
    NSLog(@"1.)");
    NSArray *nowPlayingSongsArray = [NowPlayingSong MR_findAllSortedBy:@"createdAt" ascending:NO inContext:defaultContext];
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
    
//    [self setupTimer];
//    [self updateControls];
    
//    [self.currentPlaylistButton setEnabled:YES];

//    [self playSong];


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
//    [self playButtonPressed];
}
//-(void) playButtonPressed
//{
//    if (!nowPlayingPlayer)
//    {
//        return;
//    }
//    
//    if (nowPlayingPlayer.state == STKAudioPlayerStatePaused)
//    {
//        [nowPlayingPlayer resume];
//    }
//    else
//    {
//        [nowPlayingPlayer pause];
//    }
//}
//
- (IBAction)nextButton:(id)sender {
  
}
//
//- (void) playSong {
//
//    
//    NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:defaultContext];
//    
//    NowPlayingSong *nowplayingSong = [currentPlayList objectAtIndex:[nowPlaying.songIndex integerValue]];
//    
//    currentSong = nowplayingSong;
//    
//    self.currentPlaylistButton.title = nowPlaying.playlistName;
//    
//    self.songTitle.text = nowplayingSong.title;
//    
//    [self.currentSongArtwork sd_setImageWithURL:[NSURL URLWithString:[self setImageSize:nowplayingSong.artwork] ] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageRefreshCached];
//    
//    flagSong = NO;
//    
//    NSString *resourceURL = [NSString stringWithFormat:@"%@.json?client_id=%@", nowplayingSong.stream_url ,clientID];
//    
////    NSLog(@"1.) %@", resourceURL);
//    NSURL* url = [NSURL URLWithString:resourceURL];
//    STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];
//    [nowPlayingPlayer setDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0]];
//
//}
//
//- (void) playNextSong {
//    
//    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//        
//        NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:localContext];
//        
//        int nowPlayingIndex = [nowPlaying.songIndex intValue];
////         if index is end of currentPlayList, set index to 0, if not increment index
//        if (nowPlayingIndex == currentPlayList.count - 1 ) {
//            nowPlayingIndex = 0;
//
//        } else {
//            nowPlayingIndex++;
//
//        }
//
//        nowPlaying.songIndex = [NSNumber numberWithInt:nowPlayingIndex];
//        
//        
//    } completion:^(BOOL success, NSError *error) {
//        
//        if (success) {
//            [self playSong];
//            
//        } else {
//            NSLog(@"Error 336.)");
//        }
//        
//    }];
//
//}
//
- (IBAction)backButton:(id)sender {

    
}
//
//- (void ) playPreviousSong {
//    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//        
//        NowPlaying *nowPlaying = [NowPlaying MR_findFirstInContext:localContext];
//        
//        NSUInteger nowPlayingIndex = [nowPlaying.songIndex integerValue];
//        
//        // if index is end of currentPlayList, set index to 0, if not increment index
//        if (nowPlayingIndex ==  0) {
//            NSUInteger currentPlayListCount = currentPlayList.count;
//            nowPlayingIndex = currentPlayListCount--;
//    
//        } else {
//            nowPlayingIndex--;
//            
//        }
//        
//        nowPlaying.songIndex = [NSNumber numberWithInteger:nowPlayingIndex];
//        
//    } completion:^(BOOL success, NSError *error) {
//        
//        if (success) {
//            [self playSong];
//            
//        } else {
//            NSLog(@"Error 382.)");
//        }
//        
//    }];
//}
//
//#pragma mark - Music slider
//- (IBAction)musicSlider:(id)sender {
//
//    [self sliderChanged];
//}
//
//-(void) sliderChanged
//{
//    if (!nowPlayingPlayer)
//    {
//        return;
//    }
//
//    [nowPlayingPlayer seekToTime:self.musicSlider.value];
//}
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
//#pragma Set current song artwork size
//- (NSString*) setImageSize:(NSString*)image {
//    
//    // Resizing artwork to 300 by 300 pixels
//    NSString* resizeImage = [[NSString alloc] initWithString:image];
//    
//    resizeImage = [resizeImage stringByReplacingOccurrencesOfString:@"large" withString:@"t300x300"];
//    return resizeImage;
//}


@end
