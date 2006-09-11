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
  kiTunesLaunch					= 'Laun', /* 1281455470 */
  kiTunesQuit						= 'Quit', /* 1366649204 */
  
  kiTunesStop						= 'Stop', /* 1400139632 */
  kiTunesPlayPause			= 'PlPs', /* 1349275763 */
  kiTunesBackTrack			= 'Back', /* 1113678699 */
  kiTunesNextTrack			= 'Next', /* 1315272820 */
  
  kiTunesRateTrack			= 'RaTr', /* 1382110322 */
  kiTunesPlayPlaylist		= 'PlPy', /* 1349275769 */
  kiTunesShowTrackInfo	= 'TrIn', /* 1416776046 */
  
  kiTunesVolumeUp				= 'VoUp', /* 1450136944 */
  kiTunesVolumeDown			= 'VoDo', /* 1450132591 */
  
  kiTunesVisual					= 'Visu', /* 1449751413 */
  kiTunesEjectCD				= 'Ejec', /* 1164600675 */
} iTunesAction;

typedef struct _ITunesVisual {
  float delay;
  NSPoint location;
  /* Colors */ 
  float text[4];
  float border[4];
  float backtop[4];
  float backbot[4];
} ITunesVisual;

SK_INLINE
UInt64 ITunesVisualPackColor(float color[4]) {
  UInt64 pack = 0;
  pack |= (llround(color[0] * 0xffff) & 0xffff) << 0;
  pack |= (llround(color[1] * 0xffff) & 0xffff) << 16;
  pack |= (llround(color[2] * 0xffff) & 0xffff) << 32;
  pack |= (llround(color[3] * 0xffff) & 0xffff) << 48;
  return pack;
}

SK_INLINE
void ITunesVisualUnpackColor(UInt64 pack, float color[4]) {
  color[0] = (double)((pack >> 0) & 0xffff) / 0xffff;
  color[1] = (double)((pack >> 16) & 0xffff) / 0xffff;
  color[2] = (double)((pack >> 32) & 0xffff) / 0xffff;
  color[3] = (double)((pack >> 48) & 0xffff) / 0xffff;
}

@interface ITunesAction : SparkAction <NSCoding, NSCopying> {
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
  
  ITunesVisual *visual;
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
