/*
 *  ITunesAESuite.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#if !defined(__ITUNES_SUITE_H_)
#define __ITUNES_SUITE_H_ 1

#include WBHEADER(WBAEFunctions.h)

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


WB_PRIVATE
Boolean iTunesIsRunning(ProcessSerialNumber *proc);

WB_PRIVATE
OSStatus iTunesGetPlayerState(ITunesState *state);
WB_PRIVATE
OSStatus iTunesGetPlayerPosition(UInt32 *position);

WB_PRIVATE
OSStatus iTunesGetVisualEnabled(Boolean *state);
WB_PRIVATE
OSStatus iTunesSetVisualEnabled(Boolean state);

WB_PRIVATE
OSStatus iTunesGetSoundVolume(SInt16 *volume);
WB_PRIVATE
OSStatus iTunesSetSoundVolume(SInt16 volume);

WB_PRIVATE
OSStatus iTunesCopyCurrentStreamTitle(CFStringRef *title);

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

WB_INLINE
OSStatus iTunesSendCommand(ITunesCommand command) {
  return WBAESendSimpleEvent(kiTunesSignature, kiTunesSuite, command);
}

WB_INLINE
OSStatus iTunesQuit(void) {
  return WBAESendSimpleEvent(kiTunesSignature, kCoreEventClass, kAEQuitApplication);
}
WB_PRIVATE
OSStatus iTunesLaunch(LSLaunchFlags flags);

#pragma mark -
WB_PRIVATE
OSStatus iTunesGetObjectType(AEDesc *obj, OSType *cls);

#pragma mark Tracks
WB_PRIVATE
OSStatus iTunesGetCurrentTrack(iTunesTrack *track);

WB_PRIVATE
OSStatus iTunesSetTrackRate(iTunesTrack *track, UInt32 rate);
WB_PRIVATE
OSStatus iTunesGetTrackRate(iTunesTrack *track, UInt32 *rate);

WB_PRIVATE
OSStatus iTunesSetCurrentTrackRate(UInt32 rate);

WB_PRIVATE
OSStatus iTunesCopyTrackStringProperty(iTunesTrack *track, ITunesTrackProperty property, CFStringRef *value);
WB_PRIVATE
OSStatus iTunesGetTrackIntegerProperty(iTunesTrack *track, ITunesTrackProperty property, SInt32 *value);

#pragma mark -
#pragma mark Playlists
WB_PRIVATE
CFArrayRef iTunesCopyPlaylistNames(void);

WB_PRIVATE
CFDictionaryRef iTunesCopyPlaylists(void);

WB_PRIVATE
OSStatus iTunesPlayPlaylist(iTunesPlaylist *playlist);
WB_PRIVATE
OSStatus iTunesPlayPlaylistWithID(SInt64 uid);
WB_PRIVATE
OSStatus iTunesPlayPlaylistWithName(CFStringRef name);

WB_PRIVATE
OSStatus iTunesGetCurrentPlaylist(iTunesPlaylist *playlist);
WB_PRIVATE
OSStatus iTunesGetPlaylistWithID(SInt64 uid, iTunesPlaylist *playlist);
WB_PRIVATE
OSStatus iTunesGetPlaylistWithName(CFStringRef name, iTunesPlaylist *playlist);

WB_PRIVATE
OSStatus iTunesGetPlaylistIntegerProperty(iTunesPlaylist *playlist, AEKeyword property, SInt32 *value);
WB_PRIVATE
OSStatus iTunesCopyPlaylistStringProperty(iTunesPlaylist *playlist, AEKeyword property, CFStringRef *value);

#endif /* __ITUNES_SUITE_H_ */
