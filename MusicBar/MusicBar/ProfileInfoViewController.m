//
//  ProfileInfoViewController.m
//  MusicBar
//
//  Created by Anthony Merrin on 8/21/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import "ProfileInfoViewController.h"
#import <Parse/Parse.h>
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"
#import <SVProgressHUD/SVProgressHUD.h>

@implementation ProfileInfoViewController

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)viewDidAppear:(BOOL)animated{
    [self initializeData];
}

-(void)viewWillAppear:(BOOL)animated{
    CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:[NSManagedObjectContext MR_defaultContext]];
//    NSLog(@"%@",currentUser);
    if(currentUser.info.length > 0){
        self.infoTextView.text = currentUser.info;
    } else {
        self.infoTextView.text = @"Press here to edit";
    }
}

-(void)initializeData{
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (IBAction)saveButtonPushed:(id)sender {
    
    PFUser *user = [PFUser currentUser];
    user[@"description"] = self.infoTextView.text;
    
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                CurrentUser *currentUser = [CurrentUser MR_findFirstInContext:localContext];

                currentUser.info = self.infoTextView.text;

                } completion:^(BOOL success, NSError *error) {
                    if(success){
                    
                        [SVProgressHUD showSuccessWithStatus:@"Your description has been updated successfully!"];
                        [self.navigationController dismissViewControllerAnimated:YES completion:^{
                        }];
                    }
                
            }];
        }
    }];
    
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    if([self.infoTextView.text isEqualToString:@"Press here to edit"]){
        self.infoTextView.text = @"";
    }
    return YES;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    
    if(range.length + range.location > self.infoTextView.text.length)
    {
        return NO;
    }
    
    NSUInteger newLength = [self.infoTextView.text length] + [text length] - range.length;
    return newLength <= 180;
}

@end
