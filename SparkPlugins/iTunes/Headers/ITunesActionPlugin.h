//
//  ITunesActionPlugin.h
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>

SPARK_PRIVATE
NSString * const kiTunesActionBundleIdentifier;

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
} iTunesAction;

@interface ITunesActionPlugin : SparkActionPlugIn {
  IBOutlet NSTextField *nameField;
  IBOutlet NSTabView *optionsView;
  @private
    BOOL it_play;
  unsigned it_rate;
  NSString *it_playlist;
  NSArray *it_playlists;
}

- (iTunesAction)iTunesAction;
- (void)setITunesAction:(iTunesAction)newAction;

- (NSString *)actionDescription;

- (unsigned)rate;
- (void)setRate:(unsigned)rate;

- (NSString *)playlist;
- (void)setPlaylist:(NSString *)aPlaylist;

- (NSArray *)playlists;
- (void)setPlaylists:(NSArray *)playlists;

- (NSString *)defaultName;

- (void)loadPlaylists;
+ (NSArray *)iTunesPlaylists;

@end
