//
//  FeedbackViewController.m
//  MusicLounge
//
//  Created by Jake Choi on 9/9/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import "FeedbackViewController.h"

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
    
    if ( self.feedbackTextView.text > 0 ) {
        
        // alert user are you sure do you want go back
        UIAlertView *backAlert = [[UIAlertView alloc]
                                    initWithTitle:@"MusicLounge?"
                                    message:@"Are you sure you want to cancel this feedback submission?"
                                    delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [backAlert show];
    }
    
}


- (IBAction)sendButtonPressed:(id)sender {
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
 
    if (buttonIndex == 1) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [self.feedbackTextView resignFirstResponder];
        }];
    }
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
