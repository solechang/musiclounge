//
//  SongFriendManager.m
//  MusicBar
//
//  Created by Jake Choi on 4/17/15.
//  Copyright (c) 2015 Sole Chang. All rights reserved.
//

#import "SongFriendManager.h"
#import <Parse/Parse.h>

@implementation SongFriendManager{
    NSMutableArray *playlistTracks;

}

-(id) initWithSoundCloudUserID: (NSString*)userID {
    self = [super init];
    
    if(self)
    {
        self.soundCloudUserID = userID;
    }
    return self;
    
}

-(id) initWithSoundCloudUsername: (NSString*)username {
    
    
    self = [super init];
    
    if(self)
    {
        self.soundCloudUsername = username;
    }
    return self;
    
}


-(id)initWithTrackName:(NSString *)trackName {
    
    self = [super init];
    
    if(self)
    {
        self.trackName = trackName;
        [self setUpData];
    }
    return self;
    
    
}

-(id)initWithSong:(CustomSong *)song {
    
    self = [super init];
    
    if(self)
    {
        self.song= song;
        [self setUpData];
    }
    return self;
}

- (void) setUpData {
    
    playlistTracks = [[NSMutableArray alloc] init];
    
}

- (NSString *) getSoundCloudUserSongsURL:(NSString*)type userID:(NSString*)userID limit:(NSString*)limit offset:(NSString*)offset {
    
    NSString *clientID = @"fc8c97d1af51d72375bf565acc9cfe60";
    NSString *resourceURL = [NSString stringWithFormat:@"https://api.soundcloud.com/users/%@/%@.json?client_id=%@&limit=%@&offset=%@", userID, type, clientID, limit, offset];
    
    return resourceURL;
    
}

- (NSString *) getUserResourceURL {
    
    NSString *clientID = @"fc8c97d1af51d72375bf565acc9cfe60";
    NSString *resourceURL = [NSString stringWithFormat:@"https://api.soundcloud.com/users/%@.json?client_id=%@", self.soundCloudUsername, clientID];
    
    return resourceURL;
    
}

- (NSString *) getSongResourceURL {
    
    NSString *clientID = @"fc8c97d1af51d72375bf565acc9cfe60";
    NSString *resourceURL = [NSString stringWithFormat:@"https://api.soundcloud.com/tracks?q=%@&client_id=%@&format=json&limit=50", self.trackName, clientID];
    
    return resourceURL;
    
}



-(NSMutableArray* )getSoundCloudUserSongs:(NSData *) trackData{
    
    NSError *jsonError = nil;
    
    if ( trackData != nil) {
        
        NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                             JSONObjectWithData:trackData
                                             options:NSJSONReadingMutableContainers | NSJSONReadingAllowFragments
                                             error:&jsonError];
        
        if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]]) {
            
            NSArray *tracks = [[NSArray alloc] initWithArray:(NSArray *)jsonResponse];
            
            NSDictionary *track = [[NSDictionary alloc] init];
            NSMutableArray *trackDescription = [[NSMutableArray alloc] init];
            
            // This loop below will extract the json into a dictionary to parse the title and other info of the searched songs.
            for (int i = 0; i < tracks.count; i++ ) {
                
                CustomSong *song = [CustomSong new];
                track = [tracks objectAtIndex:i];
                
                
                if (![track isEqual: [NSNull null]]) {
                    
                    if (track[@"stream_url"] != nil && ![track[@"stream_url"] isEqual: [NSNull null]] ) {
                        
                        song.title = track[@"title"];
                        song.stream_url = track[@"stream_url"];
                        
                        
                        song.time = [self formatInterval:[track[@"duration"] intValue]];
                        NSDictionary *uploadingUserInfo = track[@"user"];
                        song.uploadingUser = uploadingUserInfo[@"permalink"];
                        
                        if (![track[@"artwork_url"] isEqual:[NSNull null]]) {
                            
                            song.image = track[@"artwork_url"];
                            
                        } else {
                            // User's avatar picture if there is not artwork for the track
                            song.image = uploadingUserInfo[@"avatar_url"];
                        }
                        [trackDescription addObject:song];
                        
                    }
                    
                }
                
            }
            
            return trackDescription;
            
            
        } else {
            //            NSLog(@"ERROR: %@", jsonError.localizedDescription);
            return nil;
        }
    }
    return nil;
}



