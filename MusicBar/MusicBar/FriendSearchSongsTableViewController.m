//
//  FriendSearchSongsTableViewController.m
//  MusicBar
//
//  Created by Jake Choi on 2/25/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import "FriendSearchSongsTableViewController.h"
#import "SCUI.h"
#import "CustomSearchedSongTableViewCell.h"
#import "CustomSong.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <Parse/Parse.h>
#import "MediaPlayerViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>

#import "FriendSearchControllerTableViewController.h"

@interface FriendSearchSongsTableViewController (){
    
    NSMutableArray *iLListTracks;
    NSManagedObjectContext *defaultContext;
    int counter;
    UINavigationController *navController;
    FriendSearchControllerTableViewController *vc;

}

@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic, strong) NSArray *tracks;
@property (nonatomic, strong) NSDictionary *userTracks;

@property (nonatomic, strong) NSMutableArray *searchResult;



@end

@implementation FriendSearchSongsTableViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self setUpSearchController];
    
    [self setNSManagedObjectContext];
    [self setupTableView];
    [self setUpNotifications];
    [self setupTitle];
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
- (void) setUpData {
    navController = (UINavigationController *)self.searchController.searchResultsController;
    
    
    vc = (FriendSearchControllerTableViewController *)navController.topViewController;
}

- (void) setUpSearchController {
    UINavigationController *searchResultsController = [[self storyboard] instantiateViewControllerWithIdentifier:@"FriendTableSearchResultsNavController"];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    
//    self.searchController.searchResultsUpdater = self;
    
    [self.searchController.searchBar setPlaceholder:@"Find Your Groove :)"];
    
    self.searchController.searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"All", @"SoundCloud User", nil];
    
    [self.searchController.searchBar setScopeBarButtonTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [self.searchController.searchBar setScopeBarButtonTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil] forState:UIControlStateSelected];
    
    [self adjustSearchBarToShowScopeBar];
    
    self.searchController.searchBar.delegate = self;

    self.searchController.hidesNavigationBarDuringPresentation = NO;
    
    self.definesPresentationContext = YES;

    
}

- (void)adjustSearchBarToShowScopeBar {
    
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
}


- (void) setNSManagedObjectContext {
    
    
    defaultContext = [NSManagedObjectContext MR_defaultContext];
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

- (void) setUpNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityNotifications:) name:@"SongAdded" object:nil];
}

- (void) activityNotifications:(NSNotification *)notification {
    
    if ([[notification object] isKindOfClass:[iLLSongFriendManager class]]) {
        
        if ([[notification name] isEqualToString:@"SongAdded"]) {
            
            [self songAddedNotification:notification.userInfo];
            
        } else if ([[notification name] isEqualToString:@"ReloadTableView"]) {
            
            [self.tableView reloadData];
            
        }
        
    }
    
}

- (void) songAddedNotification: (NSDictionary*) userInfo {
    
    NSDictionary* songInfo = userInfo;
    
    PFObject* song = songInfo[@"song"];
    NSString* songTitle = song[@"title"];
    
    NSArray *songsInLocal = [SongFriend MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    // GOTTA SAVE SONGS IN PLAYLIST!
    iLListTracks = [[NSMutableArray alloc] initWithArray:songsInLocal];
    
    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"Added %@!", songTitle] ];
    

    [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated {
    
    [self playlistLogic];
    
}

- (void) viewWillDisappear:(BOOL)animated {
    [SVProgressHUD dismiss];
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        
        // View is disappearing because a new view controller was pushed onto the stack

        
    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        
        // View is disappearing because it was popped from the stackd
        
        [self deleteSongFriendInLocal];

    }
    
    
}

