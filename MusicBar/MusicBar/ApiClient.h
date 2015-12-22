//
//  ApiClient.h
//  MusicLounge
//
//  Created by Chang Choi on 11/19/15.
//  Copyright © 2015 Sole Chang. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import <Foundation/Foundation.h>

@interface ApiClient : AFHTTPSessionManager

+ (instancetype)sharedClient;

@end
