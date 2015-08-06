//
//  SearchFriendsTableViewController.h
//  MusicBar
//
//  Created by Anthony Merrin on 7/28/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FriendsTableViewController.h"


@interface SearchFriendsTableViewController : UITableViewController


@property (strong,nonatomic) NSMutableArray *filteredFriendsWhoExistsOniLList;
@property (weak,nonatomic) FriendsTableViewController *friendsTableViewController;


@end
