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


    } else {
        
        [self signUpUser];
    
    }// end else

}

- (void) signUpUser {
    PFUser *user = [PFUser user];
    
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    // Setting User ACL
    user.ACL = defaultACL;
    user.username = self.emailTextField.text;
    user.email = self.emailTextField.text;
    user.password = self.passwordTextField.text;
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error) {
            [self performSegueWithIdentifier:@"usernameSegue" sender:self];
            
        } else {

            NSString *errorString = [error userInfo][@"error"];
            // NSLog(@"ERROR: %@", errorString);

            if ([errorString containsString:@"invalid email"]) {
                [SVProgressHUD showErrorWithStatus:@"Please use another email"];
                [self setEmailTextFieldRed];


            }

            
        }
        [self.doneButton setEnabled:YES];
        
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
