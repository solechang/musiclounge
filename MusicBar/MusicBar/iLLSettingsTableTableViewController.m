//
//  iLLSettingsTableTableViewController.m
//  iLList
//
//  Created by Jake Choi on 11/21/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import "iLLSettingsTableTableViewController.h"
#import <RHAddressBook/AddressBook.h>

// Core Data
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"
#import "UserFriendList.h"
#import "Friend.h"
#import "FriendPhonenumber.h"
#import "Playlist.h"
#import "Song.h"
#import "PlaylistFriend.h"
#import "SongFriend.h"
#import "NowPlaying.h"
#import "NowPlayingSong.h"


@interface iLLSettingsTableTableViewController ()




@property (nonatomic, weak) IBOutlet UITableViewCell *logoutCell;

@end

@implementation iLLSettingsTableTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Makes the unused cells on tableview disappear
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setUpViewController];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)setUpViewController{
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:(49/255.0) green:(17/255.0f) blue:(65/255.0f) alpha:1];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons
- (IBAction)doneButton:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 4;
}

//IK - Gaps between sections

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section {
    
    return 35;
}

//- (CGFloat)tableView:(UITableView*)tableView
//heightForFooterInSection:(NSInteger)section {
//    
//    return 0;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 35.0;
        
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 35)];
    
    //IK - Setting custom background color and a border
    headerView.backgroundColor = self.tableView.backgroundColor;
    headerView.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:1.0].CGColor;
    headerView.layer.borderWidth = 0.0;
    
    //IK - Adding label
    UILabel* headerLabel = [[UILabel alloc] init];
    headerLabel.frame = CGRectMake(15, 0, tableView.frame.size.width - 30, 44);
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor grayColor];
    headerLabel.font = [UIFont boldSystemFontOfSize:16.0];
    headerLabel.textAlignment = NSTextAlignmentLeft;
    
    switch (section)
    {
        case 0:
            headerLabel.text = @"Profile Picture";

            break;
        case 1:
            headerLabel.text = @"Account Settings";
            break;
        case 2:
            headerLabel.text = @"Support";
            break;
        case 3:
            headerLabel.text = @"Log Out";
            break;
        default:
            headerLabel.text = @"";
            break;
    }

    [headerView addSubview:headerLabel];
    
    
    return headerView;
}

//IK - Section header titles

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    NSString *sectionName;
//    
//    switch (section)
//    {
//        case 0:
//            sectionName = NSLocalizedString(@"Profile Picture", @"Profile Picture");
//
//            break;
//        case 1:
//            sectionName = NSLocalizedString(@"Account Settings", @"Account Settings");
//            break;
//        case 2:
//            sectionName = NSLocalizedString(@"Support", @"Support");
//            break;
//        case 3:
//            sectionName = NSLocalizedString(@"Log out", @"Log Out");
//            break;
//        default:
//            sectionName = @"";
//            break;
//    }
//
//    return sectionName;
//}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    //IK - Reference the storyboard for the number of cells per section.
    
    if (section == 0){
        return 1;
    }
    else if (section == 1){
        return 2;
    }
    else if (section == 2){
        return 1;
    }
    else if (section == 3){
        return 1;
    }
    
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *theCellClicked = [self.tableView cellForRowAtIndexPath:indexPath];
    
    if (theCellClicked == self.logoutCell) {
//        RHAddressBook *addressBook = [[RHAddressBook alloc] init];
        
        [self deleteUserDataAndLogout];

    }
    
}

#pragma mark - Deleting core data
- (void) deleteUserDataAndLogout {
    
    // Delete Core data
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        // Delete Current User
        NSArray *deleteCurrentUserArray = [CurrentUser MR_findAllInContext:localContext];
        
        for ( CurrentUser *deleteCurrentUser in deleteCurrentUserArray ) {
            [deleteCurrentUser MR_deleteEntityInContext:localContext];
        }
        
        // Delete playlists in core data
        NSArray *deletePlaylists = [Playlist MR_findAllInContext:localContext];
        
        for (Playlist *deletePlaylist in deletePlaylists) {
            
            [deletePlaylist MR_deleteEntityInContext:localContext];
        }
        
        // Delete songs in core data
        NSArray *deleteSongs = [Song MR_findAllInContext:localContext];
        
        for (Song *deleteSong in deleteSongs) {
            [deleteSong MR_deleteEntityInContext:localContext];
        }
        
        // Delete playlists in core data
        NSArray *deletePlaylistsFriend = [PlaylistFriend MR_findAllInContext:localContext];
        
        for (PlaylistFriend *deletePlaylistFriend in deletePlaylistsFriend) {
            
            [deletePlaylistFriend MR_deleteEntityInContext:localContext];
        }
        
        // Delete songs in core data
        NSArray *deleteSongsFriend = [SongFriend MR_findAllInContext:localContext];
        
        for (SongFriend *deleteSongFriend in deleteSongsFriend) {
            [deleteSongFriend MR_deleteEntityInContext:localContext];
        }
        
        // Delete Friend
        NSArray *friendsDeleteArray = [Friend MR_findAllInContext:localContext];
        
        for ( Friend *deleteFriend in friendsDeleteArray) {
            
            [deleteFriend MR_deleteEntityInContext:localContext];
        }
        
        // Delete FriendPhonenumber
        NSArray *deleteFriendPhonenumberArray = [FriendPhonenumber MR_findAllInContext:localContext];
        
        for (FriendPhonenumber *deleteFriendPhonenumber in deleteFriendPhonenumberArray) {
            
            [deleteFriendPhonenumber MR_deleteEntityInContext:localContext];
        }
        
        // Delete UserFriendList
        NSArray *deleteUserFriendList = [UserFriendList MR_findAllInContext:localContext];
        
        for (UserFriendList *deleteFriendList in deleteUserFriendList) {
            
            [deleteFriendList MR_deleteEntityInContext:localContext];
            
        }
        
        NowPlaying *deleteNowPlaying = [NowPlaying MR_findFirstInContext:localContext];
        [deleteNowPlaying MR_deleteEntityInContext:localContext];
        
        NSArray *deleteNowPlayingSongArray = [NowPlayingSong MR_findAllInContext:localContext];
        
        for (NowPlayingSong *deleteNPS in deleteNowPlayingSongArray) {
            [deleteNPS MR_deleteEntityInContext:localContext];
        }
        

    } completion:^(BOOL success, NSError *error) {
        
        if (success) {
            
//            NSArray *friendsArray = [Friend MR_findAll];
//            NSArray *userFriendList = [UserFriendList MR_findAll];
//            NSArray *currentUser = [CurrentUser MR_findAll];
//            NSArray *userfriendpn = [FriendPhonenumber MR_findAll];
//            NSArray *userIllist = [UserIllist MR_findAll];
//
//            NSLog(@"1.) %@", friendsArray);
//            NSLog(@"2.) %@", userFriendList);
//            NSLog(@"3.) %@", currentUser);
//            NSLog(@"4.) %@", userfriendpn);
//            NSLog(@"5.) %@", userIllist);
            
            
            // Need to delete pinned PFObjects!
            [PFUser logOut];
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                
            }];
        }
    }];
    

}


@end
