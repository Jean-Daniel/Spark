/*
 *  ITunesAESuite.c
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#include "ITunesAESuite.h"

CFStringRef const kiTunesBundleIdentifier = CFSTR("com.apple.iTunes");

static 
CFArrayRef iTunesCopyPlaylistNamesFromList(AEDescList *items, WBAEError error);

static
OSStatus iTunesReshufflePlaylist(iTunesPlaylist *playlist);

WB_INLINE
OSStatus _iTunesCreateEvent(AEEventClass cls, AEEventID method, AppleEvent *event) {
  return WBAECreateEventWithTargetBundleID(kiTunesBundleIdentifier, cls, method, event);
}

WB_INLINE
OSStatus _WBAESendEventReturnBool(AppleEvent* pAppleEvent, bool* pValue) {
  Boolean b;
  OSStatus err = WBAESendEventReturnBoolean(pAppleEvent, &b);
  if (noErr == err && pValue)
    *pValue = b != FALSE;
  return err;
}

static
CFStringRef _iTunesCopyObjectStringProperty(AEDesc *object, AEKeyword property, WBAEError pError) {
  wb::AppleEvent theEvent;
  wb::AEError<CFStringRef> res(pError);
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err)
    return res(err);
  
  /* ... 'property' of object 'object' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeUnicodeText, property, object);
  if (noErr != err)
    return res(err);
  
  return WBAESendEventReturnString(&theEvent, pError);
}

static
OSStatus _iTunesGetObjectIntegerProperty(AEDesc *object, AEKeyword property, SInt32 *value) {
  wb::AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  /* ... 'property' of track 'track' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeSInt32, property, object);
  if (noErr != err) return err;
  
  return WBAESendEventReturnSInt32(&theEvent, value);
}

#pragma mark -

#pragma mark iTunes Properties
OSStatus iTunesGetPlayerState(ITunesState *state) {
  wb::AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pPlS', NULL);
  if (noErr != err) return err;
	
  return WBAESendEventReturnData(&theEvent, typeEnumerated, NULL, state, sizeof(OSType), NULL);
}

OSStatus iTunesGetPlayerPosition(UInt32 *position) {
  wb::AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pPos', NULL);
  if (noErr != err) return err;
  
  return WBAESendEventReturnUInt32(&theEvent, position);
}

OSStatus iTunesGetVisualEnabled(bool *state) {
  wb::AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pVsE', NULL);
  if (noErr != err) return err;
  
  return _WBAESendEventReturnBool(&theEvent, state);
}

OSStatus iTunesSetVisualEnabled(bool state) {
  wb::AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  if (noErr != err) return err;
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVsE', NULL);
  if (noErr != err) return err;
  
  err = WBAEAddBoolean(&theEvent, keyAEData, state);
  if (noErr != err) return err;
  
  return WBAESendEventNoReply(&theEvent);
}

OSStatus iTunesIsMuted(bool *mute) {
  wb::AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pMut', NULL);
  if (noErr != err) return err;
  
  return _WBAESendEventReturnBool(&theEvent, mute);
}

OSStatus iTunesSetMuted(bool mute) {
  wb::AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  if (noErr != err) return err;
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pMut', NULL);
  if (noErr != err) return err;
  
	err = WBAEAddBoolean(&theEvent, keyAEData, mute); 
  if (noErr != err) return err;
	
  return WBAESendEventNoReply(&theEvent);
}

OSStatus iTunesGetSoundVolume(SInt16 *volume) {
  wb::AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVol', NULL);
  if (noErr != err) return err;
  
  return WBAESendEventReturnSInt16(&theEvent, volume);
}

OSStatus iTunesSetSoundVolume(SInt16 volume) {
  wb::AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  if (noErr != err) return err;
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVol', NULL);
  if (noErr != err) return err;
  
  err = WBAEAddSInt16(&theEvent, keyAEData, volume); 
  if (noErr != err) return err;
  
  return WBAESendEventNoReply(&theEvent);
}

CFStringRef iTunesCopyCurrentStreamTitle(WBAEError error) {
  wb::AppleEvent theEvent;
  wb::AEError<CFStringRef> res(error);
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return res(err);
  
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pStT', NULL);
  if (noErr != err) return res(err);
  
  return WBAESendEventReturnString(&theEvent, error);
}

#pragma mark -
OSStatus iTunesGetObjectType(AEDesc *obj, OSType *cls) {
  wb::AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  /* ... class of obj 'obj' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeType, pClass, obj);
  if (noErr != err) return err;

  wb::AEDesc reply;
  err = WBAESendEventReturnAEDesc(&theEvent, typeType, &reply);
  if (noErr != err) return err;
  
  return AEGetDescData(&reply, cls, sizeof(*cls));
}

#pragma mark Tracks
OSStatus iTunesSetTrackRate(iTunesTrack *track, UInt32 rate) {
  wb::AppleEvent theEvent;
  /* tell application "iTunes" to set ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  if (noErr != err) return err;
  
  /* ... rate of track 'track' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeUInt32, kiTunesRateKey, track);
  if (noErr != err) return err;
  
  /* ... to 'rate' */
  err = WBAEAddUInt32(&theEvent, keyAEData, rate);
  if (noErr != err) return err;
  
  return WBAESendEventNoReply(&theEvent);
}

