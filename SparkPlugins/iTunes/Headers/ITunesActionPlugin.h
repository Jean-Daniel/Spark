//
//  ITunesActionPlugin.h
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>

#import "ITunesAction.h"

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
