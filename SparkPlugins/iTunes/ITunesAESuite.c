/*
 *  ITunesAESuite.c
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#include "ITunesAESuite.h"
#include <ShadowKit/SKLSFunctions.h>
#include <ShadowKit/SKAEFunctions.h>

static 
CFArrayRef iTunesCopyPlaylistNamesFromList(AEDescList *items);

static
OSStatus iTunesReshufflePlaylist(iTunesPlaylist *playlist);

SK_INLINE
OSStatus _iTunesCreateEvent(AEEventClass class, AEEventID method, AppleEvent *event) {
  SKAEInitDesc(event);
  
  OSStatus err = SKAECreateEventWithTargetSignature(kiTunesSignature, class, method, event);
  require_noerr(err, bail);
  
  err = SKAEAddMagnitude(event);
  require_noerr(err, bail);
  
  err = SKAEAddSubject(event);
  require_noerr(err, bail);
  
  return noErr;
bail:
    SKAEDisposeDesc(event);
  return err;
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

OSStatus iTunesGetTrackStringProperty(iTunesTrack *track, ITunesTrackProperty property, CFStringRef *value) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* ... 'property' of track 'track' */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeUnicodeText, property, track);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnCFString(&theEvent, value);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesGetTrackIntegerProperty(iTunesTrack *track, ITunesTrackProperty property, SInt32 *value) {
  AppleEvent theEvent;
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* ... 'property' of track 'track' */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeSInt32, property, track);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnSInt32(&theEvent, value);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
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

CFArrayRef iTunesCopyPlaylistNames(void) {
  CFArrayRef result = NULL;
  AEDesc theEvent = SKAEEmptyDesc();
  AEDescList names = SKAEEmptyDesc();
  
  AEDesc source = SKAEEmptyDesc();
  AEDesc playlists = SKAEEmptyDesc();
  
  /* tell application "iTunes" to get ... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  err = iTunesGetLibrarySource(&source);
  require_noerr(err, bail);
  
  /* playlists of (first source whose kind is library) */
  err = SKAECreateIndexObjectSpecifier('cPly', kAEAll, &source, &playlists);
  require_noerr(err, bail);
  
  /* name of playlists */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeUnicodeText, kiTunesNameKey, &playlists);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnAEDescList(&theEvent, &names);
  require_noerr(err, bail);
  
  result = iTunesCopyPlaylistNamesFromList(&names);
  
bail:
    SKAEDisposeDesc(&names);
  SKAEDisposeDesc(&theEvent);
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
        if (noErr == SKAEGetCFStringFromDescriptor(&listDesc, &name) && name) {
          if (name) {
            CFArrayAppendValue(names, name);
            CFRelease(name);
          }
        }
        SKAEDisposeDesc(&listDesc);
      }
    } // End for
  }
  return names;
}