OSStatus iTunesGetTrackRate(iTunesTrack *track, UInt32 *rate) {
  wb::AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  /* ... rate of track 'track' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeSInt16, kiTunesRateKey, track);
  if (noErr != err) return err;
  
  return WBAESendEventReturnUInt32(&theEvent, rate);
}

OSStatus iTunesGetCurrentTrack(iTunesTrack *track) {
  wb::AppleEvent theEvent;
  /* tell application "iTunes" to get... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  /* current track */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'cTrk', 'pTrk', NULL);
  if (noErr != err) return err;
  
  /* Do not force return type to 'cTrk', because iTunes returns a 'cTrk' subclass */
  return WBAESendEventReturnAEDesc(&theEvent, typeWildCard, track);
}

OSStatus iTunesSetCurrentTrackRate(UInt32 rate) {
  wb::AEDesc track;
  
  ITunesState state;
  OSStatus err = iTunesGetPlayerState(&state);
  if (noErr != err || state != kiTunesStatePlaying) return err;
  
  /* Does nothing if not playing */
  err = iTunesGetCurrentTrack(&track);
  if (noErr != err) return err;

  return iTunesSetTrackRate(&track, rate);
}

CFStringRef iTunesCopyTrackStringProperty(iTunesTrack *track, ITunesTrackProperty property, WBAEError error) {
  return _iTunesCopyObjectStringProperty(track, property, error);
}

CFDataRef iTunesCopyTrackArtworkData(iTunesTrack *track, OSType *type, WBAEError error) {
  wb::AEError<CFDataRef> res(error);

	/* first artwork of the 'track' */
  wb::AEDesc artwork;
	OSStatus err = WBAECreateIndexObjectSpecifier('cArt', kAEFirst, track, &artwork);
	if (noErr != err) return res(err);
	
  /* tell application "iTunes" to get ... */
  wb::AppleEvent aevt;
  err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &aevt);
  if (noErr != err) return res(err);
  
  /* ... 'data' of 'artwork' */
  err = WBAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, typePict, 'pPCT', &artwork);
  if (noErr != err) return res(err);
  
  return WBAESendEventReturnCFData(&aevt, typeWildCard, type, error);
}

OSStatus iTunesGetTrackIntegerProperty(iTunesTrack *track, ITunesTrackProperty property, SInt32 *value) {
  return _iTunesGetObjectIntegerProperty(track, property, value);
}

