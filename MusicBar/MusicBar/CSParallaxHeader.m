//
//  CSParallaxHeader.m
//  iLList
//
//  Created by Ik Song on 2/5/15.
//  Copyright (c) 2015 iLList. All rights reserved.
//

#import "CSParallaxHeader.h"
#import "CSStickyHeaderFlowLayoutAttributes.h"

@interface CSParallaxHeader()

@property (nonatomic, strong) NSArray *menuItems;


@end


@implementation CSParallaxHeader

- (void)awakeFromNib{

    // Initialization code
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.mainView.bounds;
    
    UIColor *topColor = [UIColor colorWithRed:(49/255.0) green:(17/255.0) blue:(65/255.0) alpha:0] ;
    UIColor *bottomColor = [UIColor colorWithRed:(75/255.0) green:(31/255.0) blue:(83/255.0) alpha:1] ;

    gradient.colors = [NSArray arrayWithObjects:(id)[topColor CGColor], (id)[bottomColor CGColor], nil];
    [self.mainView.layer insertSublayer:gradient atIndex:0];
    
//    [self.editProfileButton setTitle:@"Edit Profile" forState:UIControlStateNormal];
//    self.editProfileButton.layer.cornerRadius = 10.0;
//    [[self.editProfileButton layer] setBorderWidth:2.0f];
//    [[self.editProfileButton layer] setBorderColor:[UIColor whiteColor].CGColor];
//    
//    [self.addNewPlaylistButton setTitle:@"New Lounge" forState:UIControlStateNormal];
//    self.addNewPlaylistButton.layer.cornerRadius = 10.0;
//    [[self.addNewPlaylistButton layer] setBorderWidth:2.0f];
//    [[self.addNewPlaylistButton layer] setBorderColor:[UIColor whiteColor].CGColor];
    
    [[self.profileImage layer] setBorderWidth:2.0f];
    [[self.profileImage layer] setBorderColor:[UIColor whiteColor].CGColor];
    self.profileImage.layer.masksToBounds = YES;
    self.profileImage.layer.cornerRadius = self.profileImage.frame.size.height /2;

}



@end
