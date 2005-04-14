//
//  ITunesAction.h
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import <SparkKit/SparkKit.h>
#import "ITunesActionPlugin.h"

@interface ITunesAction : SparkAction <NSCoding, NSCopying> {
  iTunesAction _iTunesAction;
  NSString *_playlist;
  SInt16 _rating;
}

- (SInt16)rating;
- (void)setRating:(SInt16)aRate;

- (NSString *)playlist;
- (void)setPlaylist:(NSString *)newPlaylist;

- (iTunesAction)iTunesAction;
- (void)setITunesAction:(iTunesAction)newAction;

- (void)launchITunes;
- (void)quitITunes;

- (void)switchVisualStat;
- (void)volumeUp;
- (void)volumeDown;
- (void)ejectCD;
- (SparkAlert *)playPlaylist:(NSString *)name;

- (void)sendAppleEvent:(OSType)eventType;

@end
