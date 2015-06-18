//
//  NowPlaying.h
//  MusicBar
//
//  Created by Jake Choi on 6/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NowPlayingSong;

@interface NowPlaying : NSManagedObject

@property (nonatomic, retain) NSString * currentlyPlayingSongId;
@property (nonatomic, retain) NSString * playlistId;
@property (nonatomic, retain) NSString * playlistName;
@property (nonatomic, retain) NSNumber * songIndex;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSSet *nowPlayingSong;
@end

@interface NowPlaying (CoreDataGeneratedAccessors)

- (void)addNowPlayingSongObject:(NowPlayingSong *)value;
- (void)removeNowPlayingSongObject:(NowPlayingSong *)value;
- (void)addNowPlayingSong:(NSSet *)values;
- (void)removeNowPlayingSong:(NSSet *)values;

@end
