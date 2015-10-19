//
//  SongFriendManager.h
//  MusicBar
//
//  Created by Jake Choi on 4/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <Foundation/Foundation.h>

// CoreData
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"

#import "PlaylistFriend.h"
#import "SongFriend.h"

#import "CustomSong.h"

@interface SongFriendManager : NSObject

- (id)initWithTrackName:(NSString *)trackName;
- (id)initWithSong:(CustomSong *)song;
-(id) initWithSoundCloudUsername: (NSString*)username;
-(id) initWithSoundCloudUserID: (NSString*)userID;


- (NSString *) getUserResourceURL;
- (NSString *) getSongResourceURL;
- (NSString *) getSoundCloudUserSongsURL:(NSString*)type userID:(NSString*)userID limit:(NSString*)limit offset:(NSString*)offset;

- (NSMutableArray*) parseTrackData:(NSData *) trackData;
- (NSMutableArray *) getUserSoundCloudInfo: (NSData *) userData;
- (NSMutableArray* )getSoundCloudUserSongs:(NSData *) trackData;


// Songs
- (void) addSongToPlaylist: (CustomSong*) songAtCell playlistInfo:(PlaylistFriend*)iLListInfo playlistTracks: (NSMutableArray*) iLListTracks;

@property (nonatomic) NSString *trackName;
@property (nonatomic) CustomSong *song;

@property (nonatomic) NSString *soundCloudUsername;

@property (nonatomic, retain) PlaylistFriend *playlistInfo;

@property (nonatomic) NSString *soundCloudUserID;


@end