//
//  SearchFriendsTableViewController.m
//  MusicBar
//
//  Created by Anthony Merrin on 7/28/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import "FindFriendsTableViewController.h"

#import "FriendTabTheirCollectionViewController.h"
#import "FriendsTableViewController.h"

#import <MagicalRecord/MagicalRecord.h>
#import "Friend.h"

@interface FindFriendsTableViewController ()

@property (weak,nonatomic) FriendsTableViewController *parentcontroller;


@end

@implementation FindFriendsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.definesPresentationContext = YES;
//    [self setUpNavigationBar];
    
//    [self.tableView registerNib:[UINib nibWithNibName:@"searchFriendsCell" bundle:nil] forCellReuseIdentifier:@"cellID"];
    [self.tableView setRowHeight:50];
    
}

-(void) setUpNavigationBar{
    
    //    NSDictionary *size = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Wisdom Script" size:24.0],NSFontAttributeName, nil];
    //    self.navigationController.navigationBar.topItem.title = @"MusicBar";
    //    self.navigationController.navigationBar.titleTextAttributes = size;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    
    
//    [self.tabBarController.tabBar setTintColor:[UIColor whiteColor]];
    
}


- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if (viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count-2] == self) {
        
        // View is disappearing because a new view controller was pushed onto the stack
        self.searchController.active = NO;
        
    } else if ([viewControllers indexOfObject:self] == NSNotFound) {
        
        // View is disappearing because it was popped from the stackd
//        self.searchController.searchBar.hidden = NO;
        [self.filteredFriendsWhoExists removeAllObjects];
        [self.tableView reloadData];
//        [self deleteSearchedFriends];
    
        
    }
    
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.tableView reloadData];
    self.searchController.searchBar.hidden = NO;
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

    return [self.filteredFriendsWhoExists count];

    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"findFriendsCell" forIndexPath:indexPath];
    
    //dark blue?
    UIColor *myColor = [UIColor colorWithRed:51.0f/255.0f green:102.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
    
    if (indexPath.section == 0) {
        // Friends who exist on iLList

        //Friend *friendWhoExist =[self.filteredFriendsWhoExistsOniLList objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = [[self.filteredFriendsWhoExists objectAtIndex:indexPath.row] name];
        cell.textLabel.textColor = myColor;
        
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.friendsTableViewController performSegueWithIdentifier:@"friendSegue" sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}


@end
