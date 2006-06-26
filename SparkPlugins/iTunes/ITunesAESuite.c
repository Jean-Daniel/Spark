/*
 *  iTunesAESuite.c
 *  Spark
 *
 *  Created by Fox on Sun Mar 07 2004.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */

#include "ITunesAESuite.h"

const OSType kITunesSignature = 'hook';

static CFArrayRef GetPlaylistsNames(AEDescList *items);
static OSStatus ShufflePlaylistIfNeeded(AEDesc *playlist);
static OSStatus iTunesGetPlaylist(CFStringRef name, AEDesc *playlist);

#pragma mark -
OSStatus iTunesGetVisualState(Boolean *state) {
  OSStatus err = noErr;
  AEDesc theEvent;
  ShadowAENullDesc(&theEvent);
  
  err = ShadowAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err) {
    err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pVsE', NULL);
  }
  if (noErr == err) {
    err = ShadowAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAESendEventReturnBoolean(&theEvent, state);
    ShadowAEDisposeDesc(&theEvent);
  }
  return err;
}

OSStatus iTunesSetVisualState(Boolean state) {
  OSStatus err = noErr;
  AEDesc theEvent;
  ShadowAENullDesc(&theEvent);
  
  err = ShadowAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAESetData, &theEvent);
  if (noErr == err) {
    err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVsE', NULL);
  }
  if (noErr == err) {
    err = ShadowAEAddBoolean(&theEvent, keyAEData, state);
  }
  if (noErr == err) {
    err = ShadowAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAESendEventNoReply(&theEvent);
    ShadowAEDisposeDesc(&theEvent);
  }
  return err;
}

OSStatus iTunesGetVolume(SInt16 *volume) {
  OSStatus err = noErr;
  AEDesc theEvent;
  ShadowAENullDesc(&theEvent);
  
  err = ShadowAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err) {
    err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVol', NULL);
  }
  if (noErr == err) {
    err = ShadowAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAESendEventReturnSInt16(&theEvent, volume);
    ShadowAEDisposeDesc(&theEvent);
  }
  return err;
}

OSStatus iTunesSetVolume(SInt16 volume) {
  OSStatus err = noErr;
  AEDesc theEvent;
  ShadowAENullDesc(&theEvent);
  
  err = ShadowAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAESetData, &theEvent);
  if (noErr == err) {
    err = ShadowAEAddSInt16(&theEvent, keyAEData, volume); 
  }
  if (noErr == err) {
    err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty,'pVol', NULL);
  }
  if (noErr == err) {
    err = ShadowAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAESendEventNoReply(&theEvent);
    ShadowAEDisposeDesc(&theEvent);
  }
  return err;
}

CFArrayRef iTunesGetPlaylists() {
  OSStatus err = noErr;
  CFArrayRef names = NULL;
  
  AEDesc theEvent;
  ShadowAENullDesc(&theEvent);
  AEDescList playlists;
  ShadowAENullDesc(&playlists);
  
  err = ShadowAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err) {
    err = ShadowAEAddIndexObjectSpecifier(&theEvent, keyDirectObject, 'cPly', kAEAll, NULL);
  }
  if (noErr == err) {
    err = ShadowAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAESendEventReturnAEDescList(&theEvent, &playlists);
    ShadowAEDisposeDesc(&theEvent);
  }
  if (noErr == err) {
    names = GetPlaylistsNames(&playlists);
    ShadowAEDisposeDesc(&playlists);
  }
  return names;
}

OSStatus iTunesPlayPlaylist(CFStringRef name)  {
  AppleEvent theEvent;
  ShadowAENullDesc(&theEvent);
  AEDesc playlist;
  ShadowAENullDesc(&playlist);
  
  OSStatus err = iTunesGetPlaylist(name, &playlist);
  require_noerr(err, bail);
  
//  err = ShadowAESendSimpleEvent(kITunesSignature, 'hook', 'Stop');
//  require_noerr(err, bail);
  
  err = ShufflePlaylistIfNeeded(&playlist);
  require_noerr(err, bail);
  
  err = ShadowAECreateEventWithTargetSignature(kITunesSignature, 'hook', 'Play', &theEvent);
  require_noerr(err, bail);
  
  err = AEPutParamDesc(&theEvent, keyDirectObject, &playlist);
  require_noerr(err, bail);
  
  err = ShadowAEAddMagnitude(&theEvent);
  require_noerr(err, bail);
  
  err = ShadowAEAddSubject(&theEvent);
  require_noerr(err, bail);
  
  err = ShadowAESendEventNoReply(&theEvent);

bail:
  ShadowAEDisposeDesc(&theEvent);
  ShadowAEDisposeDesc(&playlist);
  return err;
}

OSStatus iTunesGetState(OSType *status) {
  AppleEvent theEvent;
  OSStatus err = ShadowAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  if (noErr == err) {
    err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pPlS', NULL);
  }
  if (noErr == err) {
    err = ShadowAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAESendEventReturnData(&theEvent, typeEnumerated, NULL, status, sizeof(OSType), NULL);
  }
  ShadowAEDisposeDesc(&theEvent);
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
    err = ShadowAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAESetData, &theEvent);
  }
  if (noErr == err) {
    err = ShadowAECreatePropertyObjectSpecifier('cTrk', 'pTrk', NULL, &currentTrack);
  }
  if (noErr == err) {
    err = ShadowAEAddSInt16(&theEvent, keyAEData, (SInt16)rate); 
  }
  if (noErr == err) {
    err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeInteger, 'pRte', &currentTrack);
  }
  if (noErr == err) {
    err = ShadowAEAddMagnitude(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAEAddSubject(&theEvent);
  }
  if (noErr == err) {
    err = ShadowAESendEventNoReply(&theEvent);
  }
  ShadowAEDisposeDesc(&rateProperty);  
  ShadowAEDisposeDesc(&currentTrack);
  ShadowAEDisposeDesc(&theEvent);
  return err;
}

