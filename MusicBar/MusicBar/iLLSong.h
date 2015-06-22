//
//  iLLSong.h
//  iLList
//
//  Created by Jake Choi on 12/9/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iLLSong : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *uploadingUser;
@property (nonatomic, strong) NSString *image;
@property (nonatomic, strong) NSString *time;
@property (nonatomic, strong) NSString *stream_url;
@property (nonatomic, strong) NSString *addedBy;

@end
