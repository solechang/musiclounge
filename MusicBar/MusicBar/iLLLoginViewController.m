//
//  iLLLoginViewController.m
//  iLList
//
//  Created by Ik Song on 4/1/15.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import "iLLLoginViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>

// Core Data
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "CurrentUser.h"
#import "UserFriendList.h"
#import "NowPlaying.h"

#import <QuartzCore/QuartzCore.h>

@interface iLLLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIView *subView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation iLLLoginViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    
    [self gradientSetting];
    
    self.subView.layer.cornerRadius = 10;
    self.subView.layer.masksToBounds = YES;
    
    [self.titleLabel setFont:[UIFont fontWithName:@"Wisdom Script" size:40.0]];
    self.titleLabel.text = @"MusicBar";
    
    
    self.loginButton.layer.cornerRadius = 10;
    self.loginButton.clipsToBounds = YES;
    
    self.signUpButton.layer.cornerRadius = 10;
    self.signUpButton.clipsToBounds = YES;
    
    
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    self.tabBarController.tabBar.hidden = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
}

-(void)gradientSetting {
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.mainView.bounds;
    
    UIColor *topColor = [UIColor colorWithRed:(49/255.0) green:(17/255.0) blue:(65/255.0) alpha:0] ;
    UIColor *bottomColor = [UIColor colorWithRed:(75/255.0) green:(31/255.0) blue:(83/255.0) alpha:1] ;
    
    gradient.colors = [NSArray arrayWithObjects:(id)[topColor CGColor], (id)[bottomColor CGColor], nil];
    [self.mainView.layer insertSublayer:gradient atIndex:0];

    
}

- (void)viewWillAppear:(BOOL)animated {
    
    //IK - hide navigation bar when view is open
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    //IK - unhide navigation bar in other views
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

-(void)dismissKeyboard {
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [textField resignFirstResponder];
        [self loginButton:self];
    }
    
    return YES;
}

- (IBAction)loginButton:(id)sender {
    
    if ([self.emailTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""] ) {
        
        // Display error
        [SVProgressHUD showErrorWithStatus:@"Please enter all the fields"];
        
    } else {
        
        [PFUser logInWithUsernameInBackground:self.emailTextField.text password:self.passwordTextField.text
                                        block:^(PFUser *user, NSError *error) {
                                            if (user) {
                                                // Do stuff after successful login.
                                                
                                                
                                                // Delete local current user first
                                                NSArray *deleteCurrentUserArray = [CurrentUser MR_findAll];
                                                
                                                for ( CurrentUser *deleteCurrentUser in deleteCurrentUserArray ) {
                                                    [deleteCurrentUser.userFriendList MR_deleteEntity];
//                                                    [deleteCurrentUser.userIllist MR_deleteEntity];
                                                    [deleteCurrentUser MR_deleteEntity];
                                                }
                                                
                                                
                                                // Save data in local
                                                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                                                    
                                                    // Creating User contents in core data
                                                    CurrentUser *currentUser = [CurrentUser MR_createInContext:localContext];
//
                                                    UserFriendList *currentUserFriendList = [UserFriendList MR_createInContext:localContext];
                                                    
                                                    NowPlaying *nowPlaying = [NowPlaying MR_createInContext:localContext];
                                                    // @"1" = Nothing is played
                                                    nowPlaying.playlistId = @"";
                                                    
                                                    // saving user's name, phone number, and email onto core data
                                                    currentUser.name = user[@"name"];
                                                    currentUser.userId = [[PFUser currentUser] objectId];
                                                    currentUser.email = user.email;
                                                    
                                                    
                                                    // setting data for current user illist and friend list onto core data
                                                    currentUserFriendList.hostId = [[PFUser currentUser] objectId];
                                                    
                                                    currentUser.userFriendList = currentUserFriendList;
                                                    
                                                    
                                                } completion:^(BOOL success, NSError *error) {
                                                    
                                                    [self.navigationController dismissViewControllerAnimated:YES completion:^{
                                                        
                                                        // Display success to log in
                                                        [SVProgressHUD showSuccessWithStatus:@"Welcome back to iLList!"];
                                                        
                                                        
                                                    }];
                                                    
                                                }];
                                                
                                            } else {
                                                //The login failed. Check error to see why.
                                                
                                                NSString *errorString = [error userInfo][@"error"];
                                                NSLog(@"ERROR: %@", errorString);
                                                [SVProgressHUD showSuccessWithStatus:errorString];
                                            }
                                        }];
        
    }
    
}

@end
