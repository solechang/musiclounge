//
//  iLLFriendsTableViewController.m
//  iLList
//
//  Created by Jake Choi on 1/14/15.
//  Copyright (c) 2015 iLList. All rights reserved.
//

#import "iLLFriendsTableViewController.h"
#import <RHAddressBook/AddressBook.h>
#import <SVProgressHUD/SVProgressHUD.h>

// Core Data
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"
#import "UserFriendList.h"

#import "Friend.h"
#import "FriendPhonenumber.h"

#import "iLLFriendTabTheirCollectionViewController.h"

@interface iLLFriendsTableViewController () {
    NSMutableArray *friendsList;
    NSMutableDictionary *friendsPhonenumberDictionary;
    NSMutableArray *friendsWhoExistsOniLList;
    
    NSManagedObjectContext *defaultContext;

}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;

@end

@implementation iLLFriendsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNSManagedObjectContext];

    [self initializeData];
    
    [self setUpNavigationBar];
    
    [self setUpTableView];

    [self refreshButton:self];

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
   
//    [self authorizeUserAddressbook];

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
    
    friendsPhonenumberDictionary = [[NSMutableDictionary alloc] init];
    
}

#pragma mark - Buttons
- (IBAction)refreshButton:(id)sender {
    
    /* Users first time on the app will have to press the
     * refresh button to load up their contacts from the address book
     */
    [self.refreshButton setEnabled:NO];
    [SVProgressHUD showWithStatus:@"Loading Friends :)"];
    [self queryFriendsFromServer];
}

#pragma mark - Check if Contactbook is authorized
-(void) authorizeUserAddressbook {
    
    // TODO: Prompt the user to change settings in the Settings when user's doesn't authorize the addressbook
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
        ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted ) {
        
        NSLog(@"Denied");
        
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        

    }
    
}

- (void) queryFriendsFromServer {
    
    // Getting Friend list from local storage
    // This if statement checks if currentUser.userFriendList exists in local storage
    // At first does not exist, when user signs off and signs in again, so the program looks
    // for it online
//    if (currentUser.userFriendList != nil ) {
 
        [self retrieveFriendsFromLocal];
    
    
}

- (void) retrieveUserFriendListFromServer {
    
    PFQuery *friendListQueryFromServer = [PFQuery queryWithClassName:@"UserFriendList"];
    
    [friendListQueryFromServer whereKey:@"host" equalTo:[[PFUser currentUser] objectId]];

    
    [friendListQueryFromServer getFirstObjectInBackgroundWithBlock:^(PFObject *friendListQueryFromServerObject, NSError *error) {


        if (!error) {

            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                
                // Finding current User in coredata and updating the userfriendlist in coredata
                CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:localContext];
                
                UserFriendList *currentUserFriendList = [UserFriendList MR_findFirstInContext:localContext];
                
                currentUserFriendList.updatedAt = friendListQueryFromServerObject.updatedAt;
                currentUserFriendList.objectId = friendListQueryFromServerObject.objectId;
                
                currentUser.userFriendList = currentUserFriendList;
                
            } completion:^(BOOL success, NSError *error) {
                
                
                if (success) {
                    [self retrieveUpdatedFriendsObjectFromServer];
                    
                } else {
                    
                    NSLog( @"Error: retrieveUserFriendListFromServer %@", error);
                    [SVProgressHUD dismiss];
                }
                
            }];
            
            
        }
        
        
        
    }];
}

#pragma mark - Retrieve contacts from local
- (void) retrieveFriendsFromLocal {
    
    NSArray *friendsCoreDataArray = [Friend MR_findAllSortedBy:@"name" ascending:YES];
    
    if (friendsCoreDataArray.count == 0) {

        // If no friend object exists. This is when the user first goes into friend time in his/ her lifetime of using the app
 
        [self retrieveUpdatedFriendsObjectFromServer];
        
    } else {

        // Querying friends from local storage
        friendsList = [[NSMutableArray alloc] initWithArray:friendsCoreDataArray];
 
        // Sort existings friends on top of list
        [self sortFriendsWhoExistsOnIllist];
        
        // Set the refreshbutton back to enabled because loading done
        [self.refreshButton setEnabled:YES];
        [SVProgressHUD dismiss];
        [self cleanPhonenumberStrings];

    }
    
    
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
    [self.tableView reloadData];

}


