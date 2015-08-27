//
//  FriendsTableViewController.m
//  MusicBar
//
//  Created by Jake Choi on 1/14/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import "FriendsTableViewController.h"
#import <RHAddressBook/AddressBook.h>
#import <SVProgressHUD/SVProgressHUD.h>

// Core Data
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"
#import "UserFriendList.h"

#import "Friend.h"
#import "FriendPhonenumber.h"

#import "FriendTabTheirCollectionViewController.h"
#import "SearchFriendsTableViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface FriendsTableViewController () {
    
    NSMutableArray *friendsList;
    NSMutableDictionary *friendsPhonenumberDictionary;
    NSMutableArray *friendsWhoExistsOniLList;
    
    NSManagedObjectContext *defaultContext;
    
    NSMutableDictionary *friendsFacebookIDDictionary;

}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (weak, nonatomic) IBOutlet UISearchBar *friendSearchBar;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) SearchFriendsTableViewController *searchFriendsTableController;

@end

@implementation FriendsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNSManagedObjectContext];

    [self initializeData];
    
    [self setUpNavigationBar];
    
    [self setUpTableView];

    [self refreshButton:self];

}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.searchFriendsTableController.tableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated {
    [SVProgressHUD dismiss];
}

-(void) setUpNavigationBar{
    
    NSDictionary *size = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Wisdom Script" size:24.0],NSFontAttributeName, nil];
    self.navigationController.navigationBar.topItem.title = @"Friends";
    self.navigationController.navigationBar.titleTextAttributes = size;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    
    [self.tabBarController.tabBar setTintColor:[UIColor whiteColor]];
    
}


- (void) setNSManagedObjectContext {
    
    defaultContext = [NSManagedObjectContext MR_defaultContext];
    
}

-(void) viewDidAppear:(BOOL)animated {

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Set up table view
- (void) setUpTableView {
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    [self.tableView setRowHeight:46.0];
    
}

#pragma mark - Initialization of data
- (void) initializeData {
    
    friendsFacebookIDDictionary = [[NSMutableDictionary alloc] init];
    
    friendsPhonenumberDictionary = [[NSMutableDictionary alloc] init];
    self.searchFriendsTableController = [[SearchFriendsTableViewController alloc] init];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchFriendsTableController];
    [self.searchController.searchBar sizeToFit];
    [self.searchController.searchBar setPlaceholder:@"Find new Friends by username :)"];
    
    self.tableView.tableHeaderView = self.searchController.searchBar;

    self.searchController.delegate = self;
    self.searchController.searchBar.delegate = self;
    self.definesPresentationContext = YES;
}

#pragma mark - Buttons
- (IBAction)refreshButton:(id)sender {
    
    /* Users first time on the app will have to press the
     * refresh button to load up their contacts from the address book
     */
    [self.refreshButton setEnabled:NO];
    
    [self retrieveFriendsFromLocal];
}


#pragma mark - Retrieve contacts from local
- (void) retrieveFriendsFromLocal {
    
    NSArray *friendsCoreDataArray = [Friend MR_findAllSortedBy:@"name" ascending:YES];
    
    if (friendsCoreDataArray.count == 0) {
        
        [SVProgressHUD showWithStatus:@"Loading Friends through Facebook :)"];
        
        [self queryFriendsFromParse];
        
        // If no friend object exists. This is when the user first goes into friend time in his/ her lifetime of using the app
//        [self queryFacebookIDFromUsers];
        
    } else {
        
        // Querying friends from local storage
        friendsList = [[NSMutableArray alloc] initWithArray:friendsCoreDataArray];
        
        // Sort existings friends on top of list
        [self sortFriendsWhoExistsOnIllist];
        
        // Set the refreshbutton back to enabled because loading done
        [self.refreshButton setEnabled:YES];
        [SVProgressHUD dismiss];
   
        
    }
    
    
}

- (void) queryFriendsFromParse {
    
    PFQuery *friendQuery = [PFQuery queryWithClassName:@"Friend"];
    
    [friendQuery whereKey:@"host" equalTo:[PFUser currentUser].objectId];
    
    [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *friendsInParse, NSError *error) {
        
        if (!error) {
            
            if (friendsInParse.count != 0) {
                
                [self addFriendsFromParse:friendsInParse];
                
            } else {
                
                [self queryFacebookIDFromUsers];
            }
            
        }
      
        
    }];

    
}