#pragma mark -
#pragma mark Playlists
OSStatus iTunesPlayPlaylist(iTunesPlaylist *playlist) {
  OSStatus err = iTunesReshufflePlaylist(playlist);
  if (noErr != err) return err;

  wb::AppleEvent theEvent;
  err = _iTunesCreateEvent(kiTunesSuite, kiTunesCommandPlay, &theEvent);
  if (noErr != err) return err;
  
  err = WBAEAddAEDesc(&theEvent, keyDirectObject, playlist);
  if (noErr != err) return err;
  
  return WBAESendEventNoReply(&theEvent);
}

OSStatus iTunesPlayPlaylistWithID(SInt64 uid) {
  wb::AEDesc playlist; // iTunesPlaylist
  
  OSStatus err = iTunesGetPlaylistWithID(uid, &playlist);
  if (noErr != err) return err;
  
  return iTunesPlayPlaylist(&playlist);
}

OSStatus iTunesPlayPlaylistWithName(CFStringRef name) {
  wb::AEDesc playlist; // iTunesPlaylist
  
  OSStatus err = iTunesGetPlaylistWithName(name, &playlist);
  if (noErr != err) return err;
  
  return iTunesPlayPlaylist(&playlist);
}

OSStatus iTunesGetCurrentPlaylist(iTunesPlaylist *playlist) {
  wb::AppleEvent theEvent;
  /* tell application "iTunes" to get... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  /* current playlist */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'cPly', 'pPla', NULL);
  if (noErr != err) return err;
  
  return WBAESendEventReturnAEDesc(&theEvent, typeWildCard, playlist);
}

WB_INLINE
OSStatus __iTunesGetPlaylistUIDOperand(AEDesc *operand) {
  wb::AEDesc obj;
  
  OSStatus err = AECreateDesc(typeObjectBeingExamined, NULL, 0, &obj);
  if (noErr != err) return err;
  
  return WBAECreatePropertyObjectSpecifier(typeProperty, kiTunesPersistentID, &obj, operand);
}

WB_INLINE
OSStatus __iTunesAddPlaylistSpecifier(AppleEvent *event, SInt64 uid) {
  wb::AEDesc object;
  OSStatus err = __iTunesGetPlaylistUIDOperand(&object);
  if (noErr != err) return err;

  wb::AEDesc data;
  err = AECreateDesc(typeSInt64, &uid, sizeof(uid), &data);
  if (noErr != err) return err;

  wb::AEDesc comparaison;
  err = CreateCompDescriptor(kAEEquals, &object, &data, false, &comparaison);
  if (noErr != err) return err;

  wb::AEDesc specifier;
  err = WBAECreateObjectSpecifier('cPly', formTest, &comparaison, NULL, &specifier);
  if (noErr != err) return err;

  return WBAEAddAEDesc(event, keyDirectObject, &specifier);
}

OSStatus iTunesGetPlaylistWithID(SInt64 uid, iTunesPlaylist *playlist) {
  /* tell application "iTunes" to get ... */
  wb::AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  /* ... playlists whose 'pPID' */
  err = __iTunesAddPlaylistSpecifier(&theEvent, uid);
  if (noErr != err) return err;

  wb::AEDescList list;
  err = WBAESendEventReturnAEDescList(&theEvent, &list);
  if (noErr != err) return err;
  
  long count = 0;
  err = AECountItems(&list, &count);
  if (noErr != err) return err;
  
  if (0 == count)
    return errAENoSuchObject;

  return AEGetNthDesc(&list, 1, typeWildCard, NULL, playlist);
}

OSStatus iTunesGetPlaylistWithName(CFStringRef name, iTunesPlaylist *playlist) {
  wb::AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  /* ... playlist "name" */
  err = WBAEAddNameObjectSpecifier(&theEvent, keyDirectObject, 'cPly', name, nullptr);
  if (noErr != err) return err;
  
  return WBAESendEventReturnAEDesc(&theEvent, typeWildCard, playlist);
}

CFStringRef iTunesCopyPlaylistStringProperty(iTunesPlaylist *playlist, AEKeyword property, WBAEError error) {
  return _iTunesCopyObjectStringProperty(playlist, property, error);
}