- (void) retrieveUpdatedFriendsObjectFromServer {
    

    // For retrieving the updated friendsObjectQuery of User's addressbook
    PFQuery *friendsQueryUpdate = [PFQuery queryWithClassName:@"Friend"];
    
    [friendsQueryUpdate whereKey:@"host" equalTo:[[PFUser currentUser] objectId]];
    [friendsQueryUpdate orderByAscending:@"name"];

    
    // Querying 1000. May need to update if user has more than 1000 contacts in the server
    friendsQueryUpdate.limit = 1000;
    
    [friendsQueryUpdate findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"0.1)");
        if (!error) {
          NSLog(@"0.2)");
            if (objects.count != 0) {
             
                /* Update and pin Friends when user deletes app and downloads app again or logs in from different iOS phone
                 */
                // Pinning the Friend PFObject to local storage
                
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {

                    // Finding current User in coredata and updating with the userfriendlist in coredata
                    CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:localContext];
                    
                    UserFriendList *currentUserFriendList = [UserFriendList MR_findFirstInContext:localContext];
                    
                    for (PFObject *friendPFObject in objects) {
                        
                        Friend *friend = [Friend MR_createEntityInContext:localContext];
                        
                        friend.name = friendPFObject[@"name"];
                        friend.objectId = friendPFObject.objectId;
                        
                        // getting phone number in server
                        FriendPhonenumber *friendPhonenumber = [FriendPhonenumber MR_createEntityInContext:localContext];
                        NSArray *friendPhoneNumberArray = friendPFObject[@"phone_number"];
                        
                        for (NSString *phone in friendPhoneNumberArray) {

                             friendPhonenumber.phonenumber = phone;

                            [friend addFriendPhonenumberObject:friendPhonenumber];
                        }
                        
                        friend.hostId = friendPFObject[@"host"];
                        friend.userId = friendPFObject[@"userId"];
                        friend.friend_exists = friendPFObject[@"friend_exists"];

                        [currentUserFriendList addFriendObject:friend];
                    }
                    
                    currentUser.userFriendList = currentUserFriendList;
                    
                } completion:^(BOOL success, NSError *error) {
                    
             
                    if (success) {
       
                        // User's Friends exist in the database
                        CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:defaultContext];
                        
                        NSArray *friends = [currentUser.userFriendList.friend allObjects];
                        
                        friendsList = [[NSMutableArray alloc] initWithArray:friends];
                        [self cleanPhonenumberStrings];
                          NSLog(@"0.3)");
                    } else {
                  NSLog(@"0.4)");
                        // User's Friends doesn't exist in the database
                        friendsList = [[NSMutableArray alloc] init];
                        NSLog( @"Error: retrieveUpdatedFriendsObjectFromServer");
                        
                    }
                    
                }];

                
            } else {
                  NSLog(@"0.5)");
                // PFObject Friend doesn't exists on local storage
    //             sync user's contact address to server
                friendsList = [[NSMutableArray alloc] init];
                [self synchronizeContacts];
                
            }
        } else {
              NSLog(@"0.6)");
            NSLog(@"Error: retrieveUpdatedFriendsObjectFromServer");
            [SVProgressHUD dismiss];
        }
    }];
}
- (void) cleanPhonenumberStrings {
      NSLog(@"0.31)");
    for (int i = 0; i < friendsList.count; i ++) {
        
        Friend *inFriendsList = [friendsList objectAtIndex:i];
        
        if ( inFriendsList.friendPhonenumber != nil) {
            
            NSArray *phonenumberArray = [inFriendsList.friendPhonenumber allObjects];

            
            // Extracting characters to see if user's contacts exists in the database
            for (int j = 0; j < phonenumberArray.count; j++) {
                
                FriendPhonenumber *friendPN = [phonenumberArray objectAtIndex:j];
                
                NSString *phonenumberString = [[NSString alloc] initWithString:friendPN.phonenumber];
                phonenumberString = [[phonenumberString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
                phonenumberString = [phonenumberString stringByReplacingOccurrencesOfString:@"(" withString:@""];
                phonenumberString = [phonenumberString stringByReplacingOccurrencesOfString:@")" withString:@""];
                phonenumberString = [phonenumberString stringByReplacingOccurrencesOfString:@"+" withString:@""];
                phonenumberString = [phonenumberString stringByReplacingOccurrencesOfString:@"-" withString:@""];
                phonenumberString = [phonenumberString stringByReplacingOccurrencesOfString:@"/" withString:@""];
                
                // Check if the phone number is 11 digits USA
                if (phonenumberString.length == 11) {
                    
                    if ([[phonenumberString substringToIndex:1] isEqualToString: @"1"]) {
                        // Take out the first string
                        phonenumberString = [phonenumberString substringFromIndex:1];
                    }
                    
                }
            
                [friendsPhonenumberDictionary setObject:@(i) forKey:phonenumberString];
                
            }
            
        }
    }
    
    [self queryPhonenumberUsersInServer];

    
}


- (void) queryPhonenumberUsersInServer{
 NSLog(@"0.32)");
    /* PFCloud to the server and send the friendsPhonenumberDictionary
     * friendsPhonenumberDictionary will include the user contact's phonenumber and which index the phonenumber is in the
     * friendsList array.
     */

    NSMutableArray *updatingFriendUpdateArray = [[NSMutableArray alloc] init];
    [PFCloud callFunctionInBackground:@"getPhonenumbers" withParameters:@{}
                                block:^(NSArray *phonenumbersInPrivateData, NSError *error) {
                          
                                    /* flag will check if the user's friends joined the app or not. If the friend(s) joined the app,
                                     * UserFriendList will be updated in the server and on local
                                     *
                                     */
                                    BOOL flag = NO;
                      
                                    if(!error) {
                                        for (PFObject *phonenumberInPrivateData in phonenumbersInPrivateData) {
                                            
                                            // Clean phone number
                                            NSString *cleanPhoneNumber = [self cleanPhonenumberStrings:phonenumberInPrivateData[@"phone_number"]];
                                            
                                            if ([friendsPhonenumberDictionary objectForKey:cleanPhoneNumber]) {
                                                
                                                int i = [[friendsPhonenumberDictionary objectForKey:cleanPhoneNumber] intValue];
                                                
                                                Friend *friendInFriendsList = [friendsList objectAtIndex:i];
                                                
                                                // Friend Object will be updated since the Friend joined iLList
                                                if ([friendInFriendsList.friend_exists isEqual:@(NO)]) {
                                                    
                                                    // PFObject to save friendobject in parse server
                                                    PFObject *friendObject = [PFObject objectWithClassName:@"Friend"];
                                                    friendObject.objectId = friendInFriendsList.objectId;
                                                    friendObject[@"friend_exists"] = @(YES);
                                                    [friendObject setObject:phonenumberInPrivateData[@"host"] forKey:@"userId"];
                                                    
                                                    [updatingFriendUpdateArray addObject:friendObject];
                                          
                                                    flag = YES; // update friendslist to server
                                                }
                                                
                                            }
                                            
                                        } // end of for in loop
                        
                                        if (flag) {
                                          
                                            [self updateFriendsInServer:updatingFriendUpdateArray];
                                        } else {
                                         
                                            [self sortFriendsWhoExistsOnIllist];
                                            [self.refreshButton setEnabled:YES];
                                            [SVProgressHUD dismiss];
                                        }
                                        

                                        
                                    } else {
                                        NSLog(@"Error on retrieving PrivateUserData");
                                        /* No need for updating the Friends list to server or local because the existing friends
                                         * on the server did not update
                                         */
                                        
                                        [self sortFriendsWhoExistsOnIllist];
                                        [self.refreshButton setEnabled:YES];
                                        [SVProgressHUD dismiss];
                                    }
                                    
                                    
    }];

    
}
- (void) updateFriendsInServer: (NSMutableArray*) updatingFriendUpdateArray {
    

    // Saving and updating the friend list of those who joined iLList to both the server and local storage
    [PFObject saveAllInBackground:updatingFriendUpdateArray block:^(BOOL succeeded, NSError *error) {
   
        if (succeeded) {
            
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                
                for (PFObject *friendObject in updatingFriendUpdateArray) {
                    Friend *currentFriend = [Friend MR_findFirstByAttribute:@"objectId" withValue:friendObject.objectId inContext:localContext];
                    currentFriend.friend_exists = @(YES);
                    currentFriend.userId = friendObject[@"userId"];
                }
                
            } completion:^(BOOL success, NSError *error) {
                
                if (success) {
                    
                    NSArray *friendsListUpdate = [Friend MR_findAllSortedBy:@"name" ascending:YES];
                    friendsList = [[NSMutableArray alloc] initWithArray:friendsListUpdate];
                    
                    [self saveFriendListQuery];
                    
                } else {
                    NSLog(@"Error: %@", error.localizedDescription);
                    
                }
                
            }]; // end saving for magical record

        } else {
            NSLog(@"Error on updating Friendslist to server");
        }
        
    }]; // end PFObject saveAllInBackground:updatingFriendUpdateArray
}

