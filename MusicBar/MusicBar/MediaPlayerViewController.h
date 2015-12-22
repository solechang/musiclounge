//
//  iLLMediaPlayerViewController.h
//  iLList
//
//  Created by Jake Choi on 12/26/14.
//  Copyright (c) 2014 iLList. All rights reserved.
//

#import <UIKit/UIKit.h>

// Websocket
#import <SocketRocket/SRWebSocket.h>

@interface MediaPlayerViewController : UIViewController <SRWebSocketDelegate>


@property (nonatomic,strong) NSMutableArray *userPlaylistItems;

@property (nonatomic,strong) NSMutableArray *playlistItems;

- (id)initWithMessage:(NSString *)message fromMe:(BOOL)fromMe;

@end
