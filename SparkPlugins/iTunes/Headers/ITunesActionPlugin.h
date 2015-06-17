/*
 *  ITunesActionPlugin.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPlugInAPI.h>

#import "ITunesAction.h"

@class ITunesVisualSetting;
@interface ITunesActionPlugin : SparkActionPlugIn <NSMenuDelegate> {
  IBOutlet NSTextField *ibName;
  IBOutlet NSImageView *ibIcon;
  IBOutlet NSTabView *ibTabView;
  IBOutlet NSButton *ibBackground;
  IBOutlet NSTabView *ibOptionsTab;
  IBOutlet NSPopUpButton *uiPlaylists;
  
  IBOutlet ITunesVisualSetting *ibVisual;
}

@property(nonatomic) iTunesAction iTunesAction;

@property(nonatomic) int32_t rating;

@property(nonatomic, copy) NSString *playlist;

@property(nonatomic, readonly) NSArray *playlists;

@property(nonatomic, readonly) NSString *defaultName;

- (void)loadPlaylists;
+ (NSDictionary *)iTunesPlaylists;

/* Launch flags */
@property(nonatomic) BOOL lsPlay;

@property(nonatomic) BOOL lsHide;

@property(nonatomic) BOOL lsBackground;

- (IBAction)toggleSettings:(id)sender;

@end
