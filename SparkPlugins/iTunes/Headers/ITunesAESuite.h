/*
 *  ITunesAESuite.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#if !defined(__ITUNES_SUITE_H_)
#define __ITUNES_SUITE_H_ 1

#include <ShadowKit/SKAEFunctions.h>

#pragma mark -
enum {
  kiTunesSignature = 'hook',
  kiTunesSuite = 'hook',
};

enum {
  kPlaylistUndefined = -1,
  kPlaylistMusic = 0,
  kPlaylistMovie,
  kPlaylistTVShow,
  kPlaylistPodcast,
  kPlaylistBooks,
  kPlaylistPurchased,
  kPlaylistPartyShuffle,
  kPlaylistFolder,
  kPlaylistSmart,
  kPlaylistUser,
};

typedef AEDesc iTunesTrack;
typedef AEDesc iTunesPlaylist;

#pragma mark -
#pragma mark iTunes Properties
typedef enum {
  kiTunesStateStopped		= 'kPSS',
  kiTunesStatePlaying		= 'kPSP',
  kiTunesStatePaused		= 'kPSp',
  kiTunesStateFastForward	= 'kPSF',
  kiTunesStateRewinding		= 'kPSR'
} ITunesState;


SK_PRIVATE
Boolean iTunesIsRunning(ProcessSerialNumber *proc);

SK_PRIVATE
OSStatus iTunesGetPlayerState(ITunesState *state);

SK_PRIVATE
OSStatus iTunesGetVisualEnabled(Boolean *state);
SK_PRIVATE
OSStatus iTunesSetVisualEnabled(Boolean state);

SK_PRIVATE
OSStatus iTunesGetSoundVolume(SInt16 *volume);
SK_PRIVATE
OSStatus iTunesSetSoundVolume(SInt16 volume);

#pragma mark Commands
typedef enum {
  kiTunesCommandPlay			= 'Play',
  kiTunesCommandPlayPause 		= 'PlPs',
  kiTunesCommandNextTrack 		= 'Next',
  kiTunesCommandPreviousTrack 	= 'Back',
  kiTunesCommandStopPlaying 	= 'Stop',
} ITunesCommand;

typedef enum {
  kiTunesRateKey = 'pRte',
  kiTunesNameKey = 'pnam',
  kiTunesAlbumKey = 'pAlb',
  kiTunesArtistKey = 'pArt',
  kiTunesDurationKey = 'pDur',
  kiTunesPersistentID = 'pPID',
} ITunesTrackProperty;

SK_INLINE
OSStatus iTunesSendCommand(ITunesCommand command) {
  return SKAESendSimpleEvent(kiTunesSignature, kiTunesSuite, command);
}

SK_INLINE
OSStatus iTunesQuit(void) {
  return SKAESendSimpleEvent(kiTunesSignature, kCoreEventClass, kAEQuitApplication);
}
SK_PRIVATE
OSStatus iTunesLaunch(LSLaunchFlags flags);

#pragma mark -
#pragma mark Tracks
SK_PRIVATE
OSStatus iTunesGetCurrentTrack(iTunesTrack *track);

SK_PRIVATE
OSStatus iTunesSetTrackRate(iTunesTrack *track, UInt32 rate);
SK_PRIVATE
OSStatus iTunesGetTrackRate(iTunesTrack *track, UInt32 *rate);

SK_PRIVATE
OSStatus iTunesSetCurrentTrackRate(UInt32 rate);

SK_PRIVATE
OSStatus iTunesCopyTrackStringProperty(iTunesTrack *track, ITunesTrackProperty property, CFStringRef *value);
SK_PRIVATE
OSStatus iTunesGetTrackIntegerProperty(iTunesTrack *track, ITunesTrackProperty property, SInt32 *value);

#pragma mark -
#pragma mark Playlists
SK_PRIVATE
CFArrayRef iTunesCopyPlaylistNames(void);

SK_PRIVATE
CFDictionaryRef iTunesCopyPlaylists(void);

SK_PRIVATE
OSStatus iTunesPlayPlaylist(iTunesPlaylist *playlist);
SK_PRIVATE
OSStatus iTunesPlayPlaylistWithID(SInt64 uid);
SK_PRIVATE
OSStatus iTunesPlayPlaylistWithName(CFStringRef name);

SK_PRIVATE
OSStatus iTunesGetCurrentPlaylist(iTunesPlaylist *playlist);
SK_PRIVATE
OSStatus iTunesGetPlaylistWithID(SInt64 uid, iTunesPlaylist *playlist);
SK_PRIVATE
OSStatus iTunesGetPlaylistWithName(CFStringRef name, iTunesPlaylist *playlist);

SK_PRIVATE
OSStatus iTunesGetPlaylistIntegerProperty(iTunesPlaylist *playlist, AEKeyword property, SInt32 *value);
SK_PRIVATE
OSStatus iTunesCopyPlaylistStringProperty(iTunesPlaylist *playlist, AEKeyword property, CFStringRef *value);

#endif /* __ITUNES_SUITE_H_ */