- (void) deleteSongFriendInLocal {
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        NSArray *songsInLocal = [SongFriend MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:localContext];
        
        for (SongFriend *songToDelete in songsInLocal) {
            
            [songToDelete MR_deleteEntityInContext:localContext];
        
        }

    } completion:^(BOOL success, NSError *error) {
        
        
        if (!error) {
            NSArray *songsInLocal = [SongFriend MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
            
            iLListTracks = [[NSMutableArray alloc] initWithArray:songsInLocal];
            
            [self.tableView reloadData];

            
        } else {
    
        }
        
        
    }];

    
}

- (void) playlistLogic {
    
    [self getSongsFromLocal];
    
}

- (void) getSongsFromLocal {

    
    if (self.playlistInfo.objectId) {
         [self fetchSongsFromServer];
    }

    
}



- (void ) fetchSongsFromServer {
    PFQuery *updatedQuery = [PFQuery queryWithClassName:@"Song"];

    [updatedQuery whereKey:@"iLListId" equalTo:self.playlistInfo.objectId];
    
    [updatedQuery orderByDescending:@"createdAt"];
    
    [SVProgressHUD showWithStatus:@"Loading Playlist"];
    
    [updatedQuery findObjectsInBackgroundWithBlock:^(NSArray *songsInServer, NSError *error) {

        if (!error) {
            

            if (counter<1) {
   
                [self saveSongsToLocal: songsInServer];
                counter++;
            } else {
                [SVProgressHUD dismiss];
            }
            
        } else {
//             NSLog(@"1.3)");
//            NSLog(@"Error with fetching songs from server 235");
        }
        
    }];
    
}

- (void ) saveSongsToLocal: (NSArray*) songsInServer {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        PlaylistFriend *playlistInLocal = [PlaylistFriend MR_findFirstByAttribute:@"objectId" withValue:self.playlistInfo.objectId inContext:localContext];
        
        //Delete songs in local and then create
        NSArray *songsInThisPlaylist = [SongFriend MR_findByAttribute:@"playlistId" withValue:playlistInLocal.objectId inContext:localContext];
        
        for (SongFriend *songToDelete in songsInThisPlaylist ) {
            
            [songToDelete MR_deleteEntityInContext:localContext];
        }
        
        for (PFObject *songInServer in songsInServer) {
            
            SongFriend *songInLocal = [SongFriend MR_createEntityInContext:localContext];
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
            
            [playlistInLocal addSongFriendObject:songInLocal];
        }


    } completion:^(BOOL success, NSError *error) {
        
        if (!error) {
            
            NSArray *songsInLocal = [SongFriend MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
            
            iLListTracks = [[NSMutableArray alloc] initWithArray:songsInLocal];
            
            [self.tableView reloadData];
            
        } else {
            
//            NSLog(@"Songs didnt not save locally 285.)");
            
        }
        [SVProgressHUD dismiss];
        
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
        
        // album image to framed in a circle
        cell.albumImage.layer.cornerRadius = cell.albumImage.frame.size.height /2;
        cell.albumImage.layer.masksToBounds = YES;
        cell.albumImage.layer.borderWidth = 0;
        
        
        // Songs tableview
        cell.titleLabel.numberOfLines = 3;
        cell.titleLabel.adjustsFontSizeToFitWidth = YES;
        cell.addedByLabel.adjustsFontSizeToFitWidth = YES;
        
        /* May need to change the code below for code efficiency like how it is written for searchdisplaycontroller
         * by using iLLSong
         */
        SongFriend *song = [iLListTracks objectAtIndex:indexPath.row];
        cell.titleLabel.text = song.title;
        cell.uploadingUserLabel.text = song.uploadingUser;
        cell.timeLabel.text = song.time;
        cell.addedByLabel.text = song.hostName;
        
        [cell.albumImage sd_setImageWithURL:[NSURL URLWithString:song.artwork] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageRefreshCached];
        
    }
    
    return cell;
}



