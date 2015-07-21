//
//  iLLMediaPlayerViewController.h
//  iLList
//
//  Created by Jake Choi on 12/26/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <STKAudioPlayer.h>

@interface MediaPlayerViewController : UIViewController //<STKAudioPlayerDelegate>

@property (nonatomic,strong) NSMutableArray *userPlaylistItems;

@property (nonatomic,strong) NSMutableArray *playlistItems;

@end
