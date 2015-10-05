//
//  iLLSearchSongsTableViewController.m
//  iLList
//
//  Created by Jake Choi on 12/3/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import "SearchSongsTableViewController.h"
#import "SCUI.h"
#import "CustomSearchedSongTableViewCell.h"
#import "CustomSong.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <Parse/Parse.h>
#import "MediaPlayerViewController.h"
#import "MySearchedSongsSearchControllerTableViewController.h"

#import <SVProgressHUD/SVProgressHUD.h>

@interface SearchSongsTableViewController () {
    
    NSMutableArray *iLListTracks;
    NSManagedObjectContext *defaultContext;
    UINavigationController *navController;
    MySearchedSongsSearchControllerTableViewController *vc;
    
}

@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic, strong) NSArray *tracks;
@property (nonatomic, strong) NSDictionary *userTracks;

@property (nonatomic, strong) NSMutableArray *searchResult;

@end

@implementation SearchSongsTableViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self setUpNotifications];

    [self setNSManagedObjectContext];
    [self setupTableView];
    
    [self setUpSearchController];
    [self setupTitle];

}


- (void) setUpData {
    
    navController = (UINavigationController *)self.searchController.searchResultsController;
    
    vc = (MySearchedSongsSearchControllerTableViewController *)navController.topViewController;
    
}

- (void) setNSManagedObjectContext {

    defaultContext = [NSManagedObjectContext MR_defaultContext];
}

- (void) setUpSearchController {
    UINavigationController *searchResultsController = [[self storyboard] instantiateViewControllerWithIdentifier:@"TableSearchResultsNavController"];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    
//    self.searchController.searchResultsUpdater = self;

    [self.searchController.searchBar setPlaceholder:@"Find Your Groove :)"];
    
    self.searchController.searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"All", @"SoundCloud User", nil];
    
    [self.searchController.searchBar setScopeBarButtonTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [self.searchController.searchBar setScopeBarButtonTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil] forState:UIControlStateSelected];
    
    [self adjustSearchBarToShowScopeBar];
    
    self.searchController.searchBar.delegate = self;
 
    self.searchController.hidesNavigationBarDuringPresentation = NO;
//    self.definesPresentationContext = NO;
    
}

- (void)adjustSearchBarToShowScopeBar {
    
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
}

- (void) setupTableView {
    
    
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60)
                                                         forBarMetrics:UIBarMetricsDefault];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    [self.tableView setRowHeight:90];
    
    
}

- (void) setupTitle {
    
    UILabel *label = [[UILabel alloc] init];
    [label setFrame:CGRectMake(0,5,100,20)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:17.0];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = self.playlistInfo.name;
    self.navigationItem.titleView = label;

}

- (void) setUpNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityNotifications:) name:@"SongAdded" object:nil];
}

- (void) activityNotifications:(NSNotification *)notification {
    
    if ([[notification object] isKindOfClass:[SongManager class]]) {
        
        if ([[notification name] isEqualToString:@"SongAdded"]) {
            
            [self songAddedNotification:notification.userInfo];
            
        } else if ([[notification name] isEqualToString:@"FailedToAddSong"]) {
            
            [self.tableView reloadData];
            
        }
        
    }
    
}

- (void) songAddedNotification: (NSDictionary*) userInfo {
    
    NSDictionary* songInfo = userInfo;
    
    PFObject* song = songInfo[@"song"];
    NSString* songTitle = song[@"title"];
    
    NSArray *songsInLocal = [Song MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    // GOTTA SAVE SONGS IN PLAYLIST!
    iLListTracks = [[NSMutableArray alloc] initWithArray:songsInLocal];
    
    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"Added %@!", songTitle] ];
    
    
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated {
    
    [self playlistLogic];

}

- (void) playlistLogic {
    
    [self getSongsFromLocal];
    
    
}

- (void) getSongsFromLocal {
    
    NSArray *songsInLocal = [Song MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];

    iLListTracks = [[NSMutableArray alloc] initWithArray:songsInLocal];
    [self.tableView reloadData];
    
    
    if (songsInLocal.count == 0) {
        [self fetchSongsFromServer];
    } else {
        
        [self checkIfPlaylistUpdated];
    }
   
    
}

- (void) checkIfPlaylistUpdated {
    
    // Checking if the iLList updated in the server
    PFQuery *updatedIllistQuery = [PFQuery queryWithClassName:@"Illist"];
    
    [updatedIllistQuery getObjectInBackgroundWithId:self.playlistInfo.objectId block:^(PFObject *updatedIllistObject, NSError *error) {
        
        if (!error) {
            
            Playlist *playlist = [Playlist MR_findFirstByAttribute:@"objectId" withValue:self.playlistInfo.objectId inContext:defaultContext];
            
            // Update if updatedAt dates do not equal
            if (![updatedIllistObject.updatedAt isEqual: playlist.updatedAt]) {
                
                [self updatePlaylistInLocal:updatedIllistObject];
                
            } else {
                // No need to update playlist since it is not updated
//                NSLog(@"No need to update playlist 163.)");
            }
        }
 
        
    }];

}