- (void) addFriendsFromParse:(NSArray*) friendsInParse {
    
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        // Finding current User in coredata and updating with the userfriendlist in coredata
        CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:localContext];
        UserFriendList *currentUserFriendList = [UserFriendList MR_findFirstInContext:localContext];
        
        
        for (PFObject* friendInParse in friendsInParse) {
            
            Friend *friendInLocal = [Friend MR_createEntityInContext:localContext];
            friendInLocal.name = friendInParse[@"name"];
            friendInLocal.hostId = [PFUser currentUser].objectId;
            friendInLocal.userId = friendInParse[@"userId"];
            friendInLocal.friend_exists = @(YES);
            [currentUserFriendList addFriendObject:friendInLocal];

            
        }
        
        currentUser.userFriendList = currentUserFriendList;
        
        
    } completion:^(BOOL success, NSError *error) {
        
        
        if (success) {
            
            // User's Friends exist in the database
            CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:defaultContext];
            
            NSArray *friends = [currentUser.userFriendList.friend allObjects];
            
            friendsList = [[NSMutableArray alloc] initWithArray:friends];
            
            [self sortFriendsWhoExistsOnIllist];
            
        } else {
            
            // User's Friends doesn't exist in the database
            friendsList = [[NSMutableArray alloc] init];
            NSLog( @"Error: 246.)");
            
        }
        
        [SVProgressHUD dismiss];
        [self.refreshButton setEnabled:YES];
        
    }];


    
    
}

- (void) queryFacebookIDFromUsers {
    
    // This is ran when users first use the app to find friends from facebook :)
    
    PFQuery *query = [PFUser query];
    
    [query selectKeys:@[@"facebookID", @"name"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        if (error) {
            NSString *errorString = [error userInfo][@"error"];
            NSLog(@"170.) Error: %@", errorString);
            [SVProgressHUD dismiss];
            [self.refreshButton setEnabled:YES];
        } else {

            [self filterFacebookID:users];
            
        }
        
    }];
    
}

- (void) filterFacebookID: (NSArray*) users {

    for (PFUser* user in users) {
        if (user[@"facebookID"]) {
           
            [friendsFacebookIDDictionary setObject:user forKey:user[@"facebookID"]];
            
        }

    }
    [self getFriendsFromFacebook];
    
}


- (void) getFriendsFromFacebook {
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"me/friends"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        
        
        if (!error) {
            // Handle the result
            NSArray *friendsWhoExistOnApp = result[@"data"];
        
            [self addFriendsFromFacebookToServer:friendsWhoExistOnApp];
        } else {
            [SVProgressHUD dismiss];
            [self.refreshButton setEnabled:YES];
        }
        
        
    }];
    
    
}

- (void) addFriendsFromFacebookToServer: (NSArray*) friendsWhoExistOnApp {
    
    NSMutableArray *friendToSave = [[NSMutableArray alloc] init];
    
    PFACL *acl = [PFACL ACL];
    [acl setReadAccess:YES forUser:[PFUser currentUser]];
    [acl setWriteAccess:YES forUser:[PFUser currentUser]];
    
    
    for (NSDictionary* friendInfo in friendsWhoExistOnApp) {
    
        PFUser *user = [friendsFacebookIDDictionary objectForKey:friendInfo[@"id"]];
        
        PFObject *friend = [PFObject objectWithClassName:@"Friend"];
        
        // Setting ACL. Only the current user can view the Friend PFObject
        friend.ACL = acl;
        
        friend[@"host"] = [[PFUser currentUser] objectId];
        
        friend[@"friend_exists"] = @(YES);
        
        friend[@"name"] = user[@"name"];
        
        friend[@"userId"] = user.objectId;
        
        [friendToSave addObject:friend];

    }
    
    [PFObject saveAllInBackground:friendToSave block:^(BOOL succeeded, NSError *error) {
        
        if (succeeded) {
            
            [self addFriendsFromFacebookLocally:friendsWhoExistOnApp];
            

        } else {
            
            NSLog(@"Error 275.)");
             [SVProgressHUD dismiss];
            [self.refreshButton setEnabled:YES];
        }
        
    }];


}

- (void) addFriendsFromFacebookLocally: (NSArray*) friendsWhoExistOnApp {

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        // Finding current User in coredata and updating with the userfriendlist in coredata
        CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:localContext];
        UserFriendList *currentUserFriendList = [UserFriendList MR_findFirstInContext:localContext];
        
        for (NSDictionary* friendInfo in friendsWhoExistOnApp) {
            
            if ([friendsFacebookIDDictionary objectForKey:friendInfo[@"id"]]) {
                
                Friend *friend = [Friend MR_createEntityInContext:localContext];
                PFUser *userFriend = [friendsFacebookIDDictionary objectForKey:friendInfo[@"id"]];
                
                friend.name = userFriend[@"name"];
                friend.hostId = [PFUser currentUser].objectId;
                friend.userId = userFriend.objectId;
                friend.friend_exists = @(YES);
                
                [currentUserFriendList addFriendObject:friend];
            }
            
        }
        
        currentUser.userFriendList = currentUserFriendList;
        
        
    } completion:^(BOOL success, NSError *error) {
        
        
        if (success) {
            
            // User's Friends exist in the database
            CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:defaultContext];
            
            NSArray *friends = [currentUser.userFriendList.friend allObjects];
            
            friendsList = [[NSMutableArray alloc] initWithArray:friends];
            
            [self sortFriendsWhoExistsOnIllist];
            
        } else {
            
            // User's Friends doesn't exist in the database
            friendsList = [[NSMutableArray alloc] init];
            NSLog( @"Error: 335.)");
            
        }
        
        [SVProgressHUD dismiss];
        [self.refreshButton setEnabled:YES];
        
    }];
    
}

