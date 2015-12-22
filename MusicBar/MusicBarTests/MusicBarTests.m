//
//  MusicBarTests.m
//  MusicBarTests
//
//  Created by Jake Choi on 6/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


@interface MusicBarTests : XCTestCase
@property (nonatomic, strong) NSArray *tracks;
@property (nonatomic, strong) NSDictionary *userTracks;


@end

@implementation MusicBarTests

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
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void) testRocketSocket {
    
}
- (void)testSearchTracksBySoleChang {
    // searching tracks by a specific user (solechang)
    
    NSString *clientID = @"fc8c97d1af51d72375bf565acc9cfe60";
    
    __block BOOL waitForBlock = YES;
    //solechang's tracks
    NSURL *trackURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.soundcloud.com/users/18953436/tracks?client_id=%@&format=json", clientID]];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:trackURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSError *jsonError;
        NSJSONSerialization *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]]) {
            
            self.tracks = (NSArray *)jsonResponse;
            
            NSDictionary *track = [[NSDictionary alloc] init];
            NSMutableArray *titleName = [[NSMutableArray alloc] init];
            
            for (int i = 0; i < self.tracks.count; i++){
                track = [self.tracks objectAtIndex:i];
                [titleName addObject:track[@"title"]];
                
            }
            
            waitForBlock = NO;
            
        } else {
            
            NSLog(@"%@", error.localizedDescription);
            waitForBlock = NO;
            XCTAssert(NO, @"Failed at searching song title");
        }
    }];
    
    [task resume];
    
    
    
    while(waitForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    XCTAssert(YES, @"Pass");
}

@end
