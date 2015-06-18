//
//  Playlist.h
//  MusicBar
//
//  Created by Jake Choi on 6/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Song;

@interface Playlist : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSNumber * songCount;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSSet *song;
@end

@interface Playlist (CoreDataGeneratedAccessors)

- (void)addSongObject:(Song *)value;
- (void)removeSongObject:(Song *)value;
- (void)addSong:(NSSet *)values;
- (void)removeSong:(NSSet *)values;

@end
