/*
 *  ITunesAESuite.c
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#include "ITunesAESuite.h"

#include <WonderBox/WBLSFunctions.h>

CFStringRef const kiTunesBundleIdentifier = CFSTR("com.apple.iTunes");

static 
CFArrayRef iTunesCopyPlaylistNamesFromList(AEDescList *items);

static
OSStatus iTunesReshufflePlaylist(iTunesPlaylist *playlist);

WB_INLINE
OSStatus _iTunesCreateEvent(AEEventClass class, AEEventID method, AppleEvent *event) {
  WBAEInitDesc(event);
  
  OSStatus err = WBAECreateEventWithTargetBundleID(kiTunesBundleIdentifier, class, method, event);
  spx_require_noerr(err, bail);
  
//  err = WBAESetStandardAttributes(event);
//  require_noerr(err, bail);
  
  return noErr;
bail:
	WBAEDisposeDesc(event);
  return err;
}

WB_INLINE
OSStatus _WBAESendEventReturnBool(AppleEvent* pAppleEvent, bool* pValue) {
  Boolean b;
  OSStatus err = WBAESendEventReturnBoolean(pAppleEvent, &b);
  if (noErr == err && pValue)
    *pValue = b;
  return err;
}

static
OSStatus _iTunesCopyObjectStringProperty(AEDesc *object, AEKeyword property, CFStringRef *value) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  /* ... 'property' of object 'object' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeUnicodeText, property, object);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventReturnString(&theEvent, value);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

static
OSStatus _iTunesGetObjectIntegerProperty(AEDesc *object, AEKeyword property, SInt32 *value) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  /* ... 'property' of track 'track' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeSInt32, property, object);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventReturnSInt32(&theEvent, value);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

#pragma mark -

#pragma mark iTunes Properties
OSStatus iTunesGetPlayerState(ITunesState *state) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pPlS', NULL);
  spx_require_noerr(err, bail);
	
  err = WBAESendEventReturnData(&theEvent, typeEnumerated, NULL, state, sizeof(OSType), NULL);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesGetPlayerPosition(UInt32 *position) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pPos', NULL);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventReturnUInt32(&theEvent, position);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesGetVisualEnabled(bool *state) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pVsE', NULL);
  spx_require_noerr(err, bail);
  
  err = _WBAESendEventReturnBool(&theEvent, state);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesSetVisualEnabled(bool state) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  spx_require_noerr(err, bail);
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVsE', NULL);
  spx_require_noerr(err, bail);
  
  err = WBAEAddBoolean(&theEvent, keyAEData, state);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventNoReply(&theEvent);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesIsMuted(bool *mute) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pMut', NULL);
  spx_require_noerr(err, bail);
  
  err = _WBAESendEventReturnBool(&theEvent, mute);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesSetMuted(bool mute) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  spx_require_noerr(err, bail);
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pMut', NULL);
  spx_require_noerr(err, bail);
  
	err = WBAEAddBoolean(&theEvent, keyAEData, mute); 
  spx_require_noerr(err, bail);
	
  err = WBAESendEventNoReply(&theEvent);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}


OSStatus iTunesGetSoundVolume(SInt16 *volume) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVol', NULL);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventReturnSInt16(&theEvent, volume);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}
OSStatus iTunesSetSoundVolume(SInt16 volume) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  spx_require_noerr(err, bail);
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVol', NULL);
  spx_require_noerr(err, bail);
  
  err = WBAEAddSInt16(&theEvent, keyAEData, volume); 
  spx_require_noerr(err, bail);
  
  err = WBAESendEventNoReply(&theEvent);
  spx_require_noerr(err, bail);
	
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesCopyCurrentStreamTitle(CFStringRef *title) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pStT', NULL);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventReturnString(&theEvent, title);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

#pragma mark -
OSStatus iTunesGetObjectType(AEDesc *obj, OSType *cls) {
  AEDesc reply = WBAEEmptyDesc();
  AppleEvent theEvent = WBAEEmptyDesc();
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  /* ... class of obj 'obj' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeType, pClass, obj);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventReturnAEDesc(&theEvent, typeType, &reply);
  spx_require_noerr(err, bail);
  
  err = AEGetDescData(&reply, cls, sizeof(*cls));
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  WBAEDisposeDesc(&reply);
  return err;
}

#pragma mark Tracks
OSStatus iTunesSetTrackRate(iTunesTrack *track, UInt32 rate) {
  AppleEvent theEvent;
  /* tell application "iTunes" to set ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  spx_require_noerr(err, bail);
  
  /* ... rate of track 'track' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeUInt32, kiTunesRateKey, track);
  spx_require_noerr(err, bail);
  
  /* ... to 'rate' */
  err = WBAEAddUInt32(&theEvent, keyAEData, rate);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventNoReply(&theEvent);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}
