/*
 *  ITunesAESuite.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#if !defined(__ITUNES_SUITE_H_)
#define __ITUNES_SUITE_H_ 1

#include <WonderBox/WBAEFunctions.h>

#pragma mark -
enum {
  //  kiTunesSignature = 'hook',
  kiTunesSuite = 'hook',
};

WB_PRIVATE
CFStringRef const kiTunesBundleIdentifier;

enum {
  kPlaylistUndefined = -1,
  kPlaylistBooks = 0, // kSpA
  kPlaylistFolder, // kSpF
  kPlaylistGenius, // kSpG
  kPlaylistiTunesU, // kSpU
  kPlaylistLibrary, // kSpL
  kPlaylistMovies, // kSpI
  kPlaylistMusic, // kSpZ
  kPlaylistPodcast, // kSpP
  kPlaylistPurchased, // kSpM
  kPlaylistTVShow, // kSpT
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
OSStatus iTunesGetPlayerState(ITunesState *state);
WB_PRIVATE
OSStatus iTunesGetPlayerPosition(uint32_t *position);

WB_PRIVATE
OSStatus iTunesGetVisualEnabled(bool *state);
WB_PRIVATE
OSStatus iTunesSetVisualEnabled(bool state);

WB_PRIVATE
OSStatus iTunesIsMuted(bool *mute);
WB_PRIVATE
OSStatus iTunesSetMuted(bool mute);

WB_PRIVATE
OSStatus iTunesGetSoundVolume(int16_t *volume);
WB_PRIVATE
OSStatus iTunesSetSoundVolume(int16_t volume);

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
OSStatus iTunesSendCommand(ITunesCommand command, pid_t pid) {
  if (pid)
    return WBAESendSimpleEventTo(pid, kiTunesSuite, command);
  else
    return WBAESendSimpleEventToBundle(kiTunesBundleIdentifier, kiTunesSuite, command);
}

WB_INLINE
OSStatus iTunesQuit(void) {
  return WBAESendSimpleEventToBundle(kiTunesBundleIdentifier, kCoreEventClass, kAEQuitApplication);
}

#pragma mark -
WB_PRIVATE
OSStatus iTunesGetObjectType(AEDesc *obj, OSType *cls);

#pragma mark Tracks
WB_PRIVATE
OSStatus iTunesGetCurrentTrack(iTunesTrack *track);

WB_PRIVATE
OSStatus iTunesSetTrackRate(iTunesTrack *track, uint32_t rate);
WB_PRIVATE
OSStatus iTunesGetTrackRate(iTunesTrack *track, uint32_t *rate);

WB_PRIVATE
OSStatus iTunesSetCurrentTrackRate(uint32_t rate);

WB_PRIVATE
OSStatus iTunesCopyTrackArtworkData(iTunesTrack *track, CFDataRef *value, OSType *type);
WB_PRIVATE
OSStatus iTunesCopyTrackStringProperty(iTunesTrack *track, ITunesTrackProperty property, CFStringRef *value);
WB_PRIVATE
OSStatus iTunesGetTrackIntegerProperty(iTunesTrack *track, ITunesTrackProperty property, int32_t *value);

#pragma mark -
#pragma mark Playlists
WB_PRIVATE
CFArrayRef iTunesCopyPlaylistNames(void);

WB_PRIVATE
CFDictionaryRef iTunesCopyPlaylists(void);

WB_PRIVATE
OSStatus iTunesPlayPlaylist(iTunesPlaylist *playlist);
WB_PRIVATE
OSStatus iTunesPlayPlaylistWithID(int64_t uid);
WB_PRIVATE
OSStatus iTunesPlayPlaylistWithName(CFStringRef name);

WB_PRIVATE
OSStatus iTunesGetCurrentPlaylist(iTunesPlaylist *playlist);
WB_PRIVATE
OSStatus iTunesGetPlaylistWithID(int64_t uid, iTunesPlaylist *playlist);
WB_PRIVATE
OSStatus iTunesGetPlaylistWithName(CFStringRef name, iTunesPlaylist *playlist);

WB_PRIVATE
OSStatus iTunesGetPlaylistIntegerProperty(iTunesPlaylist *playlist, AEKeyword property, int32_t *value);
WB_PRIVATE
OSStatus iTunesCopyPlaylistStringProperty(iTunesPlaylist *playlist, AEKeyword property, CFStringRef *value);

#endif /* __ITUNES_SUITE_H_ */
