//
//  SearchFriendsTableViewController.h
//  MusicBar
//
//  Created by Anthony Merrin on 7/28/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FriendsTableViewController.h"


@interface FindFriendsTableViewController : UITableViewController


@property (strong,nonatomic) NSMutableArray *filteredFriendsWhoExists;
@property (nonatomic, strong) NSArray *friendsWhoAreSearched;


@property (weak,nonatomic) FriendsTableViewController *friendsTableViewController;

@property (nonatomic, strong) UISearchController *searchController;

@end
