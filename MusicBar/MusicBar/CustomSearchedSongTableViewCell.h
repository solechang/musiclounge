//
//  iLLCustomSearchedSongTableViewCell.h
//  iLList
//
//  Created by Jake Choi on 12/9/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomSearchedSongTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *albumImage;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadingUserLabel;

@property (weak, nonatomic) IBOutlet UILabel *addedByLabel;

@end
