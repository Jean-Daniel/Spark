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

extern const OSType kITunesSignature;

extern OSStatus iTunesGetVisualState(Boolean *state);
extern OSStatus iTunesSetVisualState(Boolean state);

extern OSStatus iTunesGetVolume(SInt16 *volume);
extern OSStatus iTunesSetVolume(SInt16 volume);

extern CFArrayRef iTunesGetPlaylists();
extern OSStatus   iTunesPlayPlaylist(CFStringRef name);

extern OSStatus iTunesGetPlayerState(OSType *state);
extern OSStatus iTunesRateCurrentSong(UInt16 rate);
#endif
