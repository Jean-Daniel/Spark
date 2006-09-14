/*
 *  ITunesActionPlugin.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) Shadow Lab. 2004 - 2006. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

#import "ITunesAction.h"

@class ITunesVisualSetting;
@interface ITunesActionPlugin : SparkActionPlugIn {
  IBOutlet NSTextField *ibName;
  IBOutlet NSTabView *ibTabView;
  IBOutlet ITunesVisualSetting *ibVisual;
  @private
    struct _ia_apFlags {
      unsigned int play:1;
      unsigned int background:1;
      unsigned int reserved:30;
    } ia_apFlags;
  NSString *it_playlist;
  NSArray *it_playlists;
}

- (iTunesAction)iTunesAction;
- (void)setITunesAction:(iTunesAction)newAction;

- (SInt32)rating;
- (void)setRating:(SInt32)rate;

- (NSString *)playlist;
- (void)setPlaylist:(NSString *)aPlaylist;

- (NSArray *)playlists;
- (void)setPlaylists:(NSArray *)playlists;

- (NSString *)defaultName;

- (void)loadPlaylists;
+ (NSArray *)iTunesPlaylists;

@end
