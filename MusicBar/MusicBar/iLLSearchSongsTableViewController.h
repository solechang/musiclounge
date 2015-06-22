//
//  iLLSearchSongsTableViewController.h
//  iLList
//
//  Created by Jake Choi on 12/3/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScrollView+EmptyDataSet.h" 

// CoreData
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"
#import "Playlist.h"
#import "Song.h"
#import "SongManager.h"
#import "NowPlaying.h"
#import "NowPlayingSong.h"

@interface iLLSearchSongsTableViewController : UITableViewController <UISearchBarDelegate,UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, retain) Playlist* playlistInfo;



@end
