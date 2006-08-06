/*
 *  iTunesAESuite.c
 *  Spark
 *
 *  Created by Fox on Sun Mar 07 2004.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */

#include "ITunesAESuite.h"
#include <ShadowKit/SKAEFunctions.h>

const OSType kITunesSignature = 'hook';

static CFArrayRef GetPlaylistsNames(AEDescList *items);
static OSStatus ShufflePlaylistIfNeeded(AEDesc *playlist);
static OSStatus iTunesGetPlaylist(CFStringRef name, AEDesc *playlist);

#pragma mark -
OSStatus iTunesGetVisualState(Boolean *state) {
  OSStatus err = noErr;
  AEDesc theEvent;
  SKAENullDesc(&theEvent);
  
  err = SKAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err) {
    err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pVsE', NULL);
  }
  if (noErr == err) {
    err = SKAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = SKAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = SKAESendEventReturnBoolean(&theEvent, state);
    SKAEDisposeDesc(&theEvent);
  }
  return err;
}

OSStatus iTunesSetVisualState(Boolean state) {
  OSStatus err = noErr;
  AEDesc theEvent;
  SKAENullDesc(&theEvent);
  
  err = SKAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAESetData, &theEvent);
  if (noErr == err) {
    err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVsE', NULL);
  }
  if (noErr == err) {
    err = SKAEAddBoolean(&theEvent, keyAEData, state);
  }
  if (noErr == err) {
    err = SKAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = SKAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = SKAESendEventNoReply(&theEvent);
    SKAEDisposeDesc(&theEvent);
  }
  return err;
}

OSStatus iTunesGetVolume(SInt16 *volume) {
  OSStatus err = noErr;
  AEDesc theEvent;
  SKAENullDesc(&theEvent);
  
  err = SKAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err) {
    err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVol', NULL);
  }
  if (noErr == err) {
    err = SKAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = SKAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = SKAESendEventReturnSInt16(&theEvent, volume);
    SKAEDisposeDesc(&theEvent);
  }
  return err;
}

OSStatus iTunesSetVolume(SInt16 volume) {
  OSStatus err = noErr;
  AEDesc theEvent;
  SKAENullDesc(&theEvent);
  
  err = SKAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAESetData, &theEvent);
  if (noErr == err) {
    err = SKAEAddSInt16(&theEvent, keyAEData, volume); 
  }
  if (noErr == err) {
    err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVol', NULL);
  }
  if (noErr == err) {
    err = SKAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = SKAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = SKAESendEventNoReply(&theEvent);
    SKAEDisposeDesc(&theEvent);
  }
  return err;
}

CFArrayRef iTunesGetPlaylists() {
  OSStatus err = noErr;
  CFArrayRef names = NULL;
  
  AEDesc theEvent;
  SKAENullDesc(&theEvent);
  AEDescList playlists;
  SKAENullDesc(&playlists);
  
  err = SKAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err) {
    err = SKAEAddIndexObjectSpecifier(&theEvent, keyDirectObject, 'cPly', kAEAll, NULL);
  }
  if (noErr == err) {
    err = SKAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = SKAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = SKAESendEventReturnAEDescList(&theEvent, &playlists);
    SKAEDisposeDesc(&theEvent);
  }
  if (noErr == err) {
    names = GetPlaylistsNames(&playlists);
    SKAEDisposeDesc(&playlists);
  }
  return names;
}

OSStatus iTunesPlayPlaylist(CFStringRef name)  {
  AppleEvent theEvent;
  SKAENullDesc(&theEvent);
  AEDesc playlist;
  SKAENullDesc(&playlist);
  
  OSStatus err = iTunesGetPlaylist(name, &playlist);
  require_noerr(err, bail);
  
//  err = SKAESendSimpleEvent(kITunesSignature, 'hook', 'Stop');
//  require_noerr(err, bail);
  
  err = ShufflePlaylistIfNeeded(&playlist);
  require_noerr(err, bail);
  
  err = SKAECreateEventWithTargetSignature(kITunesSignature, 'hook', 'Play', &theEvent);
  require_noerr(err, bail);
  
  err = AEPutParamDesc(&theEvent, keyDirectObject, &playlist);
  require_noerr(err, bail);
  
  err = SKAEAddMagnitude(&theEvent);
  require_noerr(err, bail);
  
  err = SKAEAddSubject(&theEvent);
  require_noerr(err, bail);
  
  err = SKAESendEventNoReply(&theEvent);

bail:
  SKAEDisposeDesc(&theEvent);
  SKAEDisposeDesc(&playlist);
  return err;
}

