/*
 *  ITunesAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPlugInAPI.h>

#import "ITunesInfo.h"

#define kiTunesActionBundleIdentifier @"org.shadowlab.spark.action.itunes"
#define kiTunesActionBundle		      [NSBundle bundleWithIdentifier:kiTunesActionBundleIdentifier]

typedef NS_ENUM(uint32_t, iTunesAction) {
  kiTunesLaunch        = 'Laun', /* 1281455470 */
  kiTunesQuit          = 'Quit', /* 1366649204 */
  
  kiTunesStop          = 'Stop', /* 1400139632 */
  kiTunesPlayPause     = 'PlPs', /* 1349275763 */
  kiTunesBackTrack     = 'Back', /* 1113678699 */
  kiTunesNextTrack     = 'Next', /* 1315272820 */

  kiTunesRateUp        = 'RatU', /* 1382118485 */
  kiTunesRateDown      = 'RatD', /* 1382118468 */
  kiTunesRateTrack     = 'RaTr', /* 1382110322 */
  kiTunesPlayPlaylist  = 'PlPy', /* 1349275769 */
  kiTunesShowTrackInfo = 'TrIn', /* 1416776046 */
  
  kiTunesVolumeUp      = 'VoUp', /* 1450136944 */
  kiTunesVolumeDown    = 'VoDo', /* 1450132591 */
	kiTunesToggleMute    = 'ToMu', /* 1416580469 */
  
  kiTunesVisual        = 'Visu', /* 1449751413 */
  kiTunesEjectCD       = 'Ejec', /* 1164600675 */
};

enum {
  kiTunesSettingDefault = 0,
  kiTunesSettingCustom = 1,
};

@interface ITunesAction : SparkAction <NSCoding, NSCopying>

+ (ITunesVisual *)defaultVisual;
+ (void)setDefaultVisual:(const ITunesVisual *)visual;

@property(nonatomic) int32_t rating;

@property(nonatomic, readonly) NSString *playlist;

- (void)setPlaylist:(NSString *)newPlaylist uid:(UInt64)uid;

@property(nonatomic) iTunesAction iTunesAction;

@property(nonatomic) const ITunesVisual *visual;

@property(nonatomic) BOOL showInfo;

@property(nonatomic) NSInteger visualMode;

@property(nonatomic) BOOL launchHide;

@property(nonatomic) BOOL launchPlay;

@property(nonatomic) BOOL launchNotify;

@property(nonatomic) BOOL launchBackground;

@property(nonatomic) BOOL autorun;

@property(nonatomic) BOOL autoinfo;

- (void)switchVisualStat;

- (void)volumeUp;
- (void)volumeDown;
- (void)toggleMute;

- (void)ejectCD;
- (SparkAlert *)playPlaylist;

@end

WB_PRIVATE
NSImage *ITunesActionIcon(ITunesAction *action);

WB_PRIVATE
NSString *ITunesActionDescription(ITunesAction *action);
