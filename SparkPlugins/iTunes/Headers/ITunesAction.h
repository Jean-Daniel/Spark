//
//  ITunesAction.h
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
  kiTunesShowTrackInfo	= 12,
} iTunesAction;

@class SKBezelItem;
@interface ITunesAction : SparkAction <NSCoding, NSCopying> {
  IBOutlet NSTextField *track;
  IBOutlet NSTextField *artist;
  IBOutlet NSTextField *album;
  IBOutlet NSImageView *artwork;
  
  @private
    iTunesAction ia_action;
  NSString *ia_playlist;
  
  struct _ia_iaFlags {
    unsigned int rate:7; /* 0 to 100 */
    /* launch flags */
    unsigned int autoplay:1;
    unsigned int background:1;
    /* visuals settings */
    unsigned int visual:2; /* visual type: none, default, custom */
    unsigned int reserved:21;
  } ia_iaFlags;
}

- (SInt16)rating;
- (void)setRating:(SInt16)aRate;

- (NSString *)playlist;
- (void)setPlaylist:(NSString *)newPlaylist;

- (iTunesAction)iTunesAction;
- (void)setITunesAction:(iTunesAction)newAction;

- (void)switchVisualStat;
- (void)volumeUp;
- (void)volumeDown;
- (void)ejectCD;
- (SparkAlert *)playPlaylist:(NSString *)name;

@end
