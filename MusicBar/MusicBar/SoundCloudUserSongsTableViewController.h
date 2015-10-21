//
//  SoundCloudUserSongsTableViewController.h
//  MusicLounge
//
//  Created by Jake Choi on 10/7/15.
//  Copyright © 2015 Sole Chang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Playlist.h"
#import "PlaylistFriend.h"
#import "CustomSong.h"

@interface SoundCloudUserSongsTableViewController : UITableViewController
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *iLListTracks;
@property (nonatomic, retain) Playlist *playlistInfo;
@property (nonatomic, retain) PlaylistFriend *playlistFriendInfo;

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSString *soundCloudUserID;

@property (nonatomic,strong) CustomSong *scUserInfo;

@property (nonatomic, assign) NSInteger tracksOrLikes; //0 = user tracks. 1 = user liked songs

@end