- (void) sortFriendsWhoExistsOnIllist {
    friendsWhoExistsOniLList = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < friendsList.count; i++ ) {
        
        // For friends who exist on the server
        Friend *friend = [friendsList objectAtIndex:i];
        
        if ([friend.friend_exists isEqual:@(YES) ]) {
         
            [friendsWhoExistsOniLList addObject:[friendsList objectAtIndex:i]];
        }
    }
    
    self.searchFriendsTableController.filteredFriendsWhoExistsOniLList = [[NSMutableArray alloc] initWithCapacity:friendsWhoExistsOniLList.count];
    [self.tableView reloadData];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    if (section == 0) {
        return [friendsWhoExistsOniLList count];
    }
    
    return 0;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell" forIndexPath:indexPath];
    
    //dark blue?
    UIColor *myColor = [UIColor colorWithRed:51.0f/255.0f green:102.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
    
    if (indexPath.section == 0) {
        // Friends who exist on iLList
        Friend *friendWhoExist =[friendsWhoExistsOniLList objectAtIndex:indexPath.row];
        
        cell.textLabel.text = friendWhoExist.name;
        cell.textLabel.textColor = myColor;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        
    }

        return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0 ) {
        return @"Friends on MusicBar";
    }
    return @"";
}


#pragma mark - DZN Table view when empty

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text = @"Your friend list is empty :(";
    
    // dark blue
    UIColor *myColor = [UIColor colorWithRed:51.0f/255.0f green:102.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: myColor};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text = @"Search 'solechang' as your first friend!";
    
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

#pragma mark - Navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
     if ([segue.identifier isEqualToString:@"friendSegue"]){
         
         // Get destination view
         FriendTabTheirCollectionViewController *controller = (FriendTabTheirCollectionViewController*)segue.destinationViewController;
         
         // Initializing indexpath for the friend cell
         
         if (sender==nil) {
             NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
             Friend *selectedFriend =[friendsWhoExistsOniLList objectAtIndex:selectedIndexPath.row];

             controller.friendInfo = selectedFriend;
         } else if(sender==self.searchFriendsTableController){
             NSIndexPath *selectedIndexPath = [self.searchFriendsTableController.tableView indexPathForSelectedRow];
             Friend *selectedFriend =[self.searchFriendsTableController.filteredFriendsWhoExistsOniLList objectAtIndex:selectedIndexPath.row];
             controller.friendInfo = selectedFriend;
             
//             [self.searchFriendsTableController setActive:NO];
         }
     }
 }

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0 ) {
        // Only segue to FriendsDetailTVC if user exists on iLList server (friendsWhoExistsOniLList array)
        [self performSegueWithIdentifier:@"friendSegue" sender:nil];
    }
    
}

#pragma mark - search for friend - Anthony
//-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    
    [self.searchFriendsTableController.filteredFriendsWhoExistsOniLList removeAllObjects];
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    PFQuery *query = [PFUser query];
    //query = [PFQuery queryWithClassName:@"User"];
    //[query whereKey:@"name" equalTo:self.searchController.searchBar.text];
    
    [query selectKeys:@[@"name"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSString *errorString = [error userInfo][@"error"];
            NSLog(@"935 Error: %@", errorString);
            
        }
        else {
            // iterate through the objects array, which contains PFObjects for each Student
            for(PFObject *pfObject in objects){
                Friend *friend = [Friend MR_createEntity];
                friend.name =pfObject[@"name"];
                friend.userId = pfObject.objectId;
                [tempArray addObject:friend];

            }
            // Filter the array using NSPredicate

            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.name contains[c] %@",self.searchController.searchBar.text];
            self.searchFriendsTableController.filteredFriendsWhoExistsOniLList = [NSMutableArray arrayWithArray:[tempArray filteredArrayUsingPredicate:predicate]];
            
            self.searchFriendsTableController.friendsTableViewController = self;
            
            [self.searchFriendsTableController.tableView reloadData];
        }
    }];
}

@end
