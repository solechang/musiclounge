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

//                CGFloat borderWidth = 0.3f;
//        UIView *cellView = [[UIView alloc] initWithFrame:frame];
//        
//                cellView.layer.borderWidth = borderWidth;
//        cellView.layer.borderColor = [UIColor lightGrayColor].CGColor;
//        
//        self.backgroundView = cellView;
        
        
//        self.contentView = lineView;
        
//        [self setLabelPlaylistTitle:[UILabel new]];
//   
//        [_labelPlaylistTitle setTextColor:[UIColor blackColor]];
////        [_labelPlaylistTitle setBackgroundColor:[UIColor clearColor]];
//        [_labelPlaylistTitle  setFont:[UIFont fontWithName: @"Helvetica" size: 16.0f]];
//     
//        [[self labelPlaylistTitle] setFrame:CGRectMake(30.f, 17.0f, 257.f, 21.f)];
//        
//        [[self labelPlaylistTitle] setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
//        [self.contentView addSubview:self.labelPlaylistTitle];
//        
//        [self setLabelPlaylistCreator:[UILabel new]];
//        [_labelPlaylistCreator setTextColor:[UIColor blackColor]];
//        [_labelPlaylistCreator setBackgroundColor:[UIColor clearColor]];
//        [_labelPlaylistCreator  setFont:[UIFont fontWithName: @"Helvetica" size: 10.0f]];
//        [[self labelPlaylistCreator] setFrame:CGRectMake(250.f, 25.f, 257.f, 21.f)];
//        
//        [[self labelPlaylistCreator] setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
//        [[self contentView] addSubview:[self labelPlaylistCreator]];
        
        self.labelPlaylistTitle = [[UILabel alloc] init];
        
        [self.labelPlaylistTitle setFrame:CGRectMake(30.f, 17.0f, 257.f, 21.f)];
        [self.labelPlaylistTitle setTextColor:[UIColor blackColor]];
        [self.labelPlaylistTitle setBackgroundColor:[UIColor clearColor]];
        [self.labelPlaylistTitle  setFont:[UIFont fontWithName: @"Helvetica" size: 16.0f]];
        
        [self.labelPlaylistTitle setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.contentView addSubview:self.labelPlaylistTitle];

        
        UILabel *_tickLabel;
        UILabel *_crossLabel;
        
        _tickLabel = [self createTickLabel];
        _tickLabel.text = @"\u2713";
        _tickLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_tickLabel];
        
        _crossLabel = [self createCrossLabel];
        _crossLabel.text = @"\u2717";
        _crossLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_crossLabel];
        
        
        const float UI_CUES_WIDTH = self.bounds.size.width;
        
        _tickLabel.frame = CGRectMake(-UI_CUES_WIDTH - UI_CUES_MARGIN, 0,
                                      UI_CUES_WIDTH, self.bounds.size.height);
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

- (void) setPlaylistTitle:(NSString*)playlistTitle {
    
    NSLog(@"2.) %@", playlistTitle);
    self.labelPlaylistTitle.text = playlistTitle;
    
//    [self setLabelPlaylistCreator:[UILabel new]];
//    [_labelPlaylistCreator setTextColor:[UIColor blackColor]];
//    [_labelPlaylistCreator setBackgroundColor:[UIColor clearColor]];
//    [_labelPlaylistCreator  setFont:[UIFont fontWithName: @"Helvetica" size: 10.0f]];
//    [[self labelPlaylistCreator] setFrame:CGRectMake(250.f, 25.f, 257.f, 21.f)];
//
//    [[self labelPlaylistCreator] setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
//    [[self contentView] addSubview:[self labelPlaylistCreator]];

}

//-(void) layoutSubviews {
//    [super layoutSubviews];
//    // ensure the gradient layers occupies the full bounds
//
//    
//}

-(UILabel*) createTickLabel {

    UILabel* label = [[UILabel alloc] initWithFrame:CGRectNull];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:32.0];
    label.backgroundColor = [UIColor greenColor];
    return label;
}

-(UILabel*) createCrossLabel {
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectNull];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:32.0];
    label.backgroundColor = [UIColor redColor];
    
    return label;
}



@end

