//
//  FriendSearchSongsTableViewController.h
//  MusicBar
//
//  Created by Jake Choi on 2/25/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "UIScrollView+EmptyDataSet.h"

// CoreData
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"

#import "PlaylistFriend.h"
#import "SongFriend.h"

#import "NowPlaying.h"
#import "NowPlayingSong.h"
#import "iLLSongFriendManager.h"

@interface FriendSearchSongsTableViewController : UITableViewController  <UISearchBarDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, retain) PlaylistFriend* playlistInfo;


@end
