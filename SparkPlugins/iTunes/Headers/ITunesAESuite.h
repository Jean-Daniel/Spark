/*
 *  iTunesAESuite.h
 *  Spark
 *
 *  Created by Fox on Sun Mar 07 2004.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */

#include <SparkKit/SparkKit.h>

#ifndef _iTUNES_SUITE_H_
#define _iTUNES_SUITE_H_

enum {
  kiTunesStateStopped		= 'kPSS',
  kiTunesStatePlaying		= 'kPSP',
  kiTunesStatePaused		= 'kPSp',
  kiTunesStateFastForward	= 'kPSF',
  kiTunesStateRewinding		= 'kPSR'
};

SK_PRIVATE
const OSType kITunesSignature;

SK_PRIVATE
OSStatus iTunesGetVisualState(Boolean *state);
SK_PRIVATE
OSStatus iTunesSetVisualState(Boolean state);

SK_PRIVATE
OSStatus iTunesGetVolume(SInt16 *volume);
SK_PRIVATE
OSStatus iTunesSetVolume(SInt16 volume);

SK_PRIVATE
CFArrayRef iTunesCopyPlaylists(void);
SK_PRIVATE
OSStatus   iTunesPlayPlaylist(CFStringRef name);

SK_PRIVATE
OSStatus iTunesGetPlayerState(OSType *state);
SK_PRIVATE
OSStatus iTunesRateCurrentSong(UInt16 rate);

SK_PRIVATE
CFDictionaryRef iTunesCopyCurrentTrackProperties(OSStatus *error);

#endif
