//
//  SoundCloudUserSongsTableViewController.m
//  MusicLounge
//
//  Created by Jake Choi on 10/7/15.
//  Copyright © 2015 Sole Chang. All rights reserved.
//

#import "SoundCloudUserSongsTableViewController.h"
#import "SongManager.h"

#import "SCUI.h"

#import <SVProgressHUD/SVProgressHUD.h>

#import "CustomSearchedSongTableViewCell.h"

#import <SDWebImage/UIImageView+WebCache.h>

@interface SoundCloudUserSongsTableViewController () {
    SongManager *songManager;
     NSManagedObjectContext *defaultContext;
    BOOL overLimit;
}

@end

@implementation SoundCloudUserSongsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView setRowHeight:90];
    
    [self setUpNotifications];
    
    [self setNSManagedObjectContext];
    
    [self setUpViewController];
    [self setupTitle];
    [self setUpData];
    
}

- (void) setNSManagedObjectContext {
    
    defaultContext = [NSManagedObjectContext MR_defaultContext];
}

- (void) setUpNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityNotifications:) name:@"SongAdded" object:nil];
}
- (void) activityNotifications:(NSNotification *)notification {
    
    if ([[notification object] isKindOfClass:[SongManager class]]) {
        
        if ([[notification name] isEqualToString:@"SongAdded"]) {
            
            [self songAddedNotification:notification.userInfo];
            
        }
        
    }
    
}

- (void) songAddedNotification: (NSDictionary*) userInfo {
    
    
    NSArray *songsInLocal = [Song MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:defaultContext];
    
    // GOTTA SAVE SONGS IN PLAYLIST!
    self.iLListTracks = [[NSMutableArray alloc] initWithArray:songsInLocal];
    
    [self.tableView reloadData];
}

- (void) setUpData {
    overLimit = YES;
    songManager = [[SongManager alloc] initWithSoundCloudUserID:self.soundCloudUserID];

}

- (void)setUpViewController{
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:(49/255.0) green:(17/255.0f) blue:(65/255.0f) alpha:1];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
}

- (void) setupTitle {
    
    UILabel *label = [[UILabel alloc] init];
    [label setFrame:CGRectMake(0,5,100,20)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:17.0];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    
    label.text = @"Liked Songs";
    self.navigationItem.titleView = label;
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self getUserTracks];
}

- (void) getUserTracks {
    

     NSString *resourceURL;
    
    if (self.tracksOrLikes == 0) {
        
    } else if (self.tracksOrLikes == 1){
        
        resourceURL = [songManager getUserLikesURL:self.scUserInfo.userSoundCloudID limit:@"50" offset:@"0"];
    }
    
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"Loading \xF0\x9F\x98\x8A"]];
    SCRequestResponseHandler handler;
    handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        [SVProgressHUD dismiss];
        
        self.searchResults = [songManager getUserLikedSongs:data];
        [self.tableView reloadData];
        
    };
    
    
    
    [SCRequest performMethod:SCRequestMethodGET
                  onResource:[NSURL URLWithString:resourceURL]
             usingParameters:nil
                 withAccount:nil
      sendingProgressHandler:nil
             responseHandler:handler];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return 0;
    return [self.searchResults count];
}

