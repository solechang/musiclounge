//
//  SongManager.h
//  iLList
//
//  Created by Jake Choi on 4/9/15.
//  Copyright (c) 2015 iLList. All rights reserved.
//

#import <Foundation/Foundation.h>

// CoreData
#import <MagicalRecord/MagicalRecord.h>
#import "CurrentUser.h"

#import "Playlist.h"
#import "Song.h"

#import "iLLSong.h"

@interface SongManager : NSObject

-(id)initWithTrackName:(NSString *)trackName;
-(id)initWithSong:(iLLSong *)song;

- (NSString *) getResourceURL;
-(NSMutableArray*)parseTrackData:(NSData *) trackData;


// Songs
- (void) addSongToPlaylist: (iLLSong*) songAtCell playlistInfo:(Playlist*)iLListInfo playlistTracks: (NSMutableArray*) iLListTracks;

@property (nonatomic) NSString *trackName;
@property (nonatomic) iLLSong *song;

@property (nonatomic, retain) Playlist *playlistInfo;



@end

