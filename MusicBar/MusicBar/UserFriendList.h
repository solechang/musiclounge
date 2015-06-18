//
//  UserFriendList.h
//  MusicBar
//
//  Created by Jake Choi on 6/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CurrentUser, Friend;

@interface UserFriendList : NSManagedObject

@property (nonatomic, retain) NSString * hostId;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) CurrentUser *currentUser;
@property (nonatomic, retain) NSSet *friend;
@end

@interface UserFriendList (CoreDataGeneratedAccessors)

- (void)addFriendObject:(Friend *)value;
- (void)removeFriendObject:(Friend *)value;
- (void)addFriend:(NSSet *)values;
- (void)removeFriend:(NSSet *)values;

@end
