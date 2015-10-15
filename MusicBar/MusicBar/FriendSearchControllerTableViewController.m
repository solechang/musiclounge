//
//  FriendSearchControllerTableViewController.m
//  MusicBar
//
//  Created by Jake Choi on 6/10/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import "FriendSearchControllerTableViewController.h"

#import "CustomSearchedSongTableViewCell.h"
#import "CustomSong.h"
#import "SongFriend.h"

#import "SoundCloudUserInfoTableViewController.h"

#import "iLLSongFriendManager.h"

#import <SDWebImage/UIImageView+WebCache.h>

@interface FriendSearchControllerTableViewController ()

@end

@implementation FriendSearchControllerTableViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self setupTitle];
    self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    [self.tableView setRowHeight:90];
    
}
- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.searchController setActive:NO];
    
}

- (void) setupTitle {
    
    UILabel *label = [[UILabel alloc] init];
    [label setFrame:CGRectMake(0,5,100,20)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:17.0];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Search";
    self.navigationItem.titleView = label;
    
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
    
    // Return the number of rows in the section.
    return [self.searchResults count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchedSongCell" forIndexPath:indexPath];
    
    static NSString *CellIdentifier = @"searchedSongCell";
    
    CustomSearchedSongTableViewCell *cell = (CustomSearchedSongTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    CustomSong *song = nil;
    if (cell == nil) {
        cell = [[CustomSearchedSongTableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:CellIdentifier];
    }
    
    cell.titleLabel.numberOfLines = 3;
    cell.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    // album image to framed in a circle
    cell.albumImage.layer.cornerRadius = cell.albumImage.frame.size.height /2;
    cell.albumImage.layer.masksToBounds = YES;
    cell.albumImage.layer.borderWidth = 0;
    
    // Searched song table view
    song = [self.searchResults objectAtIndex:indexPath.row];
    cell.titleLabel.text = song.title;
    cell.uploadingUserLabel.text = song.uploadingUser;
    cell.timeLabel.text = song.time;
    cell.addedByLabel.text = @"";
    
    [cell.albumImage sd_setImageWithURL:[NSURL URLWithString:song.image] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageRefreshCached];
    
    if (![song.addedBy isEqualToString:@"noButtonForSoundCloudUser"]) {
        
        
        
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
        
        
    } else {
        
        if (![song.title containsString:@"is not found :("]) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        
    }
    return cell;
}

-(IBAction)addToPlaylist:(id)sender {
    
    UIButton *buttonClicked = (UIButton *)sender;
    buttonClicked.enabled = NO;
    buttonClicked.backgroundColor = [UIColor lightGrayColor];
    
    UITableViewCell *clickedCell = (UITableViewCell *)[[sender superview] superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:clickedCell];
    
    // maybe show an action sheet with more options
    [self.tableView setEditing:NO];
    
    // Getting song info to add to user's iLList
    CustomSong *songAtCell = nil;
    
    songAtCell = [self.searchResults objectAtIndex:indexPath.row];
    
    iLLSongFriendManager *songManagerAddSong = [[iLLSongFriendManager alloc] initWithSong:songAtCell];
    
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
    for (SongFriend *checkIfSongExistsInPlaylist in self.iLListTracks) {
        
        if ([song.stream_url isEqualToString:checkIfSongExistsInPlaylist.stream_url]) {
            
           [button setEnabled:NO];
            
            button.backgroundColor = [UIColor lightGrayColor];
            
        }
    }
    
    
    return button;
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchController.searchBar.selectedScopeButtonIndex == 1) {
        
        CustomSong *soundCloudUser = [self.searchResults objectAtIndex:indexPath.row];
        
        
        if ( ![soundCloudUser.title  containsString:@"is not found :("]) {
            [self performSegueWithIdentifier:@"SoundCloudUserSegue" sender:nil];
        }
        
        
    }
    [self.searchController.searchBar resignFirstResponder];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([[segue identifier] isEqualToString:@"SoundCloudUserSegue"]) {
        
        UINavigationController *navController = [segue destinationViewController];
        SoundCloudUserInfoTableViewController *ssc = (SoundCloudUserInfoTableViewController*)navController.topViewController;
        
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        
        CustomSong *soundCloudUser = [self.searchResults objectAtIndex:selectedIndexPath.row];
        ssc.scUserInfo = soundCloudUser;
        ssc.searchController = self.searchController;
        
        ssc.playlistInfo = self.playlistInfo;
        
        ssc.iLListTracks = self.iLListTracks;
        
        //        [self.searchController setActive:NO];
        //        [ssc.s setScUserName:soundCloudUser.title];
        
        
        
        
    }
    
}



@end
