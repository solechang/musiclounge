//
//  FriendPhonenumber.h
//  MusicBar
//
//  Created by Jake Choi on 6/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Friend;

@interface FriendPhonenumber : NSManagedObject

@property (nonatomic, retain) NSString * phonenumber;
@property (nonatomic, retain) Friend *friend;

@end
