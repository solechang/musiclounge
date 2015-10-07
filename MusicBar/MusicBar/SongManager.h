//
//  SongManager.h
//  MusicBar
//
//  Created by Jake Choi on 4/9/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import <Foundation/Foundation.h>

// CoreData
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"

#import "Playlist.h"
#import "Song.h"

#import "CustomSong.h"

@interface SongManager : NSObject

-(id)initWithTrackName:(NSString *)trackName;
-(id)initWithSong:(CustomSong *)song;
-(id) initWithSoundCloudUsername: (NSString*)username;
-(id) initWithSoundCloudUserID: (NSString*)userID;



- (NSString *) getUserResourceURL;
- (NSString *) getSongResourceURL;
- (NSString *) getUserLikesURL: (NSString*) userID;

- (NSMutableArray*)parseTrackData:(NSData *) trackData;
- (NSMutableArray *) getUserSoundCloudInfo: (NSData *) userData;



// Songs
- (void) addSongToPlaylist: (CustomSong*) songAtCell playlistInfo:(Playlist*)iLListInfo playlistTracks: (NSMutableArray*) iLListTracks;

@property (nonatomic) NSString *trackName;
@property (nonatomic) CustomSong *song;

@property (nonatomic) NSString *soundCloudUsername;

@property (nonatomic, retain) Playlist *playlistInfo;

@property (nonatomic) NSString *soundCloudUserID;



@end