OSStatus iTunesGetTrackRate(iTunesTrack *track, UInt32 *rate) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  /* ... rate of track 'track' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeSInt16, kiTunesRateKey, track);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventReturnUInt32(&theEvent, rate);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesGetCurrentTrack(iTunesTrack *track) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  /* current track */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'cTrk', 'pTrk', NULL);
  spx_require_noerr(err, bail);
  
  /* Do not force return type to 'cTrk', because iTunes returns a 'cTrk' subclass */
  err = WBAESendEventReturnAEDesc(&theEvent, typeWildCard, track);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesSetCurrentTrackRate(UInt32 rate) {
  AEDesc track = WBAEEmptyDesc();
  
  ITunesState state;
  OSStatus err = iTunesGetPlayerState(&state);
  spx_require_noerr(err, bail);
  
  /* Does nothing if not playing */
  if (state == kiTunesStatePlaying) {
    err = iTunesGetCurrentTrack(&track);
    spx_require_noerr(err, bail);
    
    err = iTunesSetTrackRate(&track, rate);
    spx_require_noerr(err, bail);
  }
	
bail:
	WBAEDisposeDesc(&track);
  return err;
}

OSStatus iTunesCopyTrackStringProperty(iTunesTrack *track, ITunesTrackProperty property, CFStringRef *value) {
  return _iTunesCopyObjectStringProperty(track, property, value);
}

OSStatus iTunesCopyTrackArtworkData(iTunesTrack *track, CFDataRef *value, OSType *type) {
	AEDesc artwork = WBAEEmptyDesc();
	AppleEvent aevt = WBAEEmptyDesc();
	
	/* first artwork of the 'track' */
	OSStatus err = WBAECreateIndexObjectSpecifier('cArt', kAEFirst, track, &artwork);
	spx_require_noerr(err, bail);
	
  /* tell application "iTunes" to get ... */
  err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &aevt);
  spx_require_noerr(err, bail);
  
  /* ... 'data' of 'artwork' */
  err = WBAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, typePict, 'pPCT', &artwork);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventReturnCFData(&aevt, typeWildCard, type, value);
  // ignore no artwork error.
  //spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&artwork);
	WBAEDisposeDesc(&aevt);
  return err;
}

OSStatus iTunesGetTrackIntegerProperty(iTunesTrack *track, ITunesTrackProperty property, SInt32 *value) {
  return _iTunesGetObjectIntegerProperty(track, property, value);
}

#pragma mark -
#pragma mark Playlists
OSStatus iTunesPlayPlaylist(iTunesPlaylist *playlist) {
  AppleEvent theEvent = WBAEEmptyDesc();
  
  OSStatus err = iTunesReshufflePlaylist(playlist);
  spx_require_noerr(err, bail);
  
  err = _iTunesCreateEvent(kiTunesSuite, kiTunesCommandPlay, &theEvent);
  spx_require_noerr(err, bail);
  
  err = WBAEAddAEDesc(&theEvent, keyDirectObject, playlist);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventNoReply(&theEvent);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err; 
}

OSStatus iTunesPlayPlaylistWithID(SInt64 uid) {
  iTunesPlaylist playlist = WBAEEmptyDesc();
  
  OSStatus err = iTunesGetPlaylistWithID(uid, &playlist);
  spx_require_noerr(err, bail);
  
  err = iTunesPlayPlaylist(&playlist);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&playlist);
  return err; 
}

OSStatus iTunesPlayPlaylistWithName(CFStringRef name) {
  iTunesPlaylist playlist = WBAEEmptyDesc();
  
  OSStatus err = iTunesGetPlaylistWithName(name, &playlist);
  spx_require_noerr(err, bail);
  
  err = iTunesPlayPlaylist(&playlist);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&playlist);
  return err; 
}

OSStatus iTunesGetCurrentPlaylist(iTunesPlaylist *playlist) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  /* current playlist */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'cPly', 'pPla', NULL);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventReturnAEDesc(&theEvent, typeWildCard, playlist);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}


