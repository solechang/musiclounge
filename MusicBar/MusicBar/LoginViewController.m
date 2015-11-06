//
//  iLLLoginViewController.m
//  iLList
//
//  Created by Ik Song on 4/1/15.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import "LoginViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>

// Core Data
// Objective-C
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"
#import "UserFriendList.h"
#import "NowPlaying.h"

#import <QuartzCore/QuartzCore.h>

#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface LoginViewController () {
      NSManagedObjectContext *defaultContext;
}
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIView *subView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIButton *facebookLoginButton;

@end

@implementation LoginViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setNSManagedObjectContext];
    [self gradientSetting];
    
    self.subView.layer.cornerRadius = 10;
    self.subView.layer.masksToBounds = YES;
    
//    [self.titleLabel setFont:[UIFont fontWithName:@"Wisdom Script" size:44.0]];
//    self.titleLabel.text = @"MusicLounge";
    

    self.loginButton.layer.cornerRadius = 10;
    self.loginButton.clipsToBounds = YES;
    
    self.signUpButton.layer.cornerRadius = 10;
    self.signUpButton.clipsToBounds = YES;
    
    self.facebookLoginButton.layer.cornerRadius = 10;
    self.facebookLoginButton.clipsToBounds = YES;
    
    
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    self.tabBarController.tabBar.hidden = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
   
    
}
- (void) setNSManagedObjectContext {
    
    defaultContext = [NSManagedObjectContext MR_defaultContext];
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
- (IBAction)faceBookLogin:(id)sender {
    [self.facebookLoginButton setEnabled:NO];
    NSArray *permissionsArray = @[ @"user_about_me", @"user_friends", @"read_custom_friendlists"];
    
    [SVProgressHUD showWithStatus:@"Loading \xF0\x9F\x98\x84"];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:@"You have canceled Facebook login :("];
//            NSLog(@"1.1.) Uh oh. The user cancelled the Facebook login.");
        } else {
            
//            NSLog(@"1.3.) %@", user);
            
            if (user[@"name"] != nil) {
                
                [self setUpCurrentUser: user :YES];
                
            } else {
                
                [self setFacebookID:user];
//                [self performSegueWithIdentifier:@"usernameSegue" sender:self];
                
            }
            
        }
        
        [self.facebookLoginButton setEnabled:YES];
    }];
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

- (void) setUpCurrentUser: (PFUser*)user :(BOOL) faceBookCheck{
    
    // Delete local current user first
    NSArray *deleteCurrentUserArray = [CurrentUser MR_findAllInContext:defaultContext];
    
    for ( CurrentUser *deleteCurrentUser in deleteCurrentUserArray ) {
        [deleteCurrentUser.userFriendList MR_deleteEntityInContext:defaultContext];
        //[deleteCurrentUser.userIllist MR_deleteEntity];
        [deleteCurrentUser MR_deleteEntityInContext:defaultContext];
    }
    
    
    // Save data in local
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        // Creating User contents in core data
        CurrentUser *currentUser = [CurrentUser MR_createEntityInContext:localContext];
        //
        UserFriendList *currentUserFriendList = [UserFriendList MR_createEntityInContext:localContext];
        
        NowPlaying *nowPlaying = [NowPlaying MR_createEntityInContext:localContext];
        // @"1" = Nothing is played
        nowPlaying.playlistId = @"";
        
        // saving user's name, phone number, and email onto core data
        currentUser.name = user[@"name"];
        currentUser.userId = [[PFUser currentUser] objectId];

        
        
        // setting data for current user illist and friend list onto core data
        currentUserFriendList.hostId = [[PFUser currentUser] objectId];
        
        currentUser.userFriendList = currentUserFriendList;
        
        
    } completion:^(BOOL success, NSError *error) {
        
        if (!error) {
            
            // Checking where the login came from. From facebook login or email
            if (faceBookCheck) {
                
                [self setFacebookID:  user];
                
            } else {
                
                [self.navigationController dismissViewControllerAnimated:YES completion:^{
                    
                    
                    [Answers logLoginWithMethod:@"MusicLounge"
                                        success:@YES
                               customAttributes:@{@"username": user[@"name"],
                                                  @"userID" : user.objectId
                                                  
                                                  }];
                    
                    // Display success to log in
                    [SVProgressHUD showSuccessWithStatus:@"Welcome back to MusicLounge!"];
                    
                    
                }];
                [SVProgressHUD dismiss];

                
            }
            
        }
        

    }];

}

- (void) setFacebookID: (PFUser *) user{
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"me"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        // Handle the result

        if (!error) {
            
            
            NSString *facebookID = result[@"id"];
            
            
            if (![facebookID isEqualToString:@""] && result[@"id"]) {
                [self saveUserFacebookID: facebookID :user];
            }
        }

    }];
    
}

- (void) saveUserFacebookID :(NSString*) facebookID : (PFUser *) user{

    user[@"facebookID"] = facebookID;
    user[@"updateCheck"] = @(YES);

    
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    
        if (!error) {
            
            // Checks if the username is set correctly
            if (user.isNew || !user[@"name"]) {
                
                [self performSegueWithIdentifier:@"usernameSegue" sender:self];
                
                
            } else {
         
                [self.navigationController dismissViewControllerAnimated:YES completion:^{
                    
                    PFUser *currentUser = [PFUser currentUser];
                    [Answers logLoginWithMethod:@"MusicLounge"
                                        success:@YES
                               customAttributes:@{@"username": currentUser[@"name"],
                                                  @"userID" : currentUser.objectId
                                                  
                                                  }];
                    
                    // Display success to log in
                    [SVProgressHUD showSuccessWithStatus:@"Welcome back to MusicLounge!"];
                    
                    
                }];
                
            }
            [SVProgressHUD dismiss];
            
        }
        
    }];

    
}

- (IBAction)loginButton:(id)sender {

    if ([self.emailTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""] ) {
        
        // Display error
        [SVProgressHUD showErrorWithStatus:@"Please enter all the fields"];
        
    } else {
        
        [PFUser logInWithUsernameInBackground:self.emailTextField.text password:self.passwordTextField.text
                                        block:^(PFUser *user, NSError *error) {
                                            
                                            if (!error) {
                                                // Do stuff after successful login.
                                                
                                                if (!user[@"name"]) {
                                                    [self performSegueWithIdentifier:@"usernameSegue" sender:self];
                                                } else {
                                                    
                                                    
                                                    [self setUpCurrentUser:user :NO];
                                                }
                                                
                                                
                                            } else {
                                                //The login failed. Check error to see why.
                                                
                                                NSString *errorString = [error userInfo][@"error"];
//                                                NSLog(@"ERROR: %@", errorString);
                                                [SVProgressHUD showErrorWithStatus:errorString];
                                            }
                                        }];
        
    }
    
}

@end