OSStatus __inline__ _iTunesCreateEvent(AEEventClass class, AEEventID method, AppleEvent *event) {
  ShadowAENullDesc(event);
  
  OSStatus err = ShadowAECreateEventWithTargetSignature(kITunesSignature, class, method, event);
  require_noerr(err, bail);
  
  err = ShadowAEAddMagnitude(event);
  require_noerr(err, bail);
  
  err = ShadowAEAddSubject(event);
  require_noerr(err, bail);
  
  return noErr;
bail:
    ShadowAEDisposeDesc(event);
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
  err = ShadowAECreatePropertyObjectSpecifier('cTrk', 'pTrk', NULL, &track);
  require_noerr(err, bail);
  
  /* ...'property' of current track */
  err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeUnicodeText, property, &track);
  require_noerr(err, bail);
  
  err = ShadowAESendEventReturnCFString(&theEvent, &str);
  
bail:
  ShadowAEDisposeDesc(&theEvent);
  ShadowAEDisposeDesc(&track);

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
  
  err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'cTrk', 'pTrk', NULL);
  require_noerr(err, bail);
  
  SInt32 count = 0;
  err = ShadowAESendEventReturnSInt32(&theEvent, &count);
  require_noerr(err, bail);
  
  if (count > 0) {
    ShadowAEDisposeDesc(&theEvent);
    
    err = _iTunesCreateEvent(kAECoreSuite, kAEGetData, &theEvent);
    require_noerr(err, bail);

    /* current track of application */
    err = ShadowAECreatePropertyObjectSpecifier('cTrk', 'pTrk', NULL, &track);
    require_noerr(err, bail);
    
    /* artwork idx of current track */
    err = ShadowAECreateIndexObjectSpecifier('cArt', idx, &track, &arts);
    require_noerr(err, bail);
  
    /* ...'data' of artwork */
    err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, 'PICT', 'pPCT', &arts);
    require_noerr(err, bail);
  
    err = ShadowAESendEventReturnCFData(&theEvent, 'PICT', &data);
  }
bail:
  ShadowAEDisposeDesc(&theEvent);
  ShadowAEDisposeDesc(&track);
  ShadowAEDisposeDesc(&arts);  
  
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
  ShadowAENullDesc(&theEvent);
  
  err = ShadowAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  /* get pShf of playlist */
  err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pShf', playlist);
  require_noerr(err, bail);
  
  err = ShadowAEAddMagnitude(&theEvent);
  require_noerr(err, bail);
  
  err = ShadowAESendEventReturnBoolean(&theEvent, shuffle);
  
bail:
  ShadowAEDisposeDesc(&theEvent);
  return err;
}

OSStatus SetPlaylistShuffle(AEDesc *playlist, Boolean shuffle) {
  AppleEvent theEvent;
  OSStatus err = noErr;
  ShadowAENullDesc(&theEvent);
  
  err = ShadowAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAESetData, &theEvent);
  require_noerr(err, bail);
  
  /* set pShf of playlist */
  err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pShf', playlist);
  require_noerr(err, bail);
  
  /* to shuffle */
  err = ShadowAEAddBoolean(&theEvent, keyAEData, shuffle);
  require_noerr(err, bail);
  
  err = ShadowAEAddMagnitude(&theEvent);
  require_noerr(err, bail);
  
  err = ShadowAESendEventNoReply(&theEvent);
  
bail:
    ShadowAEDisposeDesc(&theEvent);
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
  OSStatus err = ShadowAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  require_noerr(err, bail);
  
  err = ShadowAEAddNameObjectSpecifier(&theEvent, keyDirectObject, 'cPly', name, NULL);
  require_noerr(err, bail);
  
  err = ShadowAEAddMagnitude(&theEvent);
  require_noerr(err, bail);
  
  err = ShadowAESendEventReturnAEDesc(&theEvent, typeWildCard, playlist);
  require_noerr(err, bail);
  
bail:
    ShadowAEDisposeDesc(&theEvent);
  return err;
}

CFStringRef GetContainerName(AEDesc *container) {
  AppleEvent theEvent;
  CFStringRef name = NULL;
  OSStatus err = ShadowAECreateEventWithTargetSignature(kITunesSignature, kAECoreSuite, kAEGetData, &theEvent);
  
  if (noErr == err) {
    err = ShadowAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, 'pnam', container);
  }
  if (noErr == err) {
    err = ShadowAESendEventReturnCFString(&theEvent, &name);
    ShadowAEDisposeDesc(&theEvent);
  }
  return name;
}

CFArrayRef GetPlaylistsNames(AEDescList *items) {
  int count = 0, index;
  long listsCount;
  CFMutableArrayRef names = NULL;
  OSStatus err = AECountItems (items, &listsCount);
  
  if (noErr == err) {
    names = CFArrayCreateMutable(kCFAllocatorDefault, listsCount, &kCFTypeArrayCallBacks);
    for (index = 1; (index <= listsCount); index++) {
      AEDesc listDesc;
      err = AEGetNthDesc(items, index, typeWildCard, NULL, &listDesc);
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
        ShadowAEDisposeDesc(&listDesc);
      }
    } // End for
  }
  return names;
}