- (void) saveFriendListQuery {
    
    // Saving UserFriendList to local storage and to the server as well
    PFQuery *friendListQueryFromServer = [PFQuery queryWithClassName:@"UserFriendList"];
    
    [friendListQueryFromServer whereKey:@"host" equalTo:[[PFUser currentUser] objectId]];
    
    [friendListQueryFromServer getFirstObjectInBackgroundWithBlock:^(PFObject *friendListQueryFromServerObject, NSError *error) {
        
        if (!error) {
            
            [friendListQueryFromServerObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    
                if (succeeded) {
         
                    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                 
                        UserFriendList *userFriendList = [UserFriendList MR_findFirstInContext:localContext];
                        userFriendList.updatedAt = [NSDate date];
                        
                    } completion:^(BOOL success, NSError *error) {
        
                        if (success) {
             
                            NSLog(@"Success Saved and Pinned:queryPhonenumberUsersInServer" );
                            
                            // Updating again if new friends are in the musicbar
                            [self sortFriendsWhoExistsOnIllist];
                            [self.refreshButton setEnabled:YES];
                            [SVProgressHUD dismiss];
                            
                        } else {
                            NSLog(@"Error:%@ : queryPhonenumberUsersInServer", error);

                        }
                        
                    }];

                    
                } else {
                    NSLog(@"Error: %@ queryPhonenumberUsersInServer", error);
                }
                
            }]; // end friendListQueryFromServerObject saveInBackgroundWithBlock
            
        } else {
            NSLog(@"Error: queryPhonenumberUsersInServer, %@", error);
        }
        
    }]; // end friendListQueryFromServer getFirstObjectInBackgroundWithBlock
}

