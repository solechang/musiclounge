//
//  PlaylistFriend+CoreDataProperties.h
//  MusicLounge
//
//  Created by Jake Choi on 11/30/15.
//  Copyright © 2015 Sole Chang. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "PlaylistFriend.h"

NS_ASSUME_NONNULL_BEGIN

@interface PlaylistFriend (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *createdAt;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *objectId;
@property (nullable, nonatomic, retain) NSNumber *songCount;
@property (nullable, nonatomic, retain) NSDate *updatedAt;
@property (nullable, nonatomic, retain) NSString *userId;
@property (nullable, nonatomic, retain) NSString *userName;
@property (nullable, nonatomic, retain) NSNumber *fromNowSpinning;
@property (nullable, nonatomic, retain) NSSet<SongFriend *> *songFriend;

@end

@interface PlaylistFriend (CoreDataGeneratedAccessors)

- (void)addSongFriendObject:(SongFriend *)value;
- (void)removeSongFriendObject:(SongFriend *)value;
- (void)addSongFriend:(NSSet<SongFriend *> *)values;
- (void)removeSongFriend:(NSSet<SongFriend *> *)values;

@end

NS_ASSUME_NONNULL_END
