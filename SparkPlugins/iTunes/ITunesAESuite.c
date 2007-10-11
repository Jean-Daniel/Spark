/*
 *  ITunesAESuite.c
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#include "ITunesAESuite.h"
#include <ShadowKit/SKLSFunctions.h>
#include <ShadowKit/SKAEFunctions.h>
#include <ShadowKit/SKProcessFunctions.h>

static 
CFArrayRef iTunesCopyPlaylistNamesFromList(AEDescList *items);

static
OSStatus iTunesReshufflePlaylist(iTunesPlaylist *playlist);

SK_INLINE
OSStatus _iTunesCreateEvent(AEEventClass class, AEEventID method, AppleEvent *event) {
  SKAEInitDesc(event);
  
  OSStatus err = SKAECreateEventWithTargetSignature(kiTunesSignature, class, method, event);
  require_noerr(err, bail);
  
  err = SKAESetStandardAttributes(event);
  require_noerr(err, bail);
  
  return noErr;
bail:
    SKAEDisposeDesc(event);
  return err;
}

static
OSStatus _iTunesCopyObjectStringProperty(AEDesc *object, AEKeyword property, CFStringRef *value) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* ... 'property' of object 'object' */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeUnicodeText, property, object);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnCFString(&theEvent, value);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

static
OSStatus _iTunesGetObjectIntegerProperty(AEDesc *object, AEKeyword property, SInt32 *value) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* ... 'property' of track 'track' */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeSInt32, property, object);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnSInt32(&theEvent, value);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

Boolean iTunesIsRunning(ProcessSerialNumber *proc) {
  ProcessSerialNumber psn = SKProcessGetProcessWithSignature(kiTunesSignature);
  if (proc) *proc = psn;
  return psn.lowLongOfPSN != kNoProcess;
}

#pragma mark -
#pragma mark Commands
OSStatus iTunesLaunch(LSLaunchFlags flags) {
  FSRef iTunes;
  OSStatus err = SKLSGetApplicationForSignature(kiTunesSignature, &iTunes);
  if (noErr == err) {
    err = SKLSLaunchApplication(&iTunes, flags);
  }
  return err;
}

#pragma mark iTunes Properties
OSStatus iTunesGetPlayerState(ITunesState *state) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pPlS', NULL);
  require_noerr(err, bail);

  err = SKAESendEventReturnData(&theEvent, typeEnumerated, NULL, state, sizeof(OSType), NULL);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesGetPlayerPosition(UInt32 *position) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pPos', NULL);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnUInt32(&theEvent, position);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesGetVisualEnabled(Boolean *state) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pVsE', NULL);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnBoolean(&theEvent, state);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesSetVisualEnabled(Boolean state) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  require_noerr(err, bail);
  
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVsE', NULL);
  require_noerr(err, bail);
  
  err = SKAEAddBoolean(&theEvent, keyAEData, state);
  require_noerr(err, bail);
  
  err = SKAESendEventNoReply(&theEvent);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesGetSoundVolume(SInt16 *volume) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVol', NULL);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnSInt16(&theEvent, volume);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}
OSStatus iTunesSetSoundVolume(SInt16 volume) {
  AppleEvent theEvent;
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  require_noerr(err, bail);
  
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVol', NULL);
  require_noerr(err, bail);
  
  err = SKAEAddSInt16(&theEvent, keyAEData, volume); 
  require_noerr(err, bail);
  
  err = SKAESendEventNoReply(&theEvent);
  require_noerr(err, bail);

bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

#pragma mark -
#pragma mark Tracks
OSStatus iTunesSetTrackRate(iTunesTrack *track, UInt32 rate) {
  AppleEvent theEvent;
  /* tell application "iTunes" to set ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  require_noerr(err, bail);
  
  /* ... rate of track 'track' */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeUInt32, kiTunesRateKey, track);
  require_noerr(err, bail);
  
  /* ... to 'rate' */
  err = SKAEAddUInt32(&theEvent, keyAEData, rate);
  require_noerr(err, bail);
  
  err = SKAESendEventNoReply(&theEvent);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}
