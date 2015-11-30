//
//  SoundCloudSearchTest.m
//  MusicLounge
//
//  Created by Jake Choi on 11/19/15.
//  Copyright © 2015 Sole Chang. All rights reserved.
//

#import "ApiClient.h"
#import <XCTest/XCTest.h>

@interface SoundCloudSearchTest : XCTestCase

@end

@implementation SoundCloudSearchTest

- (void)setUp {
    [super setUp];
    
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void) testSoundCloundKoreanSongsSearched {
    
    
    NSString *url = [NSString stringWithFormat:@"https://api.soundcloud.com/tracks/%@/stream.json?client_id=%@", trackID, clientID];
    NSLog(@"1.) %@", url);
    flagSong = YES;
    
    // Checks if http_mp3_128_url exists to play music
    [[ApiClient sharedClient] GET:url parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSDictionary *i1Response = responseObject;
        
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        NSLog(@"Error: %@", error);
    }];

}

@end