- (void) updatePlaylistInLocal:(PFObject*) updatedIllistObject {
 
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        Playlist *playlist = [Playlist MR_findFirstByAttribute:@"objectId" withValue:self.playlistInfo.objectId inContext:localContext];
        
        playlist.updatedAt = updatedIllistObject.updatedAt;
        playlist.songCount = updatedIllistObject[@"SongCount"];
        
    } completion:^(BOOL success, NSError *error) {
        
        if (!error) {
            
            [self fetchSongsFromServer];
        } else {
            
//            NSLog(@"The playlist is not updated 187.)");
        }
        
    }];

}

- (void ) fetchSongsFromServer {
    
    PFQuery *updatedQuery = [PFQuery queryWithClassName:@"Song"];
    
    [updatedQuery whereKey:@"iLListId" equalTo:self.playlistInfo.objectId];
    
    [updatedQuery orderByDescending:@"createdAt"];
    
    [updatedQuery findObjectsInBackgroundWithBlock:^(NSArray *songsInServer, NSError *error) {
        
        if (!error) {
            
            [self saveSongsToLocal: songsInServer];
            
        } else {
//            NSLog(@"Error with fetching songs from server 208");
        }
        
    }];
    
}

- (void ) saveSongsToLocal: (NSArray*) songsInServer {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        Playlist *playlistInLocal = [Playlist MR_findFirstByAttribute:@"objectId" withValue:self.playlistInfo.objectId inContext:localContext];
        
        //Delete songs in local and then create
        NSArray *songsInThisPlaylist = [Song MR_findByAttribute:@"playlistId" withValue:playlistInLocal.objectId inContext:localContext];
        
        for (Song *songToDelete in songsInThisPlaylist ) {
        
            [songToDelete MR_deleteEntityInContext:localContext];
        }
        
        for (PFObject *songInServer in songsInServer) {
            
            Song *songInLocal = [Song MR_createEntityInContext:localContext];
            songInLocal.objectId = songInServer.objectId;
            songInLocal.title = songInServer[@"title"];
            songInLocal.playlistId = songInServer[@"iLListId"];
            songInLocal.stream_url = songInServer[@"stream_url"];
            songInLocal.artwork = songInServer[@"artwork"];
            songInLocal.time = songInServer[@"time"];
            songInLocal.hostName = songInServer[@"hostName"];
            songInLocal.uploadingUser = songInServer[@"uploadingUser"];
            songInLocal.hostId = songInServer[@"host"];
            songInLocal.createdAt = songInServer.createdAt;
            
            [playlistInLocal addSongObject:songInLocal];
        }
        
//        playlistInLocal.songCount = [NSNumber numberWithInteger:[playlistInLocal.song count]];
        
        
    } completion:^(BOOL success, NSError *error) {
        
        if (!error) {
            
            NSArray *songsInLocal = [Song MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
            
            iLListTracks = [[NSMutableArray alloc] initWithArray:songsInLocal];
            
            [self.tableView reloadData];
            
        } else {
            
//            NSLog(@"Songs didn not save locally 252.)");
            
        }
        
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [iLListTracks count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
    static NSString *CellIdentifier = @"songCell";
    CustomSearchedSongTableViewCell *cell = (CustomSearchedSongTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[CustomSearchedSongTableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:CellIdentifier];
    }
    if (tableView == self.tableView) {
        
        // iLList tableview
        
        /* May need to change the code below for code efficiency like how it is written for searchdisplaycontroller
         * by using iLLSong
         */
        
        cell.titleLabel.numberOfLines = 3;
        cell.titleLabel.adjustsFontSizeToFitWidth = YES;
        cell.addedByLabel.adjustsFontSizeToFitWidth = YES;
        
        Song *song = [iLListTracks objectAtIndex:indexPath.row];
        cell.titleLabel.text = song.title;
        cell.uploadingUserLabel.text = song.uploadingUser;
        cell.timeLabel.text = song.time;
        cell.addedByLabel.text = song.hostName;
        
        [cell.albumImage sd_setImageWithURL:[NSURL URLWithString:song.artwork] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageRefreshCached];

    }
    
    return cell;
}

#pragma mark - Getting artwork of the song

- (UIImage *)getArtWork: (NSString* ) imageURL{
//    UIImage *newImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString: imageURL]]];
//    UIImageView *artWork=[[UIImageView alloc]initWithImage:newImage];
    NSString *sizet67x67 = [[NSString alloc] initWithString:imageURL];
    sizet67x67 = [sizet67x67 stringByReplacingOccurrencesOfString:@"large" withString:@"t67x67"];

    NSURL *url = [NSURL URLWithString:sizet67x67];
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:imageData];

    return image;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {


    NSString *searchString = searchBar.text;
    
    if (searchString.length != 0 ) {
        
        NSString *trackName = [NSString stringWithFormat:@"%@", searchString];
        
        trackName = [trackName stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        
        SongManager *songMangerSearchedText;
        
        if (searchBar.selectedScopeButtonIndex == 0) {
            songMangerSearchedText = [[SongManager alloc] initWithTrackName:trackName];

        } else {
            
            
            
        }
        
        
        NSString *resourceURL = [songMangerSearchedText getResourceURL];
        
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"Searching %@",searchBar.text]];
        
        SCRequestResponseHandler handler;
        handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
            [SVProgressHUD dismiss];
            if (self.searchController.searchResultsController) {
                
                [self setUpData];
        
                self.searchResult = [songMangerSearchedText parseTrackData:data];
                vc.searchController = self.searchController;
                vc.iLListTracks = iLListTracks;
                vc.searchResults = self.searchResult;
                vc.playlistInfo = self.playlistInfo;
                [vc.tableView reloadData];
                
            }
            
            [self.tableView reloadData];
            

        };
        
        [SCRequest performMethod:SCRequestMethodGET
                      onResource:[NSURL URLWithString:resourceURL]
                 usingParameters:nil
                     withAccount:nil
          sendingProgressHandler:nil
                 responseHandler:handler];
    }

    
    
}

