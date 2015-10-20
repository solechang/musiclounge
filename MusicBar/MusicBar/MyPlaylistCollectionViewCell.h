//
//  MyPlaylistCollectionViewCell.h
//  MusicBar
//
//  Created by Jake Choi on 6/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyPlaylistCollectionViewCell : UICollectionViewCell


@property (nonatomic,readwrite) UILabel *playlistNameLabel;
@property (nonatomic,readwrite) UILabel *songCountLabel;
@property (nonatomic,readwrite) UILabel *updatedAtLabel;

- (void) setPlaylistNameAndSongCount:(NSString*)playlistName :(NSString*) songCount;

@end
