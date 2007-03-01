/*
 *  ITunesAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

#import "ITunesInfo.h"

SPARK_PRIVATE
NSString * const kiTunesActionBundleIdentifier;
#define kiTunesActionBundle		[NSBundle bundleWithIdentifier:kiTunesActionBundleIdentifier]

typedef enum {
  kiTunesLaunch        = 'Laun', /* 1281455470 */
  kiTunesQuit          = 'Quit', /* 1366649204 */
  
  kiTunesStop          = 'Stop', /* 1400139632 */
  kiTunesPlayPause     = 'PlPs', /* 1349275763 */
  kiTunesBackTrack     = 'Back', /* 1113678699 */
  kiTunesNextTrack     = 'Next', /* 1315272820 */
  
  kiTunesRateTrack     = 'RaTr', /* 1382110322 */
  kiTunesPlayPlaylist  = 'PlPy', /* 1349275769 */
  kiTunesShowTrackInfo = 'TrIn', /* 1416776046 */
  
  kiTunesVolumeUp      = 'VoUp', /* 1450136944 */
  kiTunesVolumeDown    = 'VoDo', /* 1450132591 */
  
  kiTunesVisual        = 'Visu', /* 1449751413 */
  kiTunesEjectCD       = 'Ejec', /* 1164600675 */
} iTunesAction;

@interface ITunesAction : SparkAction <NSCoding, NSCopying> {
  @private
    iTunesAction ia_action;
  
  UInt64 ia_plid;
  NSString *ia_playlist;
  
  struct _ia_iaFlags {
    unsigned int rate:7; /* 0 to 100 */
    /* launch flags */
    unsigned int hide:1;
    unsigned int notify:1;
    unsigned int autoplay:1;
    unsigned int background:1;
    /* Play/Pause settings */
    unsigned int autorun:1;
    /* Track Info */
    unsigned int autoinfo:1;    
    /* visuals settings */
    unsigned int show:1; /* visual enabled */
    unsigned int visual:2; /* visual type: default, custom */
    unsigned int reserved:16;
  } ia_iaFlags;
  
  ITunesVisual *ia_visual;
}

+ (ITunesVisual *)defaultVisual;
+ (void)setDefaultVisual:(const ITunesVisual *)visual;

- (SInt32)rating;
- (void)setRating:(SInt32)aRate;

- (NSString *)playlist;
- (void)setPlaylist:(NSString *)newPlaylist uid:(UInt64)uid;

- (iTunesAction)iTunesAction;
- (void)setITunesAction:(iTunesAction)newAction;

- (const ITunesVisual *)visual;
- (void)setVisual:(const ITunesVisual *)visual;

- (BOOL)showInfo;
- (void)setShowInfo:(BOOL)flag;

- (int)visualMode;
- (void)setVisualMode:(int)mode;

- (BOOL)launchHide;
- (void)setLaunchHide:(BOOL)flag;
- (BOOL)launchPlay;
- (void)setLaunchPlay:(BOOL)flag;
- (BOOL)launchNotify;
- (void)setLaunchNotify:(BOOL)flag;
- (BOOL)launchBackground;
- (void)setLaunchBackground:(BOOL)flag;

- (BOOL)autorun;
- (void)setAutorun:(BOOL)value;

- (BOOL)autoinfo;
- (void)setAutoinfo:(BOOL)flag;

- (void)switchVisualStat;
- (void)volumeUp;
- (void)volumeDown;
- (void)ejectCD;
- (SparkAlert *)playPlaylist;

@end

SK_PRIVATE
NSImage *ITunesActionIcon(ITunesAction *action);

SK_PRIVATE
NSString *ITunesActionDescription(ITunesAction *action);