WB_INLINE
OSStatus __iTunesGetPlaylistUIDOperand(AEDesc *operand) {
  AEDesc obj = WBAEEmptyDesc();
  
  OSStatus err = AECreateDesc(typeObjectBeingExamined, NULL, 0, &obj);
  spx_require_noerr(err, bail);
  
  err = WBAECreatePropertyObjectSpecifier(typeProperty, kiTunesPersistentID, &obj, operand);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&obj);
  return err;
}

WB_INLINE
OSStatus __iTunesAddPlaylistSpecifier(AppleEvent *event, SInt64 uid) {
  AEDesc data = WBAEEmptyDesc();
  AEDesc object = WBAEEmptyDesc();
  AEDesc specifier = WBAEEmptyDesc();
  AEDesc comparaison = WBAEEmptyDesc();
  
  OSStatus err = __iTunesGetPlaylistUIDOperand(&object);
  spx_require_noerr(err, bail);
  
  err = AECreateDesc(typeSInt64, &uid, sizeof(uid), &data);
  spx_require_noerr(err, bail);
  
  err = CreateCompDescriptor(kAEEquals,
                             &object,
                             &data,
                             FALSE,
                             &comparaison);
  spx_require_noerr(err, bail);
  
  err = WBAECreateObjectSpecifier('cPly', formTest, &comparaison, NULL, &specifier);
  spx_require_noerr(err, bail);
  
  err = WBAEAddAEDesc(event, keyDirectObject, &specifier);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&comparaison);
  WBAEDisposeDesc(&specifier);
  WBAEDisposeDesc(&object);
  WBAEDisposeDesc(&data);
  return err;
}


OSStatus iTunesGetPlaylistWithID(SInt64 uid, iTunesPlaylist *playlist) {
  AppleEvent theEvent;
  AEDescList list = WBAEEmptyDesc();
  
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  /* ... playlists whose 'pPID' */
  err = __iTunesAddPlaylistSpecifier(&theEvent, uid);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventReturnAEDescList(&theEvent, &list);
  spx_require_noerr(err, bail);
  
  long count = 0;
  err = AECountItems(&list, &count);
  spx_require_noerr(err, bail);
  
  if (0 == count) {
    err = errAENoSuchObject;
  } else {
    err = AEGetNthDesc(&list, 1, typeWildCard, NULL, playlist);
    spx_require_noerr(err, bail);
  }
  
bail:
	WBAEDisposeDesc(&list);
  WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesGetPlaylistWithName(CFStringRef name, iTunesPlaylist *playlist) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  /* ... playlist "name" */
  err = WBAEAddNameObjectSpecifier(&theEvent, keyDirectObject, 'cPly', name, NULL);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventReturnAEDesc(&theEvent, typeWildCard, playlist);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesCopyPlaylistStringProperty(iTunesPlaylist *playlist, AEKeyword property, CFStringRef *value) {
  return _iTunesCopyObjectStringProperty(playlist, property, value);
}

OSStatus iTunesGetPlaylistIntegerProperty(iTunesPlaylist *playlist, AEKeyword property, SInt32 *value) {
  return _iTunesGetObjectIntegerProperty(playlist, property, value);
}

#pragma mark -
static
OSStatus iTunesGetPlaylistShuffle(iTunesPlaylist *playlist, bool *shuffle) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  /* ... shuffle of playlist 'playlist' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pShf', playlist);
  spx_require_noerr(err, bail);
  
  err = _WBAESendEventReturnBool(&theEvent, shuffle);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}
static
OSStatus iTunesSetPlaylistShuffle(iTunesPlaylist *playlist, bool shuffle) {
  AppleEvent theEvent;
  /* tell application "iTunes" to set ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  spx_require_noerr(err, bail);
  
  /* ... shuffle of playlist 'playlist' ... */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pShf', playlist);
  spx_require_noerr(err, bail);
  
  /* ... to 'shuffle' */
  err = WBAEAddBoolean(&theEvent, keyAEData, shuffle);
  spx_require_noerr(err, bail);
  
  err = WBAESendEventNoReply(&theEvent);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesReshufflePlaylist(iTunesPlaylist *playlist) {
  OSStatus err;
  bool shuffle;
  
  err = iTunesGetPlaylistShuffle(playlist, &shuffle);
  spx_require_noerr(err, bail);
  
  if (shuffle) {
    err = iTunesSetPlaylistShuffle(playlist, FALSE);
    spx_require_noerr(err, bail);
    
    err = iTunesSetPlaylistShuffle(playlist, TRUE);
    spx_require_noerr(err, bail);
  }
bail:
	return err;
}

#pragma mark -
WB_INLINE
OSStatus _iTunesGetLibrarySourceOperand(AEDesc *operand) {
  /* Prepare operand 1: kind of examined object */
  AEDesc obj = WBAEEmptyDesc();
  
  OSStatus err = AECreateDesc(typeObjectBeingExamined, NULL, 0, &obj);
  spx_require_noerr(err, bail);
  
  err = WBAECreatePropertyObjectSpecifier(typeProperty, 'pKnd', &obj, operand);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&obj);
  return err;
}

