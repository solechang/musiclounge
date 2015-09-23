//
//  FeedbackViewController.m
//  MusicLounge
//
//  Created by Jake Choi on 9/9/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import "FeedbackViewController.h"
#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface FeedbackViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UITextView *feedbackTextView;

@end

@implementation FeedbackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.feedbackTextView.delegate = self;
    
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    
    [self.tabBarController.tabBar setTintColor:[UIColor whiteColor]];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated {
    
    [self.feedbackTextView becomeFirstResponder];
    
}
- (IBAction)backButtonPressed:(id)sender {
    
    [self.feedbackTextView resignFirstResponder];
        // alert user are you sure do you want go back
    
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"MusicLounge"
                                  message:@"Are you sure you want to cancel this feedback?"
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* noAlert = [UIAlertAction
                         actionWithTitle:@"No"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [self.feedbackTextView becomeFirstResponder];
                             [alert dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    UIAlertAction* yesAlert = [UIAlertAction
                             actionWithTitle:@"Yes"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [self.navigationController dismissViewControllerAnimated:YES completion:^{
                                     
                                 }];

                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    [alert addAction:noAlert];
    [alert addAction:yesAlert];
    
    [self presentViewController:alert animated:YES completion:nil];
    
   
    
}


- (IBAction)sendButtonPressed:(id)sender {
    if (self.feedbackTextView.text.length > 4) {
           [self sendFeedback];
        
        
    } else {
        
        
        [SVProgressHUD showErrorWithStatus:@"Please enter more than 5 characters"];
    }
 
}

- (void) feedbackAnswersEvent {
    
    [Answers logCustomEventWithName:@"FeedbackEvent"
                   customAttributes:@{
                                      @"userId" : [PFUser currentUser].objectId
                                      
                                      }];
    
    
}
- (void) sendFeedback {
    
    [self feedbackAnswersEvent];
    
    self.sendButton.enabled = NO;
    self.backButton.enabled = NO;
    [self.feedbackTextView resignFirstResponder];
    
    PFObject *feedback = [PFObject objectWithClassName:@"Feedback"];
    feedback[@"description"] = self.feedbackTextView.text;
    feedback[@"userId"] = [PFUser currentUser].objectId;

    PFACL *defaultACL = [PFACL ACL];
    
    [defaultACL setReadAccess:YES forUser:[PFUser currentUser]];
    
    [defaultACL setWriteAccess:YES forUser:[PFUser currentUser]];
    
    feedback.ACL = defaultACL;
    
    [feedback saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error) {
            
            [SVProgressHUD showSuccessWithStatus:@"Thank you for your feedback :)"];
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                self.sendButton.enabled = YES;
                self.backButton.enabled = YES;
                
            }];
            
        } else {
            // Show error
            NSString *errorString = [[NSString alloc] initWithFormat:@"%@", error.localizedDescription];
            [SVProgressHUD showErrorWithStatus:errorString];
            
            self.sendButton.enabled = YES;
            self.backButton.enabled = YES;
        }
        
    }];
    

}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
