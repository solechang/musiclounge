//
//  SearchFriendsTableViewController.m
//  MusicBar
//
//  Created by Anthony Merrin on 7/28/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import "SearchFriendsTableViewController.h"
#import "Friend.h"
#import "FriendTabTheirCollectionViewController.h"
#import "FriendsTableViewController.h"

@interface SearchFriendsTableViewController ()

@property (weak,nonatomic) FriendsTableViewController *parentcontroller;

@end

@implementation SearchFriendsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.tableView registerNib:[UINib nibWithNibName:@"searchFriendsCell" bundle:nil] forCellReuseIdentifier:@"cellID"];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
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
    if (section == 0) {
        return [self.filteredFriendsWhoExistsOniLList count];
    }
    
    return 0;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = (UITableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    
    //dark blue?
    UIColor *myColor = [UIColor colorWithRed:51.0f/255.0f green:102.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
    
    if (indexPath.section == 0) {
        // Friends who exist on iLList
        //Friend *friendWhoExist =[self.filteredFriendsWhoExistsOniLList objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [[self.filteredFriendsWhoExistsOniLList objectAtIndex:indexPath.row] name];
        cell.textLabel.textColor = myColor;
        
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.friendsTableViewController performSegueWithIdentifier:@"friendSegue" sender:self];
}

@end
