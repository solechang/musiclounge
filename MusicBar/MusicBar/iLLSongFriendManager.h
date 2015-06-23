//
//  iLLSongFriendManager.h
//  iLList
//
//  Created by Jake Choi on 4/17/15.
//  Copyright (c) 2015 iLList. All rights reserved.
//

#import <Foundation/Foundation.h>

// CoreData
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"

#import "PlaylistFriend.h"
#import "SongFriend.h"

#import "CustomSong.h"

@interface iLLSongFriendManager : NSObject

-(id)initWithTrackName:(NSString *)trackName;
-(id)initWithSong:(CustomSong *)song;

- (NSString *) getResourceURL;
-(NSMutableArray*)parseTrackData:(NSData *) trackData;


// Songs
- (void) addSongToPlaylist: (CustomSong*) songAtCell playlistInfo:(PlaylistFriend*)iLListInfo playlistTracks: (NSMutableArray*) iLListTracks;

@property (nonatomic) NSString *trackName;
@property (nonatomic) CustomSong *song;

@property (nonatomic, retain) PlaylistFriend *playlistInfo;

@end
