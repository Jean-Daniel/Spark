/*
 *  ITunesAESuite.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#if !defined(__ITUNES_SUITE_H_)
#define __ITUNES_SUITE_H_ 1

#import <WonderBox/WonderBox.h>

enum {
  //  kiTunesSignature = 'hook',
  kiTunesSuite = 'hook',
};

SPX_PRIVATE
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

SPX_PRIVATE
OSStatus iTunesGetPlayerState(ITunesState *state);
SPX_PRIVATE
OSStatus iTunesGetPlayerPosition(uint32_t *position);

SPX_PRIVATE
OSStatus iTunesGetVisualEnabled(bool *state);
SPX_PRIVATE
OSStatus iTunesSetVisualEnabled(bool state);

SPX_PRIVATE
OSStatus iTunesIsMuted(bool *mute);
SPX_PRIVATE
OSStatus iTunesSetMuted(bool mute);

SPX_PRIVATE
OSStatus iTunesGetSoundVolume(int16_t *volume);
SPX_PRIVATE
OSStatus iTunesSetSoundVolume(int16_t volume);

SPX_PRIVATE
CFStringRef iTunesCopyCurrentStreamTitle(WBAEError error);

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
  kiTunesCategoryKey = 'pCat'
} ITunesTrackProperty;

SPX_INLINE
OSStatus iTunesSendCommand(ITunesCommand command, pid_t pid) {
  if (pid)
    return WBAESendSimpleEventTo(pid, kiTunesSuite, command);
  else
    return WBAESendSimpleEventToBundle(kiTunesBundleIdentifier, kiTunesSuite, command);
}

SPX_INLINE
OSStatus iTunesQuit(void) {
  return WBAESendSimpleEventToBundle(kiTunesBundleIdentifier, kCoreEventClass, kAEQuitApplication);
}

#pragma mark -
SPX_PRIVATE
OSStatus iTunesGetObjectType(AEDesc *obj, OSType *cls);

#pragma mark Tracks
SPX_PRIVATE
OSStatus iTunesGetCurrentTrack(iTunesTrack *track);

SPX_PRIVATE
OSStatus iTunesSetTrackRate(iTunesTrack *track, uint32_t rate);
SPX_PRIVATE
OSStatus iTunesGetTrackRate(iTunesTrack *track, uint32_t *rate);

SPX_PRIVATE
OSStatus iTunesSetCurrentTrackRate(uint32_t rate);

SPX_PRIVATE
CFDataRef iTunesCopyTrackArtworkData(iTunesTrack *track, OSType *type, WBAEError error);
SPX_PRIVATE
CFStringRef iTunesCopyTrackStringProperty(iTunesTrack *track, ITunesTrackProperty property, WBAEError error);
SPX_PRIVATE
OSStatus iTunesGetTrackIntegerProperty(iTunesTrack *track, ITunesTrackProperty property, int32_t *value);

#pragma mark -
#pragma mark Playlists
SPX_PRIVATE
CFArrayRef iTunesCopyPlaylistNames(WBAEError error);

SPX_PRIVATE
CFDictionaryRef iTunesCopyPlaylists(WBAEError error);

SPX_PRIVATE
OSStatus iTunesPlayPlaylist(iTunesPlaylist *playlist);
SPX_PRIVATE
OSStatus iTunesPlayPlaylistWithID(int64_t uid);
SPX_PRIVATE
OSStatus iTunesPlayPlaylistWithName(CFStringRef name);

SPX_PRIVATE
OSStatus iTunesGetCurrentPlaylist(iTunesPlaylist *playlist);
SPX_PRIVATE
OSStatus iTunesGetPlaylistWithID(int64_t uid, iTunesPlaylist *playlist);
SPX_PRIVATE
OSStatus iTunesGetPlaylistWithName(CFStringRef name, iTunesPlaylist *playlist);

SPX_PRIVATE
OSStatus iTunesGetPlaylistIntegerProperty(iTunesPlaylist *playlist, AEKeyword property, int32_t *value);
SPX_PRIVATE
CFStringRef iTunesCopyPlaylistStringProperty(iTunesPlaylist *playlist, AEKeyword property, WBAEError error);

#endif /* __ITUNES_SUITE_H_ */