- (NSMutableArray *) getUserSoundCloudInfo: (NSData *) userData {
    
    NSMutableArray *userDescriptionArray = [[NSMutableArray alloc] init];
    NSError *jsonError = nil;
    
    if ( userData != nil) {
        
        NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                             JSONObjectWithData:userData
                                             options:NSJSONReadingMutableContainers | NSJSONReadingAllowFragments
                                             error:&jsonError];
        
        if (!jsonError && [jsonResponse isKindOfClass:[NSDictionary class]]) {
            
            NSDictionary *jsonResponseDictionary = [[NSDictionary alloc] initWithDictionary:(NSDictionary*)jsonResponse];
            
            if (!jsonResponseDictionary[@"errors"]) {
                
                CustomSong *soundCloudUserInfo = [[CustomSong alloc] init];
                
                
                soundCloudUserInfo.title = jsonResponseDictionary[@"permalink"];
                
                if (jsonResponseDictionary[@"avatar_url"]) {
                    soundCloudUserInfo.image = jsonResponseDictionary[@"avatar_url"];
                } else {
                    soundCloudUserInfo.image = nil;
                }
                soundCloudUserInfo.addedBy = @"noButtonForSoundCloudUser";
                
                soundCloudUserInfo.userSoundCloudID = jsonResponseDictionary[@"id"];
                soundCloudUserInfo.likesCount = jsonResponseDictionary[@"public_favorites_count"];
                soundCloudUserInfo.playlistsCount = jsonResponseDictionary[@"playlist_count"];
                soundCloudUserInfo.tracksCount = jsonResponseDictionary[@"track_count"];
                
                NSString *likes = [NSString stringWithFormat:@"%@", jsonResponseDictionary[@"full_name"]];
                soundCloudUserInfo.uploadingUser = likes;
                
                [userDescriptionArray addObject:soundCloudUserInfo];
                
            } else {
                
                CustomSong *soundCloudUserInfo = [[CustomSong alloc] init];
                
                NSString *userNameSC = [self.soundCloudUsername stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
                
                NSString *noUserFound = [NSString stringWithFormat:@"%@ is not found :(", userNameSC];
                
                soundCloudUserInfo.title = noUserFound;
                soundCloudUserInfo.addedBy = @"noButtonForSoundCloudUser";
                
                [userDescriptionArray addObject:soundCloudUserInfo];
            }
            
            
            
        }
        
    }
    
    
    return userDescriptionArray;
}

-(NSMutableArray* )parseTrackData:(NSData *) trackData{
    
    NSError *jsonError = nil;
    
    if ( trackData != nil) {
        
        NSJSONSerialization *jsonResponse = [NSJSONSerialization
                                             JSONObjectWithData:trackData
                                             options:NSJSONReadingMutableContainers | NSJSONReadingAllowFragments
                                             error:&jsonError];
        
        if (!jsonError && [jsonResponse isKindOfClass:[NSArray class]]) {
            
            NSArray *tracks = [[NSArray alloc] initWithArray:(NSArray *)jsonResponse];
            //            self.tracks = (NSArray *)jsonResponse;
            
            NSDictionary *track = [[NSDictionary alloc] init];
            NSMutableArray *trackDescription = [[NSMutableArray alloc] init];
            
            // This loop below will extract the json into a dictionary to parse the title and other info of the searched songs.
            for (int i = 0; i < tracks.count; i++ ) {
                
                CustomSong *song = [CustomSong new];
                track = [tracks objectAtIndex:i];
                
                
                if (![track isEqual: [NSNull null]]) {
                    
                    if (track[@"stream_url"] != nil && ![track[@"stream_url"] isEqual: [NSNull null]] ) {
                        
                        song.title = track[@"title"];
                        song.stream_url = track[@"stream_url"];
                        song.time = [self formatInterval:[track[@"duration"] intValue]];
                        NSDictionary *uploadingUserInfo = track[@"user"];
                        song.uploadingUser = uploadingUserInfo[@"permalink"];
                        
                        if (![track[@"artwork_url"] isEqual:[NSNull null]]) {
                            
                            song.image = track[@"artwork_url"];
                            
                        } else {
                            // User's avatar picture if there is not artwork for the track
                            song.image = uploadingUserInfo[@"avatar_url"];
                        }
                        [trackDescription addObject:song];
                        
                    }
                    
                }
                
            }
            
            return trackDescription;
            
            
        } else {
            //            NSLog(@"ERROR: %@", jsonError.localizedDescription);
            return nil;
        }
    }
    return nil;
}



