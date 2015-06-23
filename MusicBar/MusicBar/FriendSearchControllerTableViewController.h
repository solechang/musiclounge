//
//  FriendSearchControllerTableViewController.h
//  iLList
//
//  Created by Jake Choi on 6/10/15.
//  Copyright (c) 2015 iLList. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PlaylistFriend.h"

@interface FriendSearchControllerTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *iLListTracks;
@property (nonatomic, retain) PlaylistFriend *playlistInfo;

@end
