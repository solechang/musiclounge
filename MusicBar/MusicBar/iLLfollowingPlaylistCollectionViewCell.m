//
//  iLLfollowingPlaylistCollectionViewCell.m
//  iLList
//
//  Created by Ik Song on 3/6/15.
//  Copyright (c) 2015 iLList. All rights reserved.
//

#import "iLLfollowingPlaylistCollectionViewCell.h"

@interface iLLfollowingPlaylistCollectionViewCell ()

@property (nonatomic,readwrite) UILabel *labelPlaylistTitle;
@property (nonatomic,readwrite) UILabel *labelPlaylistCreator;


@end

@implementation iLLfollowingPlaylistCollectionViewCell


CGPoint _originalCenter;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code

        UIView *cellView = [[UIView alloc] initWithFrame:frame];
//        cellView.layer.borderWidth = borderWidth;
        cellView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.backgroundView = cellView;
        
        [self setLabelPlaylistTitle:[UILabel new]];
        
        [_labelPlaylistTitle setTextColor:[UIColor blueColor]];
        [_labelPlaylistTitle setBackgroundColor:[UIColor clearColor]];
        [_labelPlaylistTitle  setFont:[UIFont fontWithName: @"Euphemia UCAS" size: 14.0f]];
        [[self labelPlaylistTitle] setFrame:CGRectMake(55.f, 5.f, 257.f, 21.f)];
        
        [[self labelPlaylistTitle] setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [[self contentView] addSubview:[self labelPlaylistTitle]];
        
        [self setLabelPlaylistCreator:[UILabel new]];
        [_labelPlaylistCreator setTextColor:[UIColor blueColor]];
        [_labelPlaylistCreator setBackgroundColor:[UIColor clearColor]];
        [_labelPlaylistCreator  setFont:[UIFont fontWithName: @"Euphemia UCAS" size: 14.0f]];
        [[self labelPlaylistCreator] setFrame:CGRectMake(55.f, 25.f, 257.f, 21.f)];
        
        [[self labelPlaylistCreator] setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [[self contentView] addSubview:[self labelPlaylistCreator]];
    
    }
    
    return self;
}



@end