- (NSString *) cleanPhonenumberStrings :(NSString *)phonenumberInPrivateData {
    NSString *phonenumberString = [[NSString alloc] initWithString:phonenumberInPrivateData];
    phonenumberString = [[phonenumberString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    phonenumberString = [phonenumberString stringByReplacingOccurrencesOfString:@"(" withString:@""];
    phonenumberString = [phonenumberString stringByReplacingOccurrencesOfString:@")" withString:@""];
    phonenumberString = [phonenumberString stringByReplacingOccurrencesOfString:@"+" withString:@""];
    phonenumberString = [phonenumberString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    phonenumberString = [phonenumberString stringByReplacingOccurrencesOfString:@"/" withString:@""];
    
    // Check if the phone number is 11 digits USA
    if (phonenumberString.length == 11) {
        
        if ([[phonenumberString substringToIndex:1] isEqualToString: @"1"]) {
            // Take out the first string
            phonenumberString = [phonenumberString substringFromIndex:1];
        }
        
    }
    return phonenumberString;
    
    
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
        
    }

        return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0 ) {
        return @"Friends on MusicBar";
    }
    return @"Contacts";
}

#pragma mark - SynchronizeContacts and Save to server

- (void) synchronizeContacts {

    RHAddressBook *addressBook = [[RHAddressBook alloc] init];
    [addressBook requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
        
//
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
            ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted ) {
            
            NSLog(@"Denied");
            
        } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
    
            NSArray *allContacts = [addressBook peopleOrderedByFirstName] ;
            NSMutableDictionary *contactDictionary = [[NSMutableDictionary alloc] init];
            NSMutableArray *friendToSave = [[NSMutableArray alloc] init];
            
            NSMutableDictionary *contactLinkedDictionary = [[NSMutableDictionary alloc] init];
            PFACL *acl = [PFACL ACL];
            [acl setReadAccess:YES forUser:[PFUser currentUser]];
            [acl setWriteAccess:YES forUser:[PFUser currentUser]];
            
        
            for (RHPerson *person in allContacts) {
                
                /* Since the RHAddressbook can extract a duplicate of contact's info from the addressbook
                 * the contactDictionary will make sure that contact with a phone number and name
                 * will be extracted only one time
                 *
                 */
                if (![contactDictionary objectForKey:person.name]) {
                    
                    // The contactLinkedDictionary will make sure that linked users are only extracted once as well
                    if( ![contactLinkedDictionary objectForKey:[person linkedPeople]]) {
                        
                        // Syncing contacts in the addressbook whose phone number is avaliable
                        if ([[person phoneNumbers] values] != nil) {
                            
                            
                            PFObject *friend = [PFObject objectWithClassName:@"Friend"];
                            
                            // Setting ACL. Only the current user can view the Friend PFObject
                            friend.ACL = acl;

                            friend[@"host"] = [[PFUser currentUser] objectId];

                            friend[@"phone_number"] = [[person phoneNumbers] values];
                           
                            friend[@"friend_exists"] = @(NO);
                          
                            if ([person name] != nil) {
                                friend[@"name"] = person.name;
                                
                            } else {
                                friend[@"name"] = [NSNull null];
                            }
                            
                            if ([person firstName] != nil) {
                                friend[@"first_name"] = person.firstName;
                                
                            } else {
                                friend[@"first_name"] = [NSNull null];
                            }
                            if ([person lastName] != nil) {
                                friend[@"last_name"] = person.lastName;
                            } else {
                                friend[@"last_name"] = [NSNull null];
                            }
                            if ([[person emails] values] != nil) {
                                friend[@"emails"] = [[person emails] values];
                                
                            } else {
                                friend[@"emails"] = [NSNull null];
                            }
                            
                            [friendToSave addObject:friend];

                        }
                        
                    }
                    [contactLinkedDictionary setObject:@"" forKey:[person linkedPeople]];
                    
                }
                if ([person name] != nil) {
                    [contactDictionary setObject:@"" forKey:person.name];
                }
                
            } // end person in allContacts

            // Saving contacts from phone to server
            
            [PFObject saveAllInBackground:friendToSave block:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    
                    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                        
                        CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:localContext];
                        
                        UserFriendList *currentUserFriendList = [UserFriendList MR_findFirstInContext:localContext];
                        
                        for (PFObject *friend in friendToSave) {
                            
                            Friend *friendInLocal = [Friend MR_createEntityInContext:localContext];
                            friendInLocal.hostId = friend[@"host"];
                            friendInLocal.objectId = friend.objectId;
                            
                            NSArray *friendPhoneNumberList = friend[@"phone_number"];
                            
                            for (int i = 0; i < friendPhoneNumberList.count; i++ ) {
                                
                                FriendPhonenumber *phoneNumberInCoreData = [FriendPhonenumber MR_createEntityInContext:localContext];
                                phoneNumberInCoreData.phonenumber = [friendPhoneNumberList objectAtIndex:i];
                                
                                [friendInLocal addFriendPhonenumberObject:phoneNumberInCoreData];
                                
                            }
                            
                            friendInLocal.friend_exists = friend[@"friend_exists"];
                            friendInLocal.name = friend[@"name"];
                            [currentUserFriendList addFriendObject:friendInLocal];
                        }
                        
                        // saving updated date for userfriendlist
                        currentUserFriendList.updatedAt = [NSDate date];
                        
                        // Finding current User in coredata and updating with the userfriendlist in coredata
                        currentUser.userFriendList = currentUserFriendList;
                        
                    } completion:^(BOOL success, NSError *error) {
                    
                        if (success) {
                            CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:defaultContext];
                            
                            // Friends added into server and local database
                            NSLog(@"Completed syncing contacts");
                            friendsList = [[NSMutableArray alloc] initWithArray:[currentUser.userFriendList.friend allObjects]];
                           
                            [self updateUserFriendList];
                            
                        } else {
                            
                            NSLog( @"Error: sync %@", error);
                            
                        }
                        
                    }]; // end save
                    

                }
            }];
       
        }

            
    }]; // end addressBook requestAuthorizationWithCompletion
    

    
}

