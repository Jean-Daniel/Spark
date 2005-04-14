//
//  ITunesActionPlugin.h
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SparkKit/SparkKit.h>

extern NSString * const kiTunesActionBundleIdentifier;

#define kiTunesActionBundle		[NSBundle bundleWithIdentifier:kiTunesActionBundleIdentifier]

typedef enum {
  kiTunesLaunch			= 0,
  kiTunesQuit			= 1,
  kiTunesPlayPause		= 2,
  kiTunesBackTrack		= 3,
  kiTunesNextTrack		= 4,
  kiTunesStop			= 5,
  kiTunesVisual			= 6,
  kiTunesVolumeDown		= 7,
  kiTunesVolumeUp		= 8,
  kiTunesEjectCD		= 9,
  kiTunesPlayPlaylist	= 10,
  kiTunesRateTrack		= 11,
}iTunesAction;

@interface ITunesActionPlugin : SparkActionPlugIn {
  IBOutlet id nameField;
  IBOutlet id detailView;
  NSString *_playlist;
  NSArray *_playlists;
  unsigned _rate;
}

- (iTunesAction)iTunesAction;
- (void)setITunesAction:(iTunesAction)newAction;

- (NSString *)shortDescription;

- (unsigned)rate;
- (void)setRate:(unsigned)rate;

- (unsigned)detailViewIndex;

- (NSString *)playlist;
- (void)setPlaylist:(NSString *)aPlaylist;

- (NSArray *)playlists;
- (void)setPlaylists:(NSArray *)playlists;

- (NSString *)defaultName;

- (void)loadPlaylists;
+ (NSArray *)iTunesPlaylists;

@end