OSStatus iTunesGetState(OSType *status) {
  AppleEvent theEvent;
  OSStatus err = SKAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err) {
    err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pPlS', NULL);
  }
  if (noErr == err) {
    err = SKAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = SKAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = SKAESendEventReturnData(&theEvent, typeEnumerated, NULL, status, sizeof(OSType), NULL);
  }
  SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus iTunesRateCurrentSong(UInt16 rate) {
  AEDesc currentTrack = {typeNull, NULL};
  AEDesc rateProperty = {typeNull, NULL};
  AppleEvent theEvent = {typeNull, NULL};
  OSType state = 0;
  
  OSStatus err = iTunesGetState(&state);
  if (state != kiTunesStatePlaying) {
    return noErr;
  }
  if (noErr == err) {
    err = SKAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAESetData, &theEvent);
  }
  if (noErr == err) {
    err = SKAECreatePropertyObjectSpecifier('cTrk', 'pTrk', NULL, &currentTrack);
  }
  if (noErr == err) {
    err = SKAEAddSInt16(&theEvent, keyAEData, (SInt16)rate); 
  }
  if (noErr == err) {
    err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeInteger, 'pRte', &currentTrack);
  }
  if (noErr == err) {
    err = SKAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = SKAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = SKAESendEventNoReply(&theEvent);
  }
  SKAEDisposeDesc(&rateProperty);  
  SKAEDisposeDesc(&currentTrack);
  SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus __inline__ _iTunesCreateEvent(AEEventClass class, AEEventID method, AppleEvent *event) {
  SKAENullDesc(event);
  
  OSStatus err = SKAECreateEventWithTargetSignature(kITunesSignature, class, method, event);
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
CFStringRef _iTunesCopyStringProperty(OSType property) {
  CFStringRef str = NULL;
  AEDesc track = {typeNull, NULL};
  AppleEvent theEvent = {typeNull, NULL};
  
  /* tell application "iTunes" to get... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* current track of application */
  err = SKAECreatePropertyObjectSpecifier('cTrk', 'pTrk', NULL, &track);
  require_noerr(err, bail);
  
  /* ...'property' of current track */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeUnicodeText, property, &track);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnCFString(&theEvent, &str);
  
bail:
  SKAEDisposeDesc(&theEvent);
  SKAEDisposeDesc(&track);

  return str;
}

CFDataRef _iTunesCopyArtwork(int idx) {
  CFDataRef data = NULL;
  AEDesc arts = {typeNull, NULL};
  AEDesc track = {typeNull, NULL};
  AppleEvent theEvent = {typeNull, NULL};
  
  /* tell application "iTunes" to get... */
  OSStatus err = _iTunesCreateEvent(kAECoreSuite, kAECountElements, &theEvent);
  require_noerr(err, bail);
  
  OSType type = 'cArt';
  err = AEPutParamPtr(&theEvent, 'kocl', typeType, &type, sizeof(type));
  require_noerr(err, bail);
  
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'cTrk', 'pTrk', NULL);
  require_noerr(err, bail);
  
  SInt32 count = 0;
  err = SKAESendEventReturnSInt32(&theEvent, &count);
  require_noerr(err, bail);
  
  if (count >= idx) {
    SKAEDisposeDesc(&theEvent);
    
    err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
    require_noerr(err, bail);

    /* current track of application */
    err = SKAECreatePropertyObjectSpecifier('cTrk', 'pTrk', NULL, &track);
    require_noerr(err, bail);
    
    /* artwork idx of current track */
    err = SKAECreateIndexObjectSpecifier('cArt', idx, &track, &arts);
    require_noerr(err, bail);
  
    /* ...'data' of artwork */
    err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'PICT', 'pPCT', &arts);
    require_noerr(err, bail);
  
    err = SKAESendEventReturnCFData(&theEvent, 'PICT', &data);
  }
bail:
  SKAEDisposeDesc(&theEvent);
  SKAEDisposeDesc(&track);
  SKAEDisposeDesc(&arts);  
  
  return data;
}

