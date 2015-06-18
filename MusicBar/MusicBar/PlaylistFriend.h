//
//  PlaylistFriend.h
//  MusicBar
//
//  Created by Jake Choi on 6/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SongFriend;

@interface PlaylistFriend : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSNumber * songCount;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSSet *songFriend;
@end

@interface PlaylistFriend (CoreDataGeneratedAccessors)

- (void)addSongFriendObject:(SongFriend *)value;
- (void)removeSongFriendObject:(SongFriend *)value;
- (void)addSongFriend:(NSSet *)values;
- (void)removeSongFriend:(NSSet *)values;

@end