OSStatus iTunesGetTrackRate(iTunesTrack *track, UInt32 *rate) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  require_noerr(err, bail);
  
  /* ... rate of track 'track' */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeSInt16, kiTunesRateKey, track);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnUInt32(&theEvent, rate);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesGetCurrentTrack(iTunesTrack *track) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* current track */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'cTrk', 'pTrk', NULL);
  require_noerr(err, bail);
  
  /* Do not force return type to 'cTrk', because iTunes returns a 'cTrk' subclass */
  err = SKAESendEventReturnAEDesc(&theEvent, typeWildCard, track);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesSetCurrentTrackRate(UInt32 rate) {
  AEDesc track = SKAEEmptyDesc();
  
  ITunesState state = 0;
  OSStatus err = iTunesGetPlayerState(&state);
  require_noerr(err, bail);
  
  /* Does nothing if not playing */
  if (state == kiTunesStatePlaying) {
    err = iTunesGetCurrentTrack(&track);
    require_noerr(err, bail);
    
    err = iTunesSetTrackRate(&track, rate);
    require_noerr(err, bail);
  }

bail:
    SKAEDisposeDesc(&track);
  return err;
}

OSStatus iTunesCopyTrackStringProperty(iTunesTrack *track, ITunesTrackProperty property, CFStringRef *value) {
  return _iTunesCopyObjectStringProperty(track, property, value);
}

OSStatus iTunesGetTrackIntegerProperty(iTunesTrack *track, ITunesTrackProperty property, SInt32 *value) {
  return _iTunesGetObjectIntegerProperty(track, property, value);
}

#pragma mark -
#pragma mark Playlists
OSStatus iTunesPlayPlaylist(iTunesPlaylist *playlist) {
  AppleEvent theEvent = SKAEEmptyDesc();
  
  OSStatus err = iTunesReshufflePlaylist(playlist);
  require_noerr(err, bail);
  
  err = _iTunesCreateEvent(kiTunesSuite, kiTunesCommandPlay, &theEvent);
  require_noerr(err, bail);
  
  err = SKAEAddAEDesc(&theEvent, keyDirectObject, playlist);
  require_noerr(err, bail);
  
  err = SKAESendEventNoReply(&theEvent);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err; 
}

OSStatus iTunesPlayPlaylistWithID(SInt64 uid) {
  iTunesPlaylist playlist = SKAEEmptyDesc();
  
  OSStatus err = iTunesGetPlaylistWithID(uid, &playlist);
  require_noerr(err, bail);
  
  err = iTunesPlayPlaylist(&playlist);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&playlist);
  return err; 
}

OSStatus iTunesPlayPlaylistWithName(CFStringRef name) {
  iTunesPlaylist playlist = SKAEEmptyDesc();
  
  OSStatus err = iTunesGetPlaylistWithName(name, &playlist);
  require_noerr(err, bail);
  
  err = iTunesPlayPlaylist(&playlist);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&playlist);
  return err; 
}

OSStatus iTunesGetCurrentPlaylist(iTunesPlaylist *playlist) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* current playlist */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'cPly', 'pPla', NULL);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnAEDesc(&theEvent, typeWildCard, playlist);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}


SK_INLINE
OSStatus __iTunesGetPlaylistUIDOperand(AEDesc *operand) {
  AEDesc obj = SKAEEmptyDesc();
  
  OSStatus err = AECreateDesc(typeObjectBeingExamined, NULL, 0, &obj);
  require_noerr(err, bail);
  
  err = SKAECreatePropertyObjectSpecifier(typeProperty, kiTunesPersistentID, &obj, operand);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&obj);
  return err;
}

SK_INLINE
OSStatus __iTunesAddPlaylistSpecifier(AppleEvent *event, SInt64 uid) {
  AEDesc data = SKAEEmptyDesc();
  AEDesc object = SKAEEmptyDesc();
  AEDesc specifier = SKAEEmptyDesc();
  AEDesc comparaison = SKAEEmptyDesc();
  
  OSStatus err = __iTunesGetPlaylistUIDOperand(&object);
  require_noerr(err, bail);
  
  err = AECreateDesc(typeSInt64, &uid, sizeof(uid), &data);
  require_noerr(err, bail);
  
  err = CreateCompDescriptor(kAEEquals,
                             &object,
                             &data,
                             FALSE,
                             &comparaison);
  require_noerr(err, bail);
  
  err = SKAECreateObjectSpecifier('cPly', formTest, &comparaison, NULL, &specifier);
  require_noerr(err, bail);
  
  err = SKAEAddAEDesc(event, keyDirectObject, &specifier);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&comparaison);
  SKAEDisposeDesc(&specifier);
  SKAEDisposeDesc(&object);
  SKAEDisposeDesc(&data);
  return err;
}


