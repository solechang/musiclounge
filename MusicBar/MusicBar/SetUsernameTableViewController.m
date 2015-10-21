//
//  SetUsernameTableViewController.m
//  MusicBar
//
//  Created by Jake Choi on 8/19/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import "SetUsernameTableViewController.h"

#import <SVProgressHUD/SVProgressHUD.h>

#import <QuartzCore/QuartzCore.h>

// Core Data
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"
#import "UserFriendList.h"
#import "NowPlaying.h"

#import <Parse/Parse.h>

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface SetUsernameTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@end

@implementation SetUsernameTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Makes the unused cells on tableview disappear
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    
    self.navigationItem.hidesBackButton = YES;
    
    [self setUpViewController];

    self.usernameTextField.delegate = self;
    [self.usernameTextField becomeFirstResponder];



}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)setUpViewController{
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:(49/255.0) green:(17/255.0f) blue:(65/255.0f) alpha:1];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.tableView.backgroundColor = [UIColor colorWithRed:(230/255.0) green:(230/255.0) blue:(230/255.0) alpha:1] ;
    
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithRed:(230/255.0) green:(230/255.0) blue:(230/255.0) alpha:1];
    
    
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameTextField) {
        NSString* username = [self.usernameTextField.text lowercaseString];
        self.usernameTextField.text = username;
        [self doneButtonPressed:self];
        [textField resignFirstResponder];
        
    }
    
    return YES;
}

- (BOOL)nameExpecations {
    // Having textfield delgates and checking on spot if fields are valid
    if([self.usernameTextField.text containsString:@" "]){
        return YES;
    }
    else {
        return NO;
    }
    
    
    
}
- (IBAction)doneButtonPressed:(id)sender {
    [self.doneButton setEnabled:NO];
    
    if ([self.usernameTextField.text isEqualToString:@""]) {
        [self.doneButton setEnabled:YES];
        if ([self nameExpecations]) {
            
            // Display error
            [SVProgressHUD showErrorWithStatus:@"Your name has to be one word. Please try again"];
            
            return;
        } else {
            
            // Display error
            [SVProgressHUD showErrorWithStatus:@"Please enter your name"];
            
            return;
        }
    } else {
        
        [self checkIllegalCharactersForUsername];
        
        
        
    }// end else

}

- (void) checkIllegalCharactersForUsername {
    
    NSString *myRegex = @"[A-Z0-9a-z_-]*";
    NSPredicate *myTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", myRegex];
    NSString *string = [self.usernameTextField.text lowercaseString];
    BOOL valid = [myTest evaluateWithObject:string];
    
    
    if (valid) {
        // Check if username is valid use or not.
        PFQuery *query = [PFUser query];
        
        [query whereKey:@"name" equalTo:string];
        
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *foundUsername, NSError *error) {
            
            if( !foundUsername ) {
                [self setUsernameFieldGreen];
                [self setUpSignUpUserName];
                
            } else {
                [self setUsernameTextFieldRed];
                [SVProgressHUD showErrorWithStatus:@"Please use another username."];
                [self.doneButton setEnabled:YES];
                
            }
        }];

        
        
    } else {
        [self.doneButton setEnabled:YES];
        [self setUsernameTextFieldRed];
        [SVProgressHUD showErrorWithStatus:@"Your username can only contain alphabetic, numeric, '-', and '_' characters."];
    }
    
}

- (void) setUsernameTextFieldRed {
    self.usernameTextField.layer.cornerRadius=1.0f;
    self.usernameTextField.layer.masksToBounds=YES;
    self.usernameTextField.layer.borderColor=[[UIColor redColor]CGColor];
    self.usernameTextField.layer.borderWidth= 1.0f;
    
}
- (void) setUsernameFieldGreen {
    self.usernameTextField.layer.borderColor=[[UIColor greenColor]CGColor];
}

- (void)setUpSignUpUserName {
    
    PFUser *user = [PFUser currentUser];
    NSString *username =[self.usernameTextField.text lowercaseString];
    user[@"name"] = username;
    user[@"updateCheck"] = @(YES);
    
    // Setting privacy for the PrivateUserData PFObject
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
       
        if (!error) {
            
            [self createUserData:user];
        } else {
//            NSLog(@"184.) %@",error);
            [self.doneButton setEnabled:YES];
            [SVProgressHUD dismiss];
        }
        
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
//    [privateData setObject:[[PFUser currentUser] objectId] forKey:@"host"];
    
//    privateData.ACL = defaultACL;
    
    NSMutableArray *userData = [[NSMutableArray alloc] init];
    //    [userData addObject:userIllists];
    [userData addObject:userFriendList];
//    [userData addObject:privateData];
    
    // Save data in parse
    [PFObject saveAllInBackground:userData block:^(BOOL succeeded, NSError *error) {
        
        if(!error) {
            
            // Save data in local
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                
                CurrentUser *currentUser = [CurrentUser MR_createEntityInContext:localContext];
                
                UserFriendList *currentUserFriendList = [UserFriendList MR_createEntityInContext:localContext];
                
                NowPlaying *nowPlaying = [NowPlaying MR_createEntityInContext:localContext];
                // @"1" = Nothing is played
                nowPlaying.playlistId = @"";
                
                currentUser.userId = user.objectId;
                
                NSString *username =[self.usernameTextField.text lowercaseString];
                
                // saving user's name, phone number, and email onto core data
                currentUser.name = username;

                // setting data for current user illist and friend list onto core data
                currentUserFriendList.hostId = [[PFUser currentUser] objectId];
                currentUserFriendList.objectId = userFriendList.objectId;
                
                currentUser.userFriendList = currentUserFriendList;
                
            } completion:^(BOOL success, NSError *error) {
                
                if (!error) {
                    [self.navigationController dismissViewControllerAnimated:YES completion:^{
                        
                        PFUser *currentUser = [PFUser currentUser];
                        [Answers logSignUpWithMethod:@"MusicLounge"
                                             success:@YES
                                    customAttributes:@{@"username": currentUser[@"name"],
                                                       @"userId" :currentUser.objectId
                                                       
                                                       }];
                        
                        [self.doneButton setEnabled:YES];
                        [SVProgressHUD showSuccessWithStatus:@"Welcome to MusicLounge!"];
                        
                    }];
                } else {
                    [self.doneButton setEnabled:YES];
                    [SVProgressHUD showErrorWithStatus:@"Please try again. The username could not be set"];
                    
                }
                
               
                
            }];
            
        } else {
            [self.doneButton setEnabled:YES];
            [SVProgressHUD dismiss];
//            NSLog(@"Error in saving: createUserData %@", error);
        }
    }];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
