//
//  MyPlaylistCollectionViewCell.m
//  MusicBar
//
//  Created by Jake Choi on 6/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import "MyPlaylistCollectionViewCell.h"


@interface MyPlaylistCollectionViewCell () 

@end

const float UI_CUES_MARGIN = 0.0f;
//const float UI_CUES_WIDTH = [self superView].bounds.size.width;

@implementation MyPlaylistCollectionViewCell

-(id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
//         Initialization code
        self.playlistNameLabel = [[UILabel alloc] init];
        
        [self.playlistNameLabel setFrame:CGRectMake(40.0f, 20.0f, 257.0f, 21.0f)];
        [self.playlistNameLabel setTextColor:[UIColor colorWithRed:49.0/255.0 green:17.0/255.0 blue:65.0/255.0 alpha:1.0]];
        [self.playlistNameLabel setBackgroundColor:[UIColor clearColor]];
        [self.playlistNameLabel  setFont:[UIFont fontWithName: @"Helvetica" size: 12.0f]];
        [self.playlistNameLabel setTextAlignment:NSTextAlignmentLeft];
 //       [self.playlistNameLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.playlistNameLabel setTranslatesAutoresizingMaskIntoConstraints:false];
    
//         self.playlistNameLabel.backgroundColor = [UIColor blueColor];
        
        self.songCountLabel = [[UILabel alloc] init];
        
        [self.songCountLabel setFrame:CGRectMake(60.0f, 25.0f, 100.0f, 21.0f)];

        [self.songCountLabel setTextColor:[UIColor colorWithRed:49.0/255.0 green:17.0/255.0 blue:65.0/255.0 alpha:1.0]];
        [self.songCountLabel setBackgroundColor:[UIColor clearColor]];
        [self.songCountLabel  setFont:[UIFont fontWithName: @"Helvetica" size: 10.0f]];
        [self.songCountLabel setTextAlignment:NSTextAlignmentRight];
        
        //[self.songCountLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.songCountLabel setTranslatesAutoresizingMaskIntoConstraints:false];
        
//         self.songCountLabel.backgroundColor = [UIColor greenColor];
        
        NSLayoutConstraint *playlistCenterYconstraint = [NSLayoutConstraint constraintWithItem:self.playlistNameLabel
                                                                                     attribute:NSLayoutAttributeCenterY
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:self.contentView
                                                                                     attribute:NSLayoutAttributeCenterY
                                                                                    multiplier:1.0
                                                                                      constant:0];
        NSLayoutConstraint *playlistWidthConstraint = [NSLayoutConstraint constraintWithItem:self.playlistNameLabel
                                                                                   attribute:NSLayoutAttributeWidth
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:nil
                                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                                  multiplier:1.0
                                                                                    constant:257.0f];
        NSLayoutConstraint *playlistHeightConstraint = [NSLayoutConstraint constraintWithItem:self.playlistNameLabel
                                                                                    attribute:NSLayoutAttributeHeight
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:nil
                                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                                   multiplier:1.0
                                                                                     constant:21.0f];
        NSLayoutConstraint *playlistLeadingConstraint = [NSLayoutConstraint constraintWithItem:self.playlistNameLabel
                                                                                     attribute:NSLayoutAttributeLeading
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:self.contentView
                                                                                     attribute:NSLayoutAttributeLeading
                                                                                    multiplier:1.0
                                                                                      constant:60];
        
        
        NSLayoutConstraint *countCenterYconstraint = [NSLayoutConstraint constraintWithItem:self.songCountLabel
                                                                             attribute:NSLayoutAttributeCenterY
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.contentView
                                                                             attribute:NSLayoutAttributeCenterY
                                                                            multiplier:1.0
                                                                              constant:0];
        NSLayoutConstraint *countWidthConstraint = [NSLayoutConstraint constraintWithItem:self.songCountLabel
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:100.0f];
        NSLayoutConstraint *countHeightConstraint = [NSLayoutConstraint constraintWithItem:self.songCountLabel
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:21.0f];
        NSLayoutConstraint *countTrailingConstraint = [NSLayoutConstraint constraintWithItem:self.songCountLabel
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.contentView
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:-40];
       

        [self.contentView addSubview:self.playlistNameLabel];
        [self.contentView addSubview:self.songCountLabel];
        [self.contentView addConstraints:@[countCenterYconstraint,countWidthConstraint,countHeightConstraint,countTrailingConstraint,playlistCenterYconstraint,playlistWidthConstraint,playlistHeightConstraint,playlistLeadingConstraint]];
        
        UILabel *_tickLabel;
        UILabel *_crossLabel;
        
        _tickLabel = [self createTickLabel];
        _tickLabel.text = @"Dropping soon :) \u2713";
        _tickLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_tickLabel];
        
        _crossLabel = [self createCrossLabel];
        _crossLabel.text = @"\u2717";
        _crossLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_crossLabel];
        
        
        const float UI_CUES_WIDTH = self.bounds.size.width;
        
        _tickLabel.frame = CGRectMake(-UI_CUES_WIDTH - UI_CUES_MARGIN, 0, UI_CUES_WIDTH, self.bounds.size.height);
        _crossLabel.frame = CGRectMake(self.bounds.size.width + UI_CUES_MARGIN, 0,
                                       UI_CUES_WIDTH, self.bounds.size.height);
        
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(10, frame.size.height, frame.size.width, 0.5f)];
        
        CGFloat borderWidth = 0.1f;
        lineView.layer.borderWidth = borderWidth;
        lineView.backgroundColor = [UIColor lightGrayColor];
        [self.contentView addSubview:lineView];
    }
    return self;
}

- (void) setPlaylistNameAndSongCount:(NSString*)playlistName :(NSString*) songCount {

    self.playlistNameLabel.text = playlistName;
    self.songCountLabel.text = songCount;

}


-(UILabel*) createTickLabel {

    UILabel* label = [[UILabel alloc] initWithFrame:CGRectNull];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:32.0];
    label.backgroundColor = [UIColor colorWithRed:(202/255.0) green:(84/255.0) blue:(158/255.0) alpha:1];

    return label;
}

-(UILabel*) createCrossLabel {
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectNull];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:32.0];
    label.backgroundColor = [UIColor colorWithRed:250.0f/255.0f green:65.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
    
    return label;
}



@end

