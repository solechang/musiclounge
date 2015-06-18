//
//  Song.h
//  MusicBar
//
//  Created by Jake Choi on 6/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Playlist;

@interface Song : NSManagedObject

@property (nonatomic, retain) NSString * artwork;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * hostId;
@property (nonatomic, retain) NSString * hostName;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSString * playlistId;
@property (nonatomic, retain) NSString * stream_url;
@property (nonatomic, retain) NSString * time;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * uploadingUser;
@property (nonatomic, retain) Playlist *playlist;

@end