CFDictionaryRef iTunesCopyCurrentTrackProperties(OSStatus *error) {
  OSType state = 0;
  OSStatus err = iTunesGetState(&state);
  if (err != noErr || state != kiTunesStatePlaying) {
    return NULL;
  }
  
  CFMutableDictionaryRef properties = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                                &kCFTypeDictionaryKeyCallBacks, 
                                                                &kCFTypeDictionaryValueCallBacks);
  
  CFStringRef str = _iTunesCopyStringProperty('pnam');
  if (str) {
    CFDictionarySetValue(properties, CFSTR("Name"), str);
    CFRelease(str);
  }
  
  str = _iTunesCopyStringProperty('pArt');
  if (str) {
    CFDictionarySetValue(properties, CFSTR("Artist"), str);
    CFRelease(str);
  }
  
  str = _iTunesCopyStringProperty('pAlb');
  if (str) {
    CFDictionarySetValue(properties, CFSTR("Album"), str);
    CFRelease(str);
  }
  
//  CFDataRef picture = _iTunesCopyArtwork(1);
//  if (picture) {
//    CFDictionarySetValue(properties, CFSTR("Artwork"), picture);
//    CFRelease(picture);
//  }
  
  return properties;
}

#pragma mark -
OSStatus IsPlaylistShuffle(AEDesc *playlist, Boolean *shuffle) {
  AppleEvent theEvent;
  OSStatus err = noErr;
  SKAENullDesc(&theEvent);
  
  err = SKAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* get pShf of playlist */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pShf', playlist);
  require_noerr(err, bail);
  
  err = SKAEAddMagnitude(&theEvent);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnBoolean(&theEvent, shuffle);
  
bail:
  SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus SetPlaylistShuffle(AEDesc *playlist, Boolean shuffle) {
  AppleEvent theEvent;
  OSStatus err = noErr;
  SKAENullDesc(&theEvent);
  
  err = SKAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAESetData, &theEvent);
  require_noerr(err, bail);
  
  /* set pShf of playlist */
  err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pShf', playlist);
  require_noerr(err, bail);
  
  /* to shuffle */
  err = SKAEAddBoolean(&theEvent, keyAEData, shuffle);
  require_noerr(err, bail);
  
  err = SKAEAddMagnitude(&theEvent);
  require_noerr(err, bail);
  
  err = SKAESendEventNoReply(&theEvent);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

OSStatus ShufflePlaylistIfNeeded(AEDesc *playlist) {
  OSStatus err;
  Boolean shuffle;
  
  err = IsPlaylistShuffle(playlist, &shuffle);
  require_noerr(err, bail);
  
  if (!shuffle) {
    return err;
  }
  err = SetPlaylistShuffle(playlist, FALSE);
  require_noerr(err, bail);
  
  err = SetPlaylistShuffle(playlist, TRUE);
  
bail:
  return err;
}

#pragma mark -
OSStatus iTunesGetPlaylist(CFStringRef name, AEDesc *playlist) {
  AppleEvent theEvent;
  OSStatus err = SKAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  err = SKAEAddNameObjectSpecifier(&theEvent, keyDirectObject, 'cPly', name, NULL);
  require_noerr(err, bail);
  
  err = SKAEAddMagnitude(&theEvent);
  require_noerr(err, bail);
  
  err = SKAESendEventReturnAEDesc(&theEvent, typeWildCard, playlist);
  require_noerr(err, bail);
  
bail:
    SKAEDisposeDesc(&theEvent);
  return err;
}

CFStringRef GetContainerName(AEDesc *container) {
  AppleEvent theEvent;
  CFStringRef name = NULL;
  OSStatus err = SKAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  
  if (noErr == err) {
    err = SKAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pnam', container);
  }
  if (noErr == err) {
    err = SKAESendEventReturnCFString(&theEvent, &name);
    SKAEDisposeDesc(&theEvent);
  }
  return name;
}

CFArrayRef GetPlaylistsNames(AEDescList *items) {
  int count = 0, idx;
  long listsCount;
  CFMutableArrayRef names = NULL;
  OSStatus err = AECountItems (items, &listsCount);
  
  if (noErr == err) {
    names = CFArrayCreateMutable(kCFAllocatorDefault, listsCount, &kCFTypeArrayCallBacks);
    for (idx = 1; (idx <= listsCount); idx++) {
      AEDesc listDesc;
      err = AEGetNthDesc(items, idx, typeWildCard, NULL, &listDesc);
      if (noErr == err) {
        // Si c'est un objet, on le transforme en FSRef.
        if (typeObjectSpecifier == listDesc.descriptorType) {
          CFStringRef name = GetContainerName(&listDesc);
          if (name) {
            CFArrayAppendValue(names, name);
            CFRelease(name);
          }
        } else {
          // ???
        }
        if (noErr == err) {
          count++;
        }
        SKAEDisposeDesc(&listDesc);
      }
    } // End for
  }
  return names;
}
