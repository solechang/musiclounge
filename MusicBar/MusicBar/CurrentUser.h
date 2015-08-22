//
//  CurrentUser.h
//  MusicBar
//
//  Created by Anthony Merrin on 8/21/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UserFriendList;

@interface CurrentUser : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * profilePicture;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) UserFriendList *userFriendList;

@end
