//
//  ProfileInfoViewController.h
//  MusicBar
//
//  Created by Anthony Merrin on 8/21/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileInfoViewController : UIViewController <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;
@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;

@end
