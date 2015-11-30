//
//  ApiClient.m
//  MusicLounge
//
//  Created by Chang Choi on 11/19/15.
//  Copyright © 2015 Sole Chang. All rights reserved.
//

#import "ApiClient.h"
static NSString *const ApiClientURLString = @"https://api.soundcloud.com/";

@implementation ApiClient

+ (instancetype) sharedClient{
    
    static ApiClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        _sharedClient = [[ApiClient alloc] initWithBaseURL:[NSURL URLWithString:ApiClientURLString]];
        
    });
    return _sharedClient;
}
@end
