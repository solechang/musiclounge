//
//  Friend.h
//  MusicBar
//
//  Created by Jake Choi on 6/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FriendPhonenumber, UserFriendList;

@interface Friend : NSManagedObject

@property (nonatomic, retain) NSNumber * friend_exists;
@property (nonatomic, retain) NSString * hostId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSSet *friendPhonenumber;
@property (nonatomic, retain) UserFriendList *userFriendList;
@end

@interface Friend (CoreDataGeneratedAccessors)

- (void)addFriendPhonenumberObject:(FriendPhonenumber *)value;
- (void)removeFriendPhonenumberObject:(FriendPhonenumber *)value;
- (void)addFriendPhonenumber:(NSSet *)values;
- (void)removeFriendPhonenumber:(NSSet *)values;

@end
