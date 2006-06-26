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

@class SKBezelItem;
@interface ITunesAction : SparkAction <NSCoding, NSCopying> {
  IBOutlet NSTextField *track;
  IBOutlet NSTextField *artist;
  IBOutlet NSTextField *album;
  IBOutlet NSImageView *artwork;
  @private
  SKBezelItem *ia_bezel;
  
  iTunesAction ia_action;
  NSString *ia_playlist;
  SInt16 ia_rating;
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
