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
        [self.playlistNameLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.contentView addSubview:self.playlistNameLabel];
            

        self.songCountLabel = [[UILabel alloc] init];
        
        [self.songCountLabel setFrame:CGRectMake(60.0f, 25.0f, 257.0f, 21.0f)];

        [self.songCountLabel setTextColor:[UIColor colorWithRed:49.0/255.0 green:17.0/255.0 blue:65.0/255.0 alpha:1.0]];
        [self.songCountLabel setBackgroundColor:[UIColor clearColor]];
        [self.songCountLabel  setFont:[UIFont fontWithName: @"Helvetica" size: 10.0f]];
        [self.songCountLabel setTextAlignment:NSTextAlignmentRight];
        
        [self.songCountLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.contentView addSubview:self.songCountLabel];
        
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

- (void) setPlaylistNameAndSongCount:(NSString*)playlistName :(NSString*) songCount {
    
    self.playlistNameLabel.text = playlistName;
    self.songCountLabel.text = songCount;

}


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

