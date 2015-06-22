//
//  MySearchedSongsSearchControllerTableViewController.h
//  iLList
//
//  Created by Jake Choi on 6/4/15.
//  Copyright (c) 2015 iLList. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Playlist.h"

@interface MySearchedSongsSearchControllerTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *iLListTracks;
@property (nonatomic, retain) Playlist *playlistInfo;

@end