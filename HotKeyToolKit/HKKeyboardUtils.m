/*
 *  UCKeyboardUtils.c
 *  HotKeyToolKit
 *
 *  Created by Fox on Wed Mar 10 2004.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

#import "HKKeyboardUtils.h"
#import "HKKeyMap.h"

BOOL HKUseFullKeyMap = NO;

#pragma mark Statics Functions Declaration
static UInt16 KCHRKeyboardMapCount(void *layout);
static void KCHRKeyboardModifierTable(void* layout, UInt16 *modifiers);
static UniChar* KeyMapForKCHRKeyboardLayout(void *layout, UInt16 *modifiers[]);

static UInt16 UCKeyboardKeyCount(UCKeyboardLayout *layout);
static UInt16 UCKeyboardMapCount(UCKeyboardLayout *layout);
static void UCKeyboardModifierTable(UCKeyboardLayout* layout, UInt16 *modifiers);
static UniChar* KeyMapForUCKeyboardLayout(UCKeyboardLayout *layout, UInt16 *modifiers[]);

static UniChar ConvertToUnicode(unsigned char character);

#pragma mark -
#pragma mark Constants Definition
static const UInt16 kKCHRKeyCount = 127;

#pragma mark -
#pragma mark Publics Functions Definitions
OSStatus HKCurrentKeyMap(UniChar *keyMap[], UInt16 *keyCount, UInt16 *mapCount, UInt16 *modifiers[]) {
  KeyboardLayoutRef ref;
  KeyboardLayoutKind kind;
  /* type is unsigned */
  KeyboardLayoutPropertyTag type = 0xffff;
  void *layout;
  
  *keyMap = nil;
  *keyCount = 0;
  *mapCount = 0;
  
  OSStatus err = KLGetCurrentKeyboardLayout(&ref);
  if (noErr == err) {
    err = KLGetKeyboardLayoutProperty(ref, kKLKind, (void *)&kind);
  }
  if (noErr == err) {
    switch (kind) {
      case kKLKCHRuchrKind:
      case kKLuchrKind:
        type = kKLuchrData;
        break;
      case kKLKCHRKind:
        type = kKLKCHRData;
        break;
      default:
        type = 0xffff;
    }
  }
  if (type != 0xffff) {
    err = KLGetKeyboardLayoutProperty(ref, type, (void *)&layout);
  }
  if (noErr == err) {
    switch (type) {
      case kKLKCHRData:
        *keyMap = KeyMapForKCHRKeyboardLayout(layout, modifiers);
        *keyCount = kKCHRKeyCount;
        *mapCount = KCHRKeyboardMapCount(layout);
        break;
      case kKLuchrData:
        *keyMap = KeyMapForUCKeyboardLayout(layout, modifiers);
        *keyCount = UCKeyboardKeyCount(layout);
        *mapCount = UCKeyboardMapCount(layout);
        break;
      default:
        err = 1523;
    }
  }
  return err;
}

#pragma mark -
#pragma mark Statics Functions Definition

UInt16 KCHRKeyboardMapCount(void *layout) {
  UInt16 mapCount = 1;
  if (YES == HKUseFullKeyMap) { /* See KCHR reference for details */
    Byte *data = layout;
    data += 258; /* 2 bytes for version and 256 bytes for others data */
    mapCount = *(UInt16 *)data;
  }
  return mapCount;
}

void KCHRKeyboardModifierTable(void* layout, UInt16 *modifiers) {
  if (YES == HKUseFullKeyMap) {
    Byte *data = layout;
    data += 2;
    UInt8 *map = data;
    data += 256;
    
    UInt16 tablesCount = *(UInt16 *)data;
    int i;
    for (i=0; i<tablesCount; i++) {
      UInt16 modifier = 0;
      while ((map[modifier] != i) && (modifier < 256)) {
        modifier++;
      }
      modifiers[i] = modifier;
    }
  } else {
    modifiers[0] = 0;
  }
}

UniChar* KeyMapForKCHRKeyboardLayout(void *layout, UInt16 *pModifiers[]) {
  UniChar *keyMap;
  UInt16 keyCount = kKCHRKeyCount;
  
  UInt16 modifiers[128];
  UInt16 mapCount = KCHRKeyboardMapCount(layout);
  if (keyCount <= 0) {
    return nil;
  }
  keyMap = NSZoneMalloc(nil, (keyCount * mapCount) * sizeof(UniChar));
  
  KCHRKeyboardModifierTable(layout, modifiers);
  
  long keyTrans = 0;
  UInt32 state = 0;
  unsigned char result;
  
  if (pModifiers && mapCount > 0) {
    *pModifiers = NSZoneMalloc(nil, mapCount * sizeof(UInt16));
    int i;
    for (i=0; i<mapCount; i++) {
      (*pModifiers)[i] = modifiers[i] << 8;
    }
  }
  int i;
  int j;
  for (i=0; i<mapCount; i++) { /* for each modifier... */
    UInt16 modifier = modifiers[i] << 8;
    for (j=0; j<keyCount; j++) { /* ...and for each keycode */
      keyTrans = KeyTranslate(layout, j | modifier, &state); /* try to convert */
      if (keyTrans == 0 && state != 0) { /* si result == 0 and deadkey state isn't 0... */
        keyTrans = KeyTranslate(layout, kVirtualSpaceKey, &state); /* ...try to resolve deadkey */
      }
      result = keyTrans;
      if (!result) 
        result = (keyTrans >> 16);
      
      keyMap[(keyCount * i) + j] = ConvertToUnicode(result); /* Convert result into unichar */
    }
  }
  return keyMap;
}