#pragma mark - Search Delegate Methods
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {

    NSString *searchString = searchBar.text;
    
    if (searchString.length != 0 ) {
        NSString *trackName = [NSString stringWithFormat:@"%@", searchString];
        
        trackName = [trackName stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        
        iLLSongFriendManager *songMangerSearchedText = [[iLLSongFriendManager alloc] initWithTrackName:trackName] ;
        
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

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    [vc.searchResults removeAllObjects];

    [vc.tableView reloadData];
    [SVProgressHUD dismiss];
    
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

// When user swipes a cell
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( tableView == self.tableView ) {
        [self.tableView setEditing:NO];
    }    return nil;
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        SongFriend *deleteSongInLocal = [iLListTracks objectAtIndex:indexPath.row];
        
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

- (void) updatePlaylistAfterDelete:(SongFriend*) deleteSongInLocal forRowAtIndexPath:(NSIndexPath*) indexPath{
    
    // Updating the playlist in the server
    PFObject *illistInServer = [PFObject objectWithoutDataWithClassName:@"Illist" objectId:self.playlistInfo.objectId];
    
    // Updating the playlist's song count
    NSArray *songsFriendInLocal = [SongFriend MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    int songCountUpdate = (int)songsFriendInLocal.count ;
    
    if (songCountUpdate > 0 ) {
        songCountUpdate--;
    }

    illistInServer[@"SongCount"] = @(songCountUpdate);
    
    [illistInServer saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (succeeded) {
            [self updatePlaylistInLocalAfterDelete:illistInServer songToDelete:deleteSongInLocal forRowAtIndexPath:indexPath];
            
            
        } else {
//            NSLog(@"Did not update playlist after delete 484");
        }
        
    }];
    
    
}
- (void) updatePlaylistInLocalAfterDelete: (PFObject*)illistInServer songToDelete:(SongFriend*) deleteSongInLocal forRowAtIndexPath:(NSIndexPath*) indexPath{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        PlaylistFriend *playlist = [PlaylistFriend MR_findFirstByAttribute:@"objectId" withValue:self.playlistInfo.objectId inContext:localContext];
        
        NSArray *songsFriendInLocal = [SongFriend MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
        
        int songCountUpdate = (int)songsFriendInLocal.count ;
        
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

- (void) deleteSongInLocal:(SongFriend*)deleteSongInLocal forRowAtIndexPath:(NSIndexPath*) indexPath {
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        SongFriend *deleteSong = [SongFriend MR_findFirstByAttribute:@"objectId" withValue:deleteSongInLocal.objectId inContext:localContext];
        
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
    //    [self.navigationItem.backBarButtonItem setEnabled:NO];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        NSIndexPath *path = indexPath;
        NSInteger row = path.row;
        
        NowPlaying *nowPlayingDelete = [NowPlaying MR_findFirstInContext:localContext];
        [nowPlayingDelete MR_deleteEntityInContext:localContext];
        
        NowPlaying *nowPlaying = [NowPlaying MR_createEntityInContext:localContext];
        nowPlaying.playlistId = self.playlistInfo.objectId;
        nowPlaying.songIndex = [NSNumber numberWithInteger:row];
        nowPlaying.playlistName = self.playlistInfo.name;
        nowPlaying.updatedAt = [NSDate date];

        SongFriend *currentSong = [iLListTracks objectAtIndex:indexPath.row];
        nowPlaying.currentlyPlayingSongId = currentSong.objectId;
        
        NSArray *nowPlayingSongArrayToDelete = [NowPlayingSong MR_findAllInContext:localContext];
        
        for (NowPlayingSong *nowPlayingSongDelete in nowPlayingSongArrayToDelete) {
            
            [nowPlayingSongDelete MR_deleteEntityInContext:localContext];
            
        }
        
        NSArray *songsInLocalArray = [SongFriend MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:localContext];

        for ( SongFriend *songsInLocal in songsInLocalArray ) {
            
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
        
        
        
    } completion:^(BOOL success, NSError *error) {
        
        if (!error) {
  
        } else {
//            NSLog(@"Error 653 %@", error);
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