OSStatus iTunesGetPlaylistIntegerProperty(iTunesPlaylist *playlist, AEKeyword property, SInt32 *value) {
  return _iTunesGetObjectIntegerProperty(playlist, property, value);
}

#pragma mark -
static
OSStatus iTunesGetPlaylistShuffle(iTunesPlaylist *playlist, bool *shuffle) {
  wb::AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
  
  /* ... shuffle of playlist 'playlist' */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pShf', playlist);
  if (noErr != err) return err;
  
  return _WBAESendEventReturnBool(&theEvent, shuffle);
}

static
OSStatus iTunesSetPlaylistShuffle(iTunesPlaylist *playlist, bool shuffle) {
  wb::AppleEvent theEvent;
  /* tell application "iTunes" to set ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  if (noErr != err) return err;
  
  /* ... shuffle of playlist 'playlist' ... */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pShf', playlist);
  if (noErr != err) return err;
  
  /* ... to 'shuffle' */
  err = WBAEAddBoolean(&theEvent, keyAEData, shuffle);
  if (noErr != err) return err;
  
  return WBAESendEventNoReply(&theEvent);
}

OSStatus iTunesReshufflePlaylist(iTunesPlaylist *playlist) {
  bool shuffle;
  OSStatus err = iTunesGetPlaylistShuffle(playlist, &shuffle);
  if (noErr != err) return err;
  
  if (!shuffle)
    return noErr;

  err = iTunesSetPlaylistShuffle(playlist, false);
  if (noErr != err) return err;
    
  return iTunesSetPlaylistShuffle(playlist, true);
}

#pragma mark -
WB_INLINE
OSStatus _iTunesGetLibrarySourceOperand(AEDesc *operand) {
  /* Prepare operand 1: kind of examined object */
  wb::AEDesc obj;
  OSStatus err = AECreateDesc(typeObjectBeingExamined, NULL, 0, &obj);
  if (noErr != err) return err;
  
  return WBAECreatePropertyObjectSpecifier(typeProperty, 'pKnd', &obj, operand);
}

/* source whose kind is library => source where kind of examined object equals type 'kLib' */
static
OSStatus _iTunesGetLibrarySources(AEDesc *sources) {
  /* Prepare operand 1: kind of examined object */
  wb::AEDesc property;
  OSStatus err = _iTunesGetLibrarySourceOperand(&property);
  if (noErr != err) return err;

  wb::AEDesc type;
  OSType kind = 'kLib';
  err = AECreateDesc(typeType, &kind, sizeof(kind), &type);
  if (noErr != err) return err;

  wb::AEDesc comparaison;
  err = CreateCompDescriptor(kAEEquals, &property, &type, false, &comparaison);
  if (noErr != err) return err;
  
  return WBAECreateObjectSpecifier('cSrc', formTest, &comparaison, NULL, sources);
}

static OSStatus iTunesGetLibrarySource(AEDesc *source) {
  wb::AEDesc sources;
  OSStatus err = _iTunesGetLibrarySources(&sources);
  if (noErr != err) return err;
  
  return WBAECreateIndexObjectSpecifier('cSrc', 1, &sources, source);
}

WB_INLINE
OSStatus __iTunesGetEveryPlaylistObject(AEDesc *object) {
  wb::AEDesc source;
  OSStatus err = iTunesGetLibrarySource(&source);
  if (noErr != err) return err;
  
  /* every playlists of (first source whose kind is library) */
  return WBAECreateIndexObjectSpecifier('cPly', kAEAll, &source, object);
}

WB_INLINE
OSStatus __iTunesGetPlaylistsProperty(AEDesc *playlists, DescType type, AEKeyword property, AEDescList *properties) {
  wb::AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;
	
  /* name of playlists */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, type, property, playlists);
  if (noErr != err) return err;
	
  return WBAESendEventReturnAEDescList(&theEvent, properties);
}