UInt16 UCKeyboardKeyCount(UCKeyboardLayout *layout) {
  UCKeyboardTypeHeader *head = NULL;
  UCKeyToCharTableIndex *tab = NULL;
  LogicalAddress uchr = NULL;
  UInt16 keyCount = 0;
  
  if (layout) {
    head = layout->keyboardTypeList;
    uchr = layout;
  }
  if (head) {
    tab = uchr + head->keyToCharTableIndexOffset;
  }
  if (tab) {
    keyCount = tab->keyToCharTableSize;
  }
  return keyCount;
}

UInt16 UCKeyboardMapCount(UCKeyboardLayout *layout) {
  UInt16 mapCount = 1;
  if (YES == HKUseFullKeyMap) {
    UCKeyboardTypeHeader *head = NULL;
    UCKeyToCharTableIndex *tab = NULL;
    LogicalAddress uchr = NULL;
    
    if (layout) {
      head = layout->keyboardTypeList;
      uchr = layout;
    }
    if (head) {
      tab = uchr + head->keyToCharTableIndexOffset;
    }
    if (tab) {
      mapCount = tab->keyToCharTableCount;
    }
  }
  return mapCount;
}

void UCKeyboardModifierTable(UCKeyboardLayout* layout, UInt16 *modifiers) {
  if (YES == HKUseFullKeyMap) {
    UCKeyboardTypeHeader *head = NULL;
    UCKeyToCharTableIndex *tab = NULL;
    UCKeyModifiersToTableNum *mods = NULL;
    
    LogicalAddress uchr = NULL;
    UInt16 tablesCount = 0;
    ItemCount max = 0;
    UInt8 *map = NULL;
    
    if (layout) {
      head = layout->keyboardTypeList;
      uchr = layout;
    }
    if (head) {
      tab = uchr + head->keyToCharTableIndexOffset;
      mods = uchr + head->keyModifiersToTableNumOffset;
    }
    if (tab && mods) {
      tablesCount = tab->keyToCharTableCount;
      max = mods->modifiersCount;
      map = mods->tableNum;
    }
    if (map) {
      int i;
      for (i=0; i<tablesCount; i++) {
        UInt16 modifier = 0;
        while ((map[modifier] != i) && (modifier < max)) {
          modifier++;
        }
        modifiers[i] = modifier;
      }
    }
  } else {
    modifiers[0] = 0;
  }
}

UniChar* KeyMapForUCKeyboardLayout(UCKeyboardLayout *layout, UInt16 *pModifiers[]) {
  UniChar *keyMap;
  
  UInt32 deadKeyState = 0;
  UniChar unicodeString[2];
  UniCharCount stringLength;
  UInt16 virtualKeyCode;
  UInt16 modifiers[127];
  
  OSStatus err;
  
  UInt16 keyCount = UCKeyboardKeyCount(layout);
  UInt16 mapCount = UCKeyboardMapCount(layout);
  if (keyCount <= 0) {
    return NULL;
  }
  keyMap = NSZoneMalloc(nil, (keyCount * mapCount) * sizeof(UniChar));
  UCKeyboardModifierTable(layout, modifiers);
  
  if (pModifiers && mapCount > 0) {
    *pModifiers = NSZoneMalloc(nil, mapCount * sizeof(UInt16));
    int i;
    for (i=0; i<mapCount; i++) {
      (*pModifiers)[i] = modifiers[i] << 8;
    }
  }
  
  int i;
  for (i=0; i<mapCount; i++) {
    UInt16 modifier = modifiers[i];
    for (virtualKeyCode = 0; virtualKeyCode<keyCount; virtualKeyCode++) {
      err = UCKeyTranslate (layout,
                            virtualKeyCode, kUCKeyActionDown, modifier, // => Modifier 
                            LMGetKbdType(), 0,
                            &deadKeyState,
                            2, &stringLength,
                            unicodeString);
      if (noErr == err) {
        if (stringLength == 0 && deadKeyState != 0) {
          UCKeyTranslate (layout,
                          kVirtualSpaceKey , kUCKeyActionDown, 0, // => Modifier 
                          LMGetKbdType(), kUCKeyTranslateNoDeadKeysMask,
                          &deadKeyState,
                          2, &stringLength,
                          unicodeString);
        }
        if (stringLength > 0) {
          keyMap[(i * keyCount) + virtualKeyCode] = unicodeString[0];
        }
        else {
          keyMap[(i * keyCount) + virtualKeyCode] = kHKNilUnichar;
        }
      }
    }
  }
  return keyMap;
}

UniChar ConvertToUnicode(unsigned char character) {
  OSStatus err;
  UniChar result[4];
  ByteCount len = 0;
  TextEncoding encoding;
  TextToUnicodeInfo info;
  
  err = UpgradeScriptInfoToTextEncoding (smCurrentScript,
                                         kTextLanguageDontCare,
                                         kTextRegionDontCare,
                                         NULL,
                                         &encoding);
  if (noErr == err) {
    err = CreateTextToUnicodeInfoByEncoding (encoding, &info);
  }
  if (noErr == err) {
    ByteCount readed;
    err = ConvertFromTextToUnicode (info, 1, &character,
                                    kUnicodeUseFallbacksMask | kUnicodeLooseMappingsMask,
                                    0, NULL, 0, NULL,
                                    4, &readed, &len,
                                    result);
    DisposeTextToUnicodeInfo(&info);
  }
  if ((noErr == err) && len) {
    return result[0];
  }
  return 0;
}