- (void) updateUserFriendList {

    
    // Saving UserFriendList to local storage and to the server as well
    PFQuery *friendListQueryFromServer = [PFQuery queryWithClassName:@"UserFriendList"];
    
    [friendListQueryFromServer whereKey:@"host" equalTo:[[PFUser currentUser] objectId]];
    
    [friendListQueryFromServer getFirstObjectInBackgroundWithBlock:^(PFObject *friendListQueryFromServerObject, NSError *error) {
   
        if (!error) {

//            NSNumber *friendListCount = [NSNumber numberWithLong:friendsList.count];
//            [friendListQueryFromServerObject setObject:friendListCount forKey:@"UserFriendListArrayCount"];
            
            
            [friendListQueryFromServerObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                if (succeeded) {

                    
                    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                        
                        UserFriendList *userFriendList = [UserFriendList MR_findFirstInContext:localContext];
                        userFriendList.updatedAt = [NSDate date];
                        
                    } completion:^(BOOL success, NSError *error) {
                        
                        if (success) {
                    
                            [self cleanPhonenumberStrings];

                        } else {
                            NSLog(@"Error: updateUserFriendList %@", error);
                        }
                        
                    }];
                
                    
                } else {
                    NSLog(@" Error: updateUserFriendList");
                }
                
            }]; // end friendListQueryFromServerObject saveInBackgroundWithBlock
            
        } else {
            NSLog(@"Error: updateUserFriendList, %@", error);
        }
    
    
    }];
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
    
    NSString *text = @"To add friends, search your friends on the explore tab";
    
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
     
     if ([segue.identifier isEqualToString:@"friendSegue"]) {
         
         // Get destination view
         iLLFriendTabTheirCollectionViewController *controller = (iLLFriendTabTheirCollectionViewController*)segue.destinationViewController;
         
         // Initializing indexpath for the friend cell
         NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
         Friend *selectedFriend =[friendsWhoExistsOniLList objectAtIndex:selectedIndexPath.row];

         controller.friendInfo = selectedFriend;
         
        
     }
 }

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0 ) {
        // Only segue to FriendsDetailTVC if user exists on iLList server (friendsWhoExistsOniLList array)
        [self performSegueWithIdentifier:@"friendSegue" sender:nil];
    }
    
}




@end