#pragma mark - Scope bar

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    
    
    
    
}

#pragma mark - Search bar canceled
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {

    [vc.searchResults removeAllObjects];
    [SVProgressHUD dismiss];
    [vc.tableView reloadData];
    
    
}

// When user swipes a cell
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( tableView == self.tableView ) {
        [self.tableView setEditing:NO];
    }    return nil;

}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        Song *deleteSongInLocal = [iLListTracks objectAtIndex:indexPath.row];
        
        PFObject *deleteSong = [PFObject objectWithoutDataWithClassName:@"Song" objectId:deleteSongInLocal.objectId];
        
        [iLListTracks removeObjectAtIndex:indexPath.row];
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [deleteSong deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            if (!error) {
                
                [self updatePlaylistAfterDelete:deleteSongInLocal forRowAtIndexPath:indexPath];
                
//                [self deleteSongInLocal:deleteSong forRowAtIndexPath:indexPath];
                
            } else {
//                NSLog(@"Error in deleting song 456");
                
            }
            
        }];
    
    }
}

//- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Detemine if it's in editing mode
//    if (self.tableView.editing)
//    {
//        return UITableViewCellEditingStyleDelete;
//    }
//    
//    return UITableViewCellEditingStyleNone;
//}

- (void) updatePlaylistAfterDelete:(Song*) deleteSongInLocal forRowAtIndexPath:(NSIndexPath*) indexPath{
    
    // Updating the playlist in the server
    PFObject *illistInServer = [PFObject objectWithoutDataWithClassName:@"Illist" objectId:self.playlistInfo.objectId];
    
    // Updating the playlist's song count
//    Playlist *playlistInLocal = [Playlist MR_findFirstByAttribute:@"objectId" withValue:self.playlistInfo.objectId inContext:[NSManagedObjectContext MR_defaultContext]];
    
   NSArray *songsInLocal = [Song MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    int songCountUpdate = (int)songsInLocal.count ;
    
    if (songCountUpdate > 0 ) {
        songCountUpdate--;
    }

    illistInServer[@"SongCount"] = @(songCountUpdate);
    
    [illistInServer saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
       
        if (!error) {
      
            [self updatePlaylistInLocalAfterDelete:illistInServer songToDelete:deleteSongInLocal forRowAtIndexPath:indexPath];

            
        } else {
//            NSLog(@"Did not update playlist after delete 484");
        }
        
    }];

    
}
- (void) updatePlaylistInLocalAfterDelete: (PFObject*)illistInServer songToDelete:(Song*) deleteSongInLocal forRowAtIndexPath:(NSIndexPath*) indexPath{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        Playlist *playlist = [Playlist MR_findFirstByAttribute:@"objectId" withValue:self.playlistInfo.objectId inContext:localContext];
        
        NSArray *songsInLocal = [Song MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
        
        int songCountUpdate = (int)songsInLocal.count ;

        if (songCountUpdate > 0 ) {
              songCountUpdate--;
        }
        
        playlist.songCount = [NSNumber numberWithInt:songCountUpdate];
        playlist.updatedAt = illistInServer.updatedAt;
        
    } completion:^(BOOL success, NSError *error) {
        
        if (!error) {
            [self deleteSongInLocal:deleteSongInLocal forRowAtIndexPath:indexPath];
            
        } else {
            
//            NSLog(@"The playlist did not update 509.)");
        }
        
    }];

}