static
OSStatus _iTunesPlaylistIsSmart(UInt32 id, bool *smart) {
  /* tell application "iTunes" to get ... */
  wb::AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  if (noErr != err) return err;

  wb::AEDesc playlist;
  err = WBAECreateUniqueIDObjectSpecifier('cPly', id, NULL, &playlist);
  if (noErr != err) return err;
  
  /* name of playlists */
  err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeBoolean, 'pSmt', &playlist);
  if (noErr != err) return err;
  
  return _WBAESendEventReturnBool(&theEvent, smart);
}

CFArrayRef iTunesCopyPlaylistNames(WBAEError error) {
  wb::AEError<CFArrayRef> res(error);

  wb::AEDesc playlists;
  OSStatus err = __iTunesGetEveryPlaylistObject(&playlists);
  if (noErr != err) return res(err);

  wb::AEDescList names;
  err = __iTunesGetPlaylistsProperty(&playlists, typeUnicodeText, kiTunesNameKey, &names);
  if (noErr != err) return res(err);
  
  return iTunesCopyPlaylistNamesFromList(&names, error);
}

CFArrayRef iTunesCopyPlaylistNamesFromList(AEDescList *items, WBAEError error) {
  wb::AEError<CFArrayRef> res(error);

  long listsCount;
  OSStatus err = AECountItems(items, &listsCount);
  if (noErr != err)
    return res(err);

  CFMutableArrayRef names = CFArrayCreateMutable(kCFAllocatorDefault, listsCount, &kCFTypeArrayCallBacks);
  for (long idx = 1; idx <= listsCount; ++idx) {
    wb::AEDesc listDesc;
    err = AEGetNthDesc(items, idx, typeWildCard, NULL, &listDesc);
    if (noErr != err) {
      spx_log("get track %ld returned %d", idx, err);
      continue;
    }

    spx::unique_cfptr<CFStringRef> name(WBAECopyStringFromDescriptor(&listDesc, &err));
    if (name) {
      CFArrayAppendValue(names, name.get());
    } else {
      spx_log("get track %ld name returned %d", idx, err);
    }
  } // End for

  return names;
}

CFDictionaryRef iTunesCopyPlaylists(WBAEError error) {
  wb::AEError<CFDictionaryRef> res(error);
  
  wb::AEDesc playlists;
  OSStatus err = __iTunesGetEveryPlaylistObject(&playlists);
  if (noErr != err) return res(err);

  wb::AEDescList ids;
  err = __iTunesGetPlaylistsProperty(&playlists, typeSInt32, 'ID  ', &ids);
  if (noErr != err) return res(err);

  wb::AEDescList uids;
  err = __iTunesGetPlaylistsProperty(&playlists, typeSInt64, kiTunesPersistentID, &uids);
  if (noErr != err) return res(err);

  wb::AEDescList kinds;
  err = __iTunesGetPlaylistsProperty(&playlists, 'eSpK', 'pSpK', &kinds);
  if (noErr != err) return res(err);

  wb::AEDescList names;
  err = __iTunesGetPlaylistsProperty(&playlists, typeUnicodeText, kiTunesNameKey, &names);
  if (noErr != err) return res(err);
  
  long count = 0;
  err = AECountItems(&names, &count);
  if (noErr != err) return res(err);

  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:count];
  for (long idx = 1; idx <= count; ++idx) {
    SInt64 uid = 0;
    err = WBAEGetNthSInt64FromDescList(&uids, idx, &uid);
    if (noErr != err)
      continue;

    OSType type;
    err = AEGetNthPtr(&kinds, idx, typeWildCard, nullptr, nullptr, &type, sizeof(type), nullptr);
    if (noErr != err)
      continue;

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
      spx::unique_cfptr<CFStringRef> name(WBAECopyNthStringFromDescList(&names, idx, &err));
      if (!name)
        continue;

      result[SPXCFToNSString(name.get())] = @{ @"uid": @(uid), @"kind": @(kind) };
    }

  } // End for
  return SPXCFDictionaryBridgingRetain(result);
}