OSStatus iTunesGetPlaylistWithID(SInt64 uid, iTunesPlaylist *playlist) {
  AppleEvent theEvent;
  AEDescList list = SKAEEmptyDesc();
  
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* ... playlists whose 'pPID' */
  err = __iTunesAddPlaylistSpecifier(&theEvent, uid);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnAEDescList(&theEvent, &list);
  require_noerr(err, bail);
  
  long count = 0;
  err = AECountItems(&list, &count);
  require_noerr(err, bail);
  
  if (0 == count) {
    err = errAENoSuchObject;
  } else {
    err = AEGetNthDesc(&list, 1, typeWildCard, NULL, playlist);
    require_noerr(err, bail);
  }
  
bail:
    SKAEDisposeDesc(&list);
  SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesGetPlaylistWithName(CFStringRef name, iTunesPlaylist *playlist) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* ... playlist "name" */
  err = SKAEAddNameObjectSpecifier(&theEvent, keyDirectObject, 'cPly', name, NULL);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnAEDesc(&theEvent, typeWildCard, playlist);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
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
OSStatus iTunesGetPlaylistShuffle(iTunesPlaylist *playlist, Boolean *shuffle) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* ... shuffle of playlist 'playlist' */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pShf', playlist);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnBoolean(&theEvent, shuffle);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}
static
OSStatus iTunesSetPlaylistShuffle(iTunesPlaylist *playlist, Boolean shuffle) {
  AppleEvent theEvent;
  /* tell application "iTunes" to set ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAESetData, &theEvent);
  require_noerr(err, bail);
  
  /* ... shuffle of playlist 'playlist' ... */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pShf', playlist);
  require_noerr(err, bail);
  
  /* ... to 'shuffle' */
  err = SKAEAddBoolean(&theEvent, keyAEData, shuffle);
  require_noerr(err, bail);
  
  err = SKAESendEventNoReply(&theEvent);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesReshufflePlaylist(iTunesPlaylist *playlist) {
  OSStatus err;
  Boolean shuffle;
  
  err = iTunesGetPlaylistShuffle(playlist, &shuffle);
  require_noerr(err, bail);
  
  if (shuffle) {
    err = iTunesSetPlaylistShuffle(playlist, FALSE);
    require_noerr(err, bail);
    
    err = iTunesSetPlaylistShuffle(playlist, TRUE);
    require_noerr(err, bail);
  }
bail:
    return err;
}

#pragma mark -
SK_INLINE
OSStatus _iTunesGetLibrarySourceOperand(AEDesc *operand) {
  /* Prepare operand 1: kind of examined object */
  AEDesc obj = SKAEEmptyDesc();
  
  OSStatus err = AECreateDesc(typeObjectBeingExamined, NULL, 0, &obj);
  require_noerr(err, bail);
  
  err = SKAECreatePropertyObjectSpecifier(typeProperty, 'pKnd', &obj, operand);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&obj);
  return err;
}

/* source whose kind is library => source where kind of examined object equals type 'kLib' */
static OSStatus _iTunesGetLibrarySources(AEDesc *sources) {
  /* Prepare operand 1: kind of examined object */
  AEDesc type = SKAEEmptyDesc();
  AEDesc property = SKAEEmptyDesc();
  AEDesc comparaison = SKAEEmptyDesc();
  
  OSStatus err = _iTunesGetLibrarySourceOperand(&property);
  require_noerr(err, bail);
  
  OSType kind = 'kLib';
  err = AECreateDesc(typeType, &kind, sizeof(kind), &type);
  require_noerr(err, bail);
  
  err = CreateCompDescriptor(kAEEquals,
                             &property,
                             &type,
                             FALSE,
                             &comparaison);
  require_noerr(err, bail);
  
  err = SKAECreateObjectSpecifier('cSrc', formTest, &comparaison, NULL, sources);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&type);
  SKAEDisposeDesc(&property);
  SKAEDisposeDesc(&comparaison);
  return err;
}

static OSStatus iTunesGetLibrarySource(AEDesc *source) {
  AEDesc sources = SKAEEmptyDesc();
  
  OSStatus err = _iTunesGetLibrarySources(&sources);
  require_noerr(err, bail);
  
  err = SKAECreateIndexObjectSpecifier('cSrc', 1, &sources, source);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&sources);
  return err;
}

SK_INLINE
OSStatus __iTunesGetEveryPlaylistObject(AEDesc *object) {
  AEDesc source = SKAEEmptyDesc();
  
  OSStatus err = iTunesGetLibrarySource(&source);
  require_noerr(err, bail);
  
  /* every playlists of (first source whose kind is library) */
  err = SKAECreateIndexObjectSpecifier('cPly', kAEAll, &source, object);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&source);
  return err;
}

