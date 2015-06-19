//
//  CSParallaxHeader.h
//  iLList
//
//  Created by Ik Song on 2/5/15.
//  Copyright (c) 2015 iLList. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DZNSegmentedControl.h"



@interface CSParallaxHeader : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *textLabelName;

@property (weak, nonatomic) IBOutlet UIButton *editProfileButton;
@property (weak, nonatomic) IBOutlet UIButton *addNewPlaylistButton;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UIImageView *profileImage;

@property (weak, nonatomic) IBOutlet UILabel *playlistLabel;

@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIView *headerView;

@end