/* source whose kind is library => source where kind of examined object equals type 'kLib' */
static OSStatus _iTunesGetLibrarySources(AEDesc *sources) {
  /* Prepare operand 1: kind of examined object */
  AEDesc type = WBAEEmptyDesc();
  AEDesc property = WBAEEmptyDesc();
  AEDesc comparaison = WBAEEmptyDesc();
  
  OSStatus err = _iTunesGetLibrarySourceOperand(&property);
  spx_require_noerr(err, bail);
  
  OSType kind = 'kLib';
  err = AECreateDesc(typeType, &kind, sizeof(kind), &type);
  spx_require_noerr(err, bail);
  
  err = CreateCompDescriptor(kAEEquals,
                             &property,
                             &type,
                             FALSE,
                             &comparaison);
  spx_require_noerr(err, bail);
  
  err = WBAECreateObjectSpecifier('cSrc', formTest, &comparaison, NULL, sources);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&type);
  WBAEDisposeDesc(&property);
  WBAEDisposeDesc(&comparaison);
  return err;
}

static OSStatus iTunesGetLibrarySource(AEDesc *source) {
  AEDesc sources = WBAEEmptyDesc();
  
  OSStatus err = _iTunesGetLibrarySources(&sources);
  spx_require_noerr(err, bail);
  
  err = WBAECreateIndexObjectSpecifier('cSrc', 1, &sources, source);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&sources);
  return err;
}

WB_INLINE
OSStatus __iTunesGetEveryPlaylistObject(AEDesc *object) {
  AEDesc source = WBAEEmptyDesc();
  
  OSStatus err = iTunesGetLibrarySource(&source);
  spx_require_noerr(err, bail);
  
  /* every playlists of (first source whose kind is library) */
  err = WBAECreateIndexObjectSpecifier('cPly', kAEAll, &source, object);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&source);
  return err;
}

WB_INLINE
OSStatus __iTunesGetPlaylistsProperty(AEDesc *playlists, DescType type, AEKeyword property, AEDescList *properties) {
  AppleEvent theEvent = WBAEEmptyDesc();
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
	
  /* name of playlists */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, type, property, playlists);
  spx_require_noerr(err, bail);
	
  err = WBAESendEventReturnAEDescList(&theEvent, properties);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&theEvent);
  return err;
}

static
OSStatus _iTunesPlaylistIsSmart(UInt32 id, bool *smart) {
  AEDesc playlist = WBAEEmptyDesc();
  AppleEvent theEvent = WBAEEmptyDesc();
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  spx_require_noerr(err, bail);
  
  err = WBAECreateUniqueIDObjectSpecifier('cPly', id, NULL, &playlist);
  spx_require_noerr(err, bail);
  
  /* name of playlists */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeBoolean, 'pSmt', &playlist);
  spx_require_noerr(err, bail);
  
  err = _WBAESendEventReturnBool(&theEvent, smart);
  spx_require_noerr(err, bail);
  
bail:
	WBAEDisposeDesc(&playlist);
  WBAEDisposeDesc(&theEvent);
  return err;
}

CFArrayRef iTunesCopyPlaylistNames(void) {
  CFArrayRef result = NULL;
  AEDescList names = WBAEEmptyDesc();
  AEDesc playlists = WBAEEmptyDesc();
  
  OSStatus err = __iTunesGetEveryPlaylistObject(&playlists);
  spx_require_noerr(err, bail);
  
  err = __iTunesGetPlaylistsProperty(&playlists, typeUnicodeText, kiTunesNameKey, &names);
  spx_require_noerr(err, bail);
  
  result = iTunesCopyPlaylistNamesFromList(&names);
  
bail:
	WBAEDisposeDesc(&names);
  WBAEDisposeDesc(&playlists);
  return result;
}

