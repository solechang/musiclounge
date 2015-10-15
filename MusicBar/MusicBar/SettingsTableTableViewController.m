//
//  iLLSettingsTableTableViewController.m
//  iLList
//
//  Created by Jake Choi on 11/21/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import "SettingsTableTableViewController.h"

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

#import <SVProgressHUD/SVProgressHUD.h>


@interface SettingsTableTableViewController ()



@property (weak, nonatomic) IBOutlet UITableViewCell *termsOfUseCell;

@property (nonatomic, weak) IBOutlet UITableViewCell *logoutCell;

@end

@implementation SettingsTableTableViewController

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

- (CGFloat)tableView:(UITableView*)tableView
heightForHeaderInSection:(NSInteger)section {
    
    return 35;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 45.0;
        
}

- (void)popAlertViewForLoggingOut{

    
    
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"MusicLounge"
                                  message:@"Are you sure you want to leave MusicLounge? \xF0\x9F\x98\xAD"
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* noAlert = [UIAlertAction
                         actionWithTitle:@"No"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             
                             [alert dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    
    UIAlertAction* yesAlert = [UIAlertAction
                             actionWithTitle:@"Yes"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [self deleteUserDataAndLogout];
                                 
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    [alert addAction:noAlert];
    [alert addAction:yesAlert];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    
    UITableViewCell *theCellClicked = [self.tableView cellForRowAtIndexPath:indexPath];
  
    if (theCellClicked == self.logoutCell) {
        
        [self popAlertViewForLoggingOut];

    } else if (theCellClicked == self.termsOfUseCell) {
    
        [SVProgressHUD showInfoWithStatus:@"Dropping soon \xF0\x9F\x98\x8F"];
        
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
        
        if (!error) {
            
            
            // Need to delete pinned PFObjects!
            [PFUser logOut];
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                
            }];
        }
    }];
    

}


@end