#pragma mark - duration of song
- (NSString *) formatInterval: (NSTimeInterval) interval{
    unsigned long milliseconds = interval;
    unsigned long seconds = milliseconds / 1000;
    milliseconds %= 1000;
    unsigned long minutes = seconds / 60;
    seconds %= 60;
    unsigned long hours = minutes / 60;
    minutes %= 60;
    
    //    NSMutableString * result = [NSMutableString new];
    
    NSString * result;
    if(hours) {
        result = [NSString stringWithFormat:@"%lu:", hours];
    } else {
        result = [[NSString alloc] init];
    }
    if( minutes < 10 && minutes > 0) {
        NSString *minute = [[NSNumber numberWithLong:minutes] stringValue];
        //        NSLog(@"minutes:0%@", minute);
        result = [NSString stringWithFormat:@"%@0%@:",result,minute];
    } else {
        //        [result appendFormat: @"%2lu:", minutes];
        if ( minutes == 0) {
            result = [NSString stringWithFormat:@"%@%lu0:",result,minutes];
         
        } else {
            result = [NSString stringWithFormat:@"%@%lu:",result,minutes];

        }
        
    }
    
    
    if( seconds < 10 ) {
        //        [result appendFormat: @"%2lu", seconds];
        NSString *second = [[NSNumber numberWithLong:seconds] stringValue];
        //        NSLog(@"seconds:0%@", second);
        result = [NSString stringWithFormat:@"%@0%@",result,second];
    } else {
        //        [result appendFormat: @"%2lu", seconds];
        result = [NSString stringWithFormat:@"%@%lu",result,seconds];
        //        NSLog(@"seconds:%lu", seconds);
    }
    //    NSLog(@"time:%@" , result);
    
    //    [result appendFormat: @"%2lu",milliseconds];
    
    return result;
}
- (void) addSongToPlaylist:(CustomSong*)songAtCell playlistInfo:(PlaylistFriend*)playlist playlistTracks:(NSMutableArray*) iLListTracks {
    
    // Creating a song PFObject in the server
    PFObject *song = [PFObject objectWithClassName:@"Song"];
    
    song[@"iLListId"] = playlist.objectId;
    
    song[@"host"] = [PFUser currentUser].objectId; // The person who uploaded the song to the iLList
    song[@"title"] = songAtCell.title;
    song[@"uploadingUser"] = songAtCell.uploadingUser;
    song[@"time"] = songAtCell.time;
    song[@"artwork"] = songAtCell.image;
    song[@"stream_url"] = songAtCell.stream_url;
    song[@"hostName"] = [PFUser currentUser][@"name"];
    
    PFACL *defaultACL = [PFACL ACL];
    
    [defaultACL setWriteAccess:YES forUser:[PFUser currentUser]];
    [defaultACL setWriteAccess:YES forUserId:playlist.userId];
//    [defaultACL setWr]
//    [defaultACL setPublicWriteAccess:YES];

    [defaultACL setPublicReadAccess:YES];
    
    song.ACL = defaultACL;
    
    self.playlistInfo = playlist;
    playlistTracks = iLListTracks;
    
    [self saveSongToServer:song ];
    
}

- (void)saveSongToServer:(PFObject*) song{
    
    // Updating the playlist in the server
    PFObject *illistInServer = [PFObject objectWithoutDataWithClassName:@"Illist" objectId:song[@"iLListId"]];
    
    // Updating the playlist's song count
    NSArray *songsFriendInLocal = [SongFriend MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:[NSManagedObjectContext MR_defaultContext]];
    
    int songCountUpdate = (int)songsFriendInLocal.count;
    
    songCountUpdate++;
//    NSLog(@"0.) %@", [NSNumber numberWithInt:songCountUpdate]);
    illistInServer[@"SongCount"] = [NSNumber numberWithInt:songCountUpdate];
    
    NSMutableArray *sendObjectsToServer = [[NSMutableArray alloc] init];
    
    [sendObjectsToServer addObject:illistInServer];
    [sendObjectsToServer addObject:song];
    
    [PFObject saveAllInBackground:sendObjectsToServer block:^(BOOL succeeded, NSError *error) {
        
        if (succeeded) {
//            NSLog(@"Illist: %@, Song: %@", illistInServer.updatedAt, song.updatedAt);
            [self saveSongToLocal:song];
            
        } else {
//            NSLog(@"211.)");
            
        }
        
    }];
    
}

- (void) saveSongToLocal:(PFObject*) song {
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        // Update playlist in local
        PlaylistFriend *playlistInLocal = [PlaylistFriend MR_findFirstByAttribute:@"objectId" withValue:self.playlistInfo.objectId inContext:localContext];
        
        // Create song in local
        SongFriend *songInLocal = [SongFriend MR_createEntityInContext:localContext];
        
        songInLocal.artwork = song[@"artwork"];
        songInLocal.hostId = song[@"host"];
        songInLocal.hostName = song[@"hostName"];
        songInLocal.objectId = song.objectId;
        songInLocal.playlistId = self.playlistInfo.objectId;
        songInLocal.stream_url = song[@"stream_url"];
        songInLocal.time = song[@"time"];
        songInLocal.title = song[@"title"];
        songInLocal.uploadingUser = song[@"uploadingUser"];
        songInLocal.createdAt = song.createdAt;
        
        [playlistInLocal addSongFriendObject:songInLocal];
        
        NSArray *songsFriendInLocal = [SongFriend MR_findByAttribute:@"playlistId" withValue:self.playlistInfo.objectId andOrderBy:@"createdAt" ascending:NO inContext:localContext];
        
        int songCountUpdate = (int) songsFriendInLocal.count;
    
        
        playlistInLocal.songCount = [NSNumber numberWithInt:songCountUpdate];
        playlistInLocal.updatedAt = song.updatedAt;
        
        
    } completion:^(BOOL success, NSError *error) {
        
        if (!error) {
            // Notify the user that the song has been added
            NSDictionary* songInfo = @{@"song": song};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SongAdded" object:self userInfo:songInfo];
            
        } else {
            
//            NSLog(@"Error: %@ 267", error.localizedDescription);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadTableView" object:self ];
            
            
        }
        
    }];
    
}

@end