CFArrayRef iTunesCopyPlaylistNamesFromList(AEDescList *items) {
  int idx;
  long listsCount;
  CFMutableArrayRef names = NULL;
  OSStatus err = AECountItems (items, &listsCount);
  
  if (noErr == err) {
    names = CFArrayCreateMutable(kCFAllocatorDefault, listsCount, &kCFTypeArrayCallBacks);
    for (idx = 1; (idx <= listsCount); idx++) {
      AEDesc listDesc;
      err = AEGetNthDesc(items, idx, typeWildCard, NULL, &listDesc);
      if (noErr == err) {
        CFStringRef name = NULL;
        if (noErr == WBAECopyStringFromDescriptor(&listDesc, &name) && name) {
          CFArrayAppendValue(names, name);
          CFRelease(name);
        }
        WBAEDisposeDesc(&listDesc);
      }
    } // End for
  }
  return names;
}

CFDictionaryRef iTunesCopyPlaylists(void) {
  CFMutableDictionaryRef result = NULL;
  
  AEDescList ids = WBAEEmptyDesc();
  AEDescList uids = WBAEEmptyDesc();
  AEDescList kinds = WBAEEmptyDesc();
  AEDescList names = WBAEEmptyDesc();
  
  AEDesc playlists = WBAEEmptyDesc();
  
  OSStatus err = __iTunesGetEveryPlaylistObject(&playlists);
  spx_require_noerr(err, bail);
	
  err = __iTunesGetPlaylistsProperty(&playlists, typeSInt32, 'ID  ', &ids);
  spx_require_noerr(err, bail);

  err = __iTunesGetPlaylistsProperty(&playlists, typeSInt64, kiTunesPersistentID, &uids);
  spx_require_noerr(err, bail);
  
  err = __iTunesGetPlaylistsProperty(&playlists, 'eSpK', 'pSpK', &kinds);
  spx_require_noerr(err, bail);
  
  err = __iTunesGetPlaylistsProperty(&playlists, typeUnicodeText, kiTunesNameKey, &names);
  spx_require_noerr(err, bail);
  
  long count = 0;
  err = AECountItems(&names, &count);
  if (noErr == err) {
    result = CFDictionaryCreateMutable(kCFAllocatorDefault, count, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    for (SInt32 idx = 1; (idx <= count); idx++) {
      SInt64 uid = 0;
      err = WBAEGetNthSInt64FromDescList(&uids, idx, &uid);
      if (noErr == err) {
        OSType type;
        err = AEGetNthPtr(&kinds, idx, typeWildCard, NULL, NULL, &type, sizeof(type), NULL);
        if (noErr == err) {
          SInt32 kind = kPlaylistUndefined;
          switch (type) {
            case 'kSpF':
              kind = kPlaylistFolder;
              break;
            case 'kSpZ':
              kind = kPlaylistMusic;
              break;
            case 'kSpI':
              kind = kPlaylistMovies;
              break;
							//            case 'kSpI':
							//              kind = kPlaylistTVShow:
              //              break;
            case 'kSpP':
              kind = kPlaylistPodcast;
              break;
            case 'kSpA':
              kind = kPlaylistBooks;
              break;
            case 'kSpM':
              kind = kPlaylistPurchased;
              break;
            case 'kNon': // modern iTunes version
            case 'kSpN': {
              // check if smart. 
              UInt32 id = 0;
              if (noErr == WBAEGetNthUInt32FromDescList(&ids, idx, &id)) {
                bool smart = false;
                err = _iTunesPlaylistIsSmart(id, &smart);
                if (noErr == err) {
                  kind = smart ? kPlaylistSmart : kPlaylistUser;
                } else {
                  err = noErr;
                }
              }
            }
              break;
            default:
              spx_debug("unsupported playlist type: %4.4s", (char *)&type);
              break;
          }
          if (kind != kPlaylistUndefined) {
            CFStringRef name = NULL;
            err = WBAECopyNthStringFromDescList(&names, idx, &name);
            if (noErr == err && name != NULL) {
              CFStringRef keys[] = { CFSTR("uid"), CFSTR("kind") };
              CFNumberRef numbers[2];
              numbers[0] = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &uid);
              numbers[1] = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &kind);
              if (numbers[0] && numbers[1]) {
                CFDictionaryRef entry = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)numbers, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
                if (entry) {
                  CFDictionarySetValue(result, name, entry);
                  CFRelease(entry);
                }
              }
              if (numbers[0]) CFRelease(numbers[0]);
              if (numbers[1]) CFRelease(numbers[1]);
              CFRelease(name);
            }
          }
        }
      }
    } // End for
  }
  
bail:
  WBAEDisposeDesc(&names);
  WBAEDisposeDesc(&kinds);
  WBAEDisposeDesc(&uids);
  WBAEDisposeDesc(&ids);
  WBAEDisposeDesc(&playlists);
  return result;
}