SK_INLINE
OSStatus __iTunesGetPlaylistsProperty(AEDesc *playlists, DescType type, AEKeyword property, AEDescList *properties) {
  AppleEvent theEvent = SKAEEmptyDesc();
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);

  /* name of playlists */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, type, property, playlists);
  require_noerr(err, bail);

  err = SKAESendEventReturnAEDescList(&theEvent, properties);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

static
OSStatus _iTunesPlaylistIsSmart(UInt32 id, Boolean *smart) {
  AEDesc playlist = SKAEEmptyDesc();
  AppleEvent theEvent = SKAEEmptyDesc();
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  err = SKAECreateUniqueIDObjectSpecifier('cPly', id, NULL, &playlist);
  require_noerr(err, bail);
  
  /* name of playlists */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeBoolean, 'pSmt', &playlist);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnBoolean(&theEvent, smart);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&playlist);
  SKAEDisposeDesc(&theEvent);
  return err;
}

CFArrayRef iTunesCopyPlaylistNames(void) {
  CFArrayRef result = NULL;
  AEDescList names = SKAEEmptyDesc();
  AEDesc playlists = SKAEEmptyDesc();
  
  OSStatus err = __iTunesGetEveryPlaylistObject(&playlists);
  require_noerr(err, bail);
  
  err = __iTunesGetPlaylistsProperty(&playlists, typeUnicodeText, kiTunesNameKey, &names);
  require_noerr(err, bail);
  
  result = iTunesCopyPlaylistNamesFromList(&names);
  
bail:
    SKAEDisposeDesc(&names);
  SKAEDisposeDesc(&playlists);
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
        if (noErr == SKAECopyCFStringFromDescriptor(&listDesc, &name) && name) {
          CFArrayAppendValue(names, name);
          CFRelease(name);
        }
        SKAEDisposeDesc(&listDesc);
      }
    } // End for
  }
  return names;
}

CFDictionaryRef iTunesCopyPlaylists(void) {
  CFMutableDictionaryRef result = NULL;
  
  AEDescList ids = SKAEEmptyDesc();
  AEDescList uids = SKAEEmptyDesc();
  AEDescList kinds = SKAEEmptyDesc();
  AEDescList names = SKAEEmptyDesc();
  
  AEDesc playlists = SKAEEmptyDesc();
  
  OSStatus err = __iTunesGetEveryPlaylistObject(&playlists);
  require_noerr(err, bail);

  err = __iTunesGetPlaylistsProperty(&playlists, typeSInt32, 'ID  ', &ids);
  require_noerr(err, bail);
  
  err = __iTunesGetPlaylistsProperty(&playlists, typeSInt64, kiTunesPersistentID, &uids);
  require_noerr(err, bail);
  
  err = __iTunesGetPlaylistsProperty(&playlists, 'eSpK', 'pSpK', &kinds);
  require_noerr(err, bail);
  
  err = __iTunesGetPlaylistsProperty(&playlists, typeUnicodeText, kiTunesNameKey, &names);
  require_noerr(err, bail);
  
  long count = 0;
  err = AECountItems(&names, &count);
  if (noErr == err) {
    result = CFDictionaryCreateMutable(kCFAllocatorDefault, count, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    for (SInt32 idx = 1; (idx <= count); idx++) {
      SInt64 uid = 0;
      err = SKAEGetNthSInt64FromDescList(&uids, idx, &uid);
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
              kind = kPlaylistMovie;
              break;
//            case 'kSpI':
//              kind = kPlaylistTVShow:
              break;
            case 'kSpP':
              kind = kPlaylistPodcast;
              break;
            case 'kSpA':
              kind = kPlaylistBooks;
              break;
            case 'kSpM':
              kind = kPlaylistPurchased;
              break;
            case 'kSpS':
              kind = kPlaylistPartyShuffle;
              break;
            case 'kSpN': {
              // check if smart. 
              UInt32 id = 0;
              if (noErr == SKAEGetNthUInt32FromDescList(&ids, idx, &id)) {
                Boolean smart = false;
                err = _iTunesPlaylistIsSmart(id, &smart);
                if (noErr == err) {
                  kind = smart ? kPlaylistSmart : kPlaylistUser;
                } else {
                  err = noErr;
                }
              }
            }
              break;
          }
          if (kind != kPlaylistUndefined) {
            CFStringRef name = NULL;
            err = SKAECopyNthCFStringFromDescList(&names, idx, &name);
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
  SKAEDisposeDesc(&names);
  SKAEDisposeDesc(&kinds);
  SKAEDisposeDesc(&uids);
  SKAEDisposeDesc(&ids);
  SKAEDisposeDesc(&playlists);
  return result;
}
