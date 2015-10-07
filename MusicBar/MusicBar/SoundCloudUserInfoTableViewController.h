//
//  SoundCloudUserInfoTableViewController.h
//  MusicLounge
//
//  Created by Jake Choi on 10/6/15.
//  Copyright © 2015 Sole Chang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Playlist.h"
#import "CustomSong.h"

@interface SoundCloudUserInfoTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *iLListTracks;
@property (nonatomic, retain) Playlist *playlistInfo;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSString *soundCloudUserID;

@property (nonatomic,strong) CustomSong *scUserInfo;
//@property (nonatomic)
@end