- (void) deleteSongInLocal:(Song*)deleteSongInLocal forRowAtIndexPath:(NSIndexPath*) indexPath {
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        Song *deleteSong = [Song MR_findFirstByAttribute:@"objectId" withValue:deleteSongInLocal.objectId inContext:localContext];
        
        [deleteSong MR_deleteEntityInContext:localContext];
        
    } completion:^(BOOL success, NSError *error) {
       
        if (!error) {
//            [iLListTracks removeObjectAtIndex:indexPath.row];
//            
//            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            [self.tableView reloadData];

        } else {
//            NSLog(@"Couldn't delete song in local: 534.)");
        }
        
        
    }];
    
   

}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
 
    // Need to change to edit playlist
    return YES;

    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (tableView == self.tableView) {
        
        [self setCurrentIllistNowPlaying:indexPath];
    }


}


#pragma mark - Setting now playhing object

-(void)setCurrentIllistNowPlaying: (NSIndexPath *) indexPath {

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        
        NowPlaying *nowPlayingDelete = [NowPlaying MR_findFirstInContext:localContext];
        [nowPlayingDelete MR_deleteEntityInContext:localContext];
        
        NSArray *nowPlayingSongArrayToDelete = [NowPlayingSong MR_findAllInContext:localContext];
        
        for (NowPlayingSong *nowPlayingSongDelete in nowPlayingSongArrayToDelete) {

            [nowPlayingSongDelete MR_deleteEntityInContext:localContext];
            
        }


    } completion:^(BOOL success, NSError *error) {

        if (!error) {
            [self setUpNowPlayingSongs:indexPath];
            
   
  
        } else {
//            NSLog(@"Error 653 %@", error);
        }

    }];
    
    
}

- (void) setUpNowPlayingSongs:(NSIndexPath *) indexPath {
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSIndexPath *path = indexPath;
        NSInteger row = path.row;

        
        NSArray *songsInLocalArray = [Song MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:localContext];
        
        NowPlaying *nowPlaying = [NowPlaying MR_createEntityInContext:localContext];
        nowPlaying.playlistId = self.playlistInfo.objectId;
        nowPlaying.songIndex = [NSNumber numberWithInteger:row];
        nowPlaying.playlistName = self.playlistInfo.name;
        nowPlaying.updatedAt = [NSDate date];
        
        Song *currentSong = [iLListTracks objectAtIndex:indexPath.row];
        nowPlaying.currentlyPlayingSongId = currentSong.objectId;

        for ( Song *songsInLocal in songsInLocalArray ) {
            
            NowPlayingSong *nowPlayingSong = [NowPlayingSong MR_createEntityInContext:localContext];
            
            nowPlayingSong.artwork = songsInLocal.artwork;
            nowPlayingSong.hostId = songsInLocal.hostId;
            nowPlayingSong.hostName = songsInLocal.hostName;
            nowPlayingSong.objectId = songsInLocal.objectId;
            nowPlayingSong.playlistId = songsInLocal.playlistId;
            nowPlayingSong.stream_url = songsInLocal.stream_url;
            nowPlayingSong.time = songsInLocal.time;
            nowPlayingSong.title = songsInLocal.title;
            nowPlayingSong.uploadingUser = songsInLocal.uploadingUser;
            nowPlayingSong.createdAt = songsInLocal.createdAt;
            
            nowPlayingSong.nowPlaying = nowPlaying;
        }
        
    }completion:^(BOOL success, NSError *error) {
        
        if (!error) {

        }
    
        
        
        if(self.tabBarController.selectedIndex == 0) {
            [self backButton:self];
            // Change to media player from me tab
            [self.tabBarController setSelectedIndex:2];
            
        } else if(self.tabBarController.selectedIndex == 1) {
            
            // Change to media player from Friend tab
            [self.tabBarController setSelectedIndex:2];
            
        }
    
    }];
}

- (IBAction)backButton:(id)sender {
    
    // Only when user checks out playlist from the mediaplayer
    [self.navigationController dismissViewControllerAnimated:YES
 completion:^{

 }];
    
}

#pragma mark - DZN Table view when empty

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text = @"Please search for a song to add";
    
    // dark blue
    UIColor *myColor = [UIColor colorWithRed:51.0f/255.0f green:102.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: myColor};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text = @"To search for a song, click on the search bar and enter a song you would like to add to this playlist";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    // cardinal color?
    UIColor *myColor = [UIColor colorWithRed:250.0f/255.0f green:65.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                 NSForegroundColorAttributeName: myColor,
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}


@end