- (void) loadMoreTracks {
    
    NSString *resourceURL;
    NSString *searchResultsCountOffset;
    NSString *searchResultsCountForLimit;
    
    NSInteger searchCountPlusFifty = self.searchResults.count + 50;
    
    if (self.tracksOrLikes == 0) {
        
    } else if (self.tracksOrLikes == 1) {
        
        //since array count starts at 0 need to plus 1 so duplicate songs do not show up
        searchResultsCountOffset = [NSString stringWithFormat:@"%lu", (unsigned long)self.searchResults.count+1];
        
        searchResultsCountForLimit = [NSString stringWithFormat:@"%lu", (unsigned long)searchCountPlusFifty];


        resourceURL = [songManager getUserLikesURL:self.scUserInfo.userSoundCloudID limit:searchResultsCountForLimit offset:searchResultsCountOffset];
    }

    NSInteger userLikesLimit = [self.scUserInfo.likesCount integerValue];
    
    if ( (searchCountPlusFifty < userLikesLimit) && overLimit) {
userLikesLimit, (long)searchCountPlusFifty, overLimit);
        
     
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"Loading \xF0\x9F\x98\x8A"]];
        SCRequestResponseHandler handler;
        handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
            [SVProgressHUD dismiss];
            
            [self.searchResults addObjectsFromArray: [songManager getUserLikedSongs:data]];
            [self.tableView reloadData];
            
        };
        
        
        
        [SCRequest performMethod:SCRequestMethodGET
                      onResource:[NSURL URLWithString:resourceURL]
                 usingParameters:nil
                     withAccount:nil
          sendingProgressHandler:nil
                 responseHandler:handler];

    } else {
       overLimit = NO;
    }
    
   
    
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Last cell to load more
    NSInteger lastSectionIndex = [tableView numberOfSections] - 1;
    NSInteger lastRowIndex = [tableView numberOfRowsInSection:lastSectionIndex] - 1;
    if ((indexPath.section == lastSectionIndex) && (indexPath.row == lastRowIndex)) {
        
        // This is the last cell
        [self loadMoreTracks];
    }}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"searchedSongCell";
    CustomSearchedSongTableViewCell *cell = (CustomSearchedSongTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[CustomSearchedSongTableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    CustomSong *song = nil;
    
    // album image to framed in a circle
    cell.albumImage.layer.cornerRadius = cell.albumImage.frame.size.height /2;
    cell.albumImage.layer.masksToBounds = YES;
    cell.albumImage.layer.borderWidth = 0;
    
    cell.titleLabel.numberOfLines = 3;
    cell.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    // Searched song table view
    song = [self.searchResults objectAtIndex:indexPath.row];
    cell.titleLabel.text = song.title;
    cell.uploadingUserLabel.text = song.uploadingUser;
    cell.timeLabel.text = song.time;
    cell.addedByLabel.text = @"";
    
    [[cell.contentView viewWithTag:1] performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:NO];
    
    [cell.albumImage sd_setImageWithURL:[NSURL URLWithString:song.image] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageRefreshCached];
    
    
        //IK - Link adding song function here
        UIButton* button = [self addSongButtonPressed:song];
        
        button.tag = 1;
        
        [button setTranslatesAutoresizingMaskIntoConstraints:false];
        NSLayoutConstraint *centerYconstraint = [NSLayoutConstraint constraintWithItem:button
                                                                             attribute:NSLayoutAttributeCenterY
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:cell.contentView
                                                                             attribute:NSLayoutAttributeCenterY
                                                                            multiplier:1.0
                                                                              constant:-15];
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:button
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:30.0f];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:button
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:30.0f];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:button
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:cell.contentView
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:-15];
        
        [cell.contentView addSubview:button];
        [cell.contentView bringSubviewToFront:button];
        [cell.contentView addConstraints:@[centerYconstraint,widthConstraint,heightConstraint,rightConstraint]];
        
        
  
    
    
    return cell;

}

-(IBAction)addToPlaylist:(id)sender {
    
    UIButton *buttonClicked = (UIButton *)sender;
    [buttonClicked setEnabled:NO];
    buttonClicked.backgroundColor = [UIColor lightGrayColor];
    
    UITableViewCell *clickedCell = (UITableViewCell *)[[sender superview] superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:clickedCell];
    
    // maybe show an action sheet with more options
    [self.tableView setEditing:NO];
    
    // Getting song info to add to user's iLList
    CustomSong *songAtCell = nil;
    
    songAtCell = [self.searchResults objectAtIndex:indexPath.row];

    SongManager *songManagerAddSong = [[SongManager alloc] initWithSong:songAtCell];
    
    [songManagerAddSong addSongToPlaylist:songAtCell playlistInfo:self.playlistInfo playlistTracks:self.iLListTracks];
    
}


- (UIButton*) addSongButtonPressed :(CustomSong*)song {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    float buttonSize = 30.0f;
    button.frame = CGRectMake((268+(52-buttonSize)/2.0f), (88-buttonSize)/2.0f, buttonSize, buttonSize);
    [button setTitle:@"+" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor colorWithRed:(67/255.0) green:(157/255.0) blue:(255/255.0) alpha:1];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [button addTarget:self action:@selector(addToPlaylist:) forControlEvents:UIControlEventTouchUpInside];
    //        button.layer.cornerRadius = 5.0f;
    button.layer.cornerRadius = buttonSize/2.0f;
    
    button.layer.borderColor=[UIColor colorWithRed:(67/255.0) green:(157/255.0) blue:(255/255.0) alpha:1].CGColor;
    button.layer.borderWidth=1.0f;
    
    if (song.stream_url == nil) {
        [button setEnabled:NO];
        
        button.backgroundColor = [UIColor lightGrayColor];
    }
    
    // Disable button if the song exists in current playlist
    for (Song *checkIfSongExistsInPlaylist in self.iLListTracks) {
        
        if ([song.stream_url isEqualToString:checkIfSongExistsInPlaylist.stream_url]) {
            
            [button setEnabled:NO];
            
            button.backgroundColor = [UIColor lightGrayColor];
            
        }
    }
    
    
    return button;
    
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
