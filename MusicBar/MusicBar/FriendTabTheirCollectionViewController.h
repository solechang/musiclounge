//
//  FriendTabTheirCollectionViewController.h
//  MusicBar
//
//  Created by Jake Choi on 2/24/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <AVFoundation/AVFoundation.h>

// Core data
#import "Friend.h"

@interface FriendTabTheirCollectionViewController : UICollectionViewController


@property (strong, nonatomic) IBOutlet UICollectionView *friendTabTheirSegmentedControlView;

@property (nonatomic) Friend* friendInfo;
@end
