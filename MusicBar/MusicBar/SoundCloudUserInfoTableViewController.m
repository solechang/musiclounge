//
//  SoundCloudUserInfoTableViewController.m
//  MusicLounge
//
//  Created by Jake Choi on 10/6/15.
//  Copyright © 2015 Sole Chang. All rights reserved.
//

#import "SoundCloudUserInfoTableViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "SoundCloudUserSongsTableViewController.h"

@interface SoundCloudUserInfoTableViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *scUserImage;
@property (weak, nonatomic) IBOutlet UILabel *tracksLabel;

@property (weak, nonatomic) IBOutlet UILabel *likesLabel;
@property (weak, nonatomic) IBOutlet UILabel *playlistsLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@end

@implementation SoundCloudUserInfoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self setUpImage];
    [self setupTitle];
    [self setUpUserFullName];
    
    [self setUpInfo];
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.
        [self.searchController setActive:NO];
    }

    [super viewWillDisappear:animated];
}

- (void) setUpImage {
    // album image to framed in a circle
    self.scUserImage.layer.cornerRadius = self.scUserImage.frame.size.height /2;
    self.scUserImage.layer.masksToBounds = YES;
    self.scUserImage.layer.borderWidth = 0;

    [self.scUserImage sd_setImageWithURL:[NSURL URLWithString:self.scUserInfo.image] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageRefreshCached];
}

- (void) setupTitle {
    
    UILabel *label = [[UILabel alloc] init];
    [label setFrame:CGRectMake(0,5,100,20)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:16.0];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = self.scUserInfo.title;
    self.navigationItem.titleView = label;
    
}

- (void) setUpUserFullName {
    self.usernameLabel.text = self.scUserInfo.title;
}

- (void) setUpInfo {
    
    self.tracksLabel.text = [NSString stringWithFormat:@"Tracks: %@", self.scUserInfo.tracksCount];
    self.likesLabel.text = [NSString stringWithFormat:@"Likes: %@", self.scUserInfo.likesCount];
    self.playlistsLabel.text = [NSString stringWithFormat:@"Playlists: %@", self.scUserInfo.playlistsCount];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 1;
}
- (IBAction)doneButtonPressed:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];

}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 1) {
        // soundcloud user tracks
        [self performSegueWithIdentifier:@"soundCloudUserSongsSegue" sender:nil];
        
    } else if (indexPath.section == 2) {
        // soundcloud user likes
        [self performSegueWithIdentifier:@"soundCloudUserSongsSegue" sender:nil];
        
    } else if (indexPath.section == 3) {
        //  soundcloud user playlists
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"soundCloudUserSongsSegue"]) {
        
         NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        SoundCloudUserSongsTableViewController *controller = [segue destinationViewController];
        
        controller.playlistInfo = self.playlistInfo;
        controller.playlistFriendInfo = self.playlistFriendInfo;
        controller.soundCloudUserID = self.soundCloudUserID;
        controller.iLListTracks = self.iLListTracks;
        controller.scUserInfo = self.scUserInfo;

        if (selectedIndexPath.section == 1) {
            // user liked songs
            controller.tracksOrLikes = 0;
        } else if (selectedIndexPath.section == 2) {
            // user liked songs
            controller.tracksOrLikes = 1;
        }

        
    }
    
    
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




@end
