//
//  iLLCustomSearchedSongTableViewCell.m
//  iLList
//
//  Created by Jake Choi on 12/9/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import "iLLCustomSearchedSongTableViewCell.h"

@implementation iLLCustomSearchedSongTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];
    self.albumImage.frame = CGRectMake(15,10,67,67);
    float limgW =  self.imageView.image.size.width;
    if(limgW > 0) {
        self.textLabel.frame = CGRectMake(55,self.textLabel.frame.origin.y,self.textLabel.frame.size.width,self.textLabel.frame.size.height);
        self.detailTextLabel.frame = CGRectMake(55,self.detailTextLabel.frame.origin.y,self.detailTextLabel.frame.size.width,self.detailTextLabel.frame.size.height);
    }
}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
