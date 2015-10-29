//
//  iLLSignUpTableViewController.m
//  iLList
//
//  Created by Jake Choi on 11/5/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import "SignUpTableViewController.h"

#import <SVProgressHUD/SVProgressHUD.h>

#import <QuartzCore/QuartzCore.h>

// Core Data
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"
#import "UserFriendList.h"
#import "NowPlaying.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>


@interface SignUpTableViewController () {
    BOOL phoneFlag;
}

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@end

@implementation SignUpTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Makes the unused cells on tableview disappear
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    [self setUpViewController];
    
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;

    phoneFlag = NO;
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

    self.tableView.backgroundColor = [UIColor colorWithRed:(230/255.0) green:(230/255.0) blue:(230/255.0) alpha:1] ;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithRed:(230/255.0) green:(230/255.0) blue:(230/255.0) alpha:1];
    
    
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{

    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [textField resignFirstResponder];
        [self doneButton:self];
    }
    
    return YES;
}

- (IBAction)doneButton:(id)sender {
    
    [self.doneButton setEnabled:NO];
    [self setEmailTextFieldGreen];

    if ( [self.passwordTextField.text isEqualToString:@""] ||
        [self.emailTextField.text isEqualToString:@""] ) {
        
        [self.doneButton setEnabled:YES];
        
            // Display error
            [SVProgressHUD showErrorWithStatus:@"Please enter all of the fields"];

//        if (!phoneFlag) {
//            [SVProgressHUD showErrorWithStatus:@"Your phone number is invalid. Please try again"];
//        }
        
    } else {
        
        // Find if username is in use or not.
        PFQuery *query = [PFUser query];
        
        [query whereKey:@"name" equalTo:self.usernameTextField.text];
        
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *foundUsername, NSError *error) {
            
            if( !foundUsername ) {
                [self setUsernameFieldGreen];
                [self setUpSignUpUser];
                
            } else {
                [self setUsernameTextFieldRed];
                [SVProgressHUD showErrorWithStatus:@"Please use another username."];

            }
        }];
        
        

        
        
    }// end else

}

- (void) setUpSignUpUser {
    
    // Setting sign up User
    PFUser *user = [PFUser user];
    user[@"name"] = self.usernameTextField.text;
    user.username = self.emailTextField.text;
    user.email = self.emailTextField.text;
    user.password = self.passwordTextField.text;
    
    // Setting privacy for the PrivateUserData PFObject
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    // Setting User ACL
    user.ACL = defaultACL;
    
    
    NSMutableDictionary *phonenumberDictionary = [NSMutableDictionary new];
    [phonenumberDictionary setObject:self.phonenumberTextField.text forKey:@"phone_number" ];
    
    [PFCloud callFunctionInBackground:@"checkPhonenumber" withParameters:phonenumberDictionary
                                block:^(NSString *result, NSError *error) {
                                    
                                    if (!error ) {
                                        // Need to change PFCloud if more than 1000 users register
                                        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                            
                                            if (!error) {
                                                [self createUserData :user];
                                                
                                                
                                            } else {
                                                
                                                NSString *errorString = [error userInfo][@"error"];
//                                                NSLog(@"ERROR: %@", errorString);
                                                
                                                if ([errorString containsString:@"invalid email"]) {
                                                    [SVProgressHUD showErrorWithStatus:@"Please use another email"];
                                                    [self setEmailTextFieldRed];
                                                    
                                                    
                                                }
                                                if ( [errorString containsString:@"username"] ){
                                                    [SVProgressHUD showErrorWithStatus:@"Please use another email"];
                                                    [self setEmailTextFieldRed];
                                                    
                                                }
                                                
                                                [self.doneButton setEnabled:YES];
                                            }
                                            
                                        }];
                                        
                                    } else {
                                        [SVProgressHUD showErrorWithStatus:@"Please use another phone number"];
                                        
                                    }
//                                    NSLog(@"%@", result);
                                }];

}


-(void) createUserData :(PFUser*)user{
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setReadAccess:YES forUser:[PFUser currentUser]];
    [defaultACL setWriteAccess:NO forUser:[PFUser currentUser]];
      
    //Creating UserFriendList PFObject and setting ACL
    PFObject *userFriendList = [PFObject objectWithClassName:@"UserFriendList"];
    [userFriendList setObject:[[PFUser currentUser] objectId] forKey:@"host"];
    userFriendList.ACL = defaultACL;
    
    // PFObject PrivateUserData
//    PFObject *privateData = [PFObject objectWithClassName:@"PrivateUserData"];
    
    // When user signs up, their phone number has to be only numbers and US phone number. Need to include for international
//    [privateData setObject:self.phonenumberTextField.text forKey:@"phone_number"];
//    [privateData setObject:[[PFUser currentUser] objectId] forKey:@"host"];
    
//    privateData.ACL = defaultACL;
    
    NSMutableArray *userData = [[NSMutableArray alloc] init];
//    [userData addObject:userIllists];
    [userData addObject:userFriendList];
//    [userData addObject:privateData];
    
    // Save data in parse
    [PFObject saveAllInBackground:userData block:^(BOOL succeeded, NSError *error) {
        
        if(succeeded) {
     
            // Save data in local
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {

                CurrentUser *currentUser = [CurrentUser MR_createEntityInContext:localContext];

                UserFriendList *currentUserFriendList = [UserFriendList MR_createEntityInContext:localContext];
                
                NowPlaying *nowPlaying = [NowPlaying MR_createEntityInContext:localContext];
                // @"1" = Nothing is played
                nowPlaying.playlistId = @"";
                
                currentUser.userId = user.objectId;
                // saving user's name, phone number, and email onto core data
                currentUser.name = [self.usernameTextField.text lowercaseString];
                currentUser.email = self.emailTextField.text;
                
                // setting data for current user illist and friend list onto core data
                currentUserFriendList.hostId = [[PFUser currentUser] objectId];
                currentUserFriendList.objectId = userFriendList.objectId;
                
                currentUser.userFriendList = currentUserFriendList;
                
            } completion:^(BOOL success, NSError *error) {
                
                [self.navigationController dismissViewControllerAnimated:YES completion:^{
                  
                   
            
                    [self.doneButton setEnabled:YES];
                    [SVProgressHUD showSuccessWithStatus:@"Welcome to MusicLounge!"];
                    
                }];
                
            }];

        } else {
//            NSLog(@"Error in saving: createUserData %@", error);
        }
    }];
}



- (void) setEmailTextFieldRed {
    self.emailTextField.layer.cornerRadius=1.0f;
    self.emailTextField.layer.masksToBounds=YES;
    self.emailTextField.layer.borderColor=[[UIColor redColor]CGColor];
    self.emailTextField.layer.borderWidth= 1.0f;

}

- (void) setEmailTextFieldGreen {
    self.emailTextField.layer.borderColor=[[UIColor greenColor]CGColor];
}

#pragma mark - Private methods
- (NSString *) decodeUnicodeCharacters: (NSString*)name {
    if (name) {
        NSString * encodedString = name;
        NSString *decodedString = [NSString stringWithUTF8String:[encodedString cStringUsingEncoding:[NSString defaultCStringEncoding]]];
//        NSString *correctString = [NSString stringWithCString:[utf8String cStringUsingEncoding:NSISOLatin1StringEncoding] encoding:NSUTF8StringEncoding];
        

        return decodedString;
    }
    
    return nil;
}


@end
