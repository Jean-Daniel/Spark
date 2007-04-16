/*
 *  HKKeyboardUtils.c
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#include <Carbon/Carbon.h>
#import "HKKeyMap.h"
#import "HKKeyboardUtils.h"

#pragma mark Flat and deflate
/* Flat format: 
-----------------------------------------------------------------
| dead state (14 bits) | modifiers (10 bits) | keycode (8 bits) |
-----------------------------------------------------------------
Note: keycode = 0xff => keycode is 0.
*/

HK_INLINE
NSInteger __HKUtilsFlatKey(HKKeycode code, HKModifier modifier, UInt32 dead) {
  check(code < 128);
  /* Avoid null code */
  /* modifier: modifier use only 16 high bits and 0x3ff00 is 0x3ff << 8 */
  return ((code ? : 0xff) & 0xff) | ((modifier >> 8) & 0x3ff00) | (dead & 0x3fff) << 18;
}
HK_INLINE
NSInteger __HKUtilsFlatDead(NSInteger flat, UInt32 dead) {
  /* Avoid null code */
  return (flat & 0x3ffff) | ((dead & 0x3fff) << 18);
}
HK_INLINE
void __HKUtilsDeflatKey(NSInteger flat, HKKeycode *code, HKModifier *modifier, UInt32 *dead) {
  *code = flat & 0xff;
  if (*code == 0xff) *code = 0;
  *modifier = (UInt32)(flat & 0x3ff00) << 8;
  *dead = (UInt32)(flat >> 18) & 0x3fff;
}


HK_INLINE
void __HKUtilsNormalizeEndOfLine(NSMapTable *map) {
  /* Patch to correctly handle new line */
  HKKeycode mack; HKModifier macm; UInt32 macd;
  NSInteger mac = (NSInteger)NSMapGet(map, (void *)'\r');
  __HKUtilsDeflatKey(mac, &mack, &macm, &macd);
  
  HKKeycode unixk; HKModifier unixm; UInt32 unixd;
  NSInteger unix = (NSInteger)NSMapGet(map, (void *)'\n');
  __HKUtilsDeflatKey(unix, &unixk, &unixm, &unixd);
  
  /* If 'mac return' use modifier or dead key and unix not */
  if ((!mac || macm || macd) && (unix && !unixm && !unixd)) {
    NSMapInsert(map, (void *)'\r', (void *)unix);
  } else if ((!unix || unixm || unixd) && (mac && !macm && !macd)) {
    NSMapInsert(map, (void *)'\n', (void *)mac);
  }
}

#pragma mark Modifiers
enum {
  kCommandKey = 1 << 0,
  kShiftKey = 1 << 1,
  kCapsKey = 1 << 2,
  kOptionKey = 1 << 3,
  kControlKey = 1 << 4,
  kRightShiftKey = 1 << 5,
  kRightOptionKey = 1 << 6,
  kRightControlKey = 1 << 7,
};

HK_INLINE
UInt32 __GetModifierCount(NSUInteger idx) {
  UInt32 count = 0;
  if (idx & kCommandKey) count++;
  if (idx & kShiftKey) count++;
  if (idx & kCapsKey) count++;
  if (idx & kOptionKey) count++;
  if (idx & kControlKey) count++;
  if (idx & kRightShiftKey) count++;
  if (idx & kRightOptionKey) count++;
  if (idx & kRightControlKey) count++;
  return count;
}

static 
void __HKUtilsConvertModifiers(NSUInteger *mods, UInt32 count) {
  while (count-- > 0) {
    HKModifier modifier = 0;
    if (mods[count] & kCommandKey) modifier |= kCGEventFlagMaskCommand;
    if (mods[count] & kShiftKey) modifier |= kCGEventFlagMaskShift;
    if (mods[count] & kCapsKey) modifier |= kCGEventFlagMaskAlphaShift;
    if (mods[count] & kOptionKey) modifier |= kCGEventFlagMaskAlternate;
    if (mods[count] & kControlKey) modifier |= kCGEventFlagMaskControl;
    /* Should not append */
    if (mods[count] & kRightShiftKey) modifier |= kCGEventFlagMaskShift;
    if (mods[count] & kRightOptionKey) modifier |= kCGEventFlagMaskAlternate;
    if (mods[count] & kRightControlKey) modifier |= kCGEventFlagMaskControl;
    
    mods[count] = modifier;
  }
}

#pragma mark -
#pragma mark UCHR
typedef struct _UchrContext {
  UniChar map[128];
  NSMapTable *chars;
  NSMapTable *stats;
  const UCKeyboardLayout *layout;
} UchrContext;

static
UniChar UchrBaseCharacterForKeyCode(UchrContext *ctxt, HKKeycode keycode) {
  if (keycode < 128) {
    return ctxt->map[keycode];
  }
  return kHKNilUnichar;
}

static 
UniChar UchrCharacterForKeyCodeAndKeyboard(const UCKeyboardLayout *layout, HKKeycode keycode, HKModifier modifiers) {
  UniChar string[3];
  SInt32 type = LMGetKbdType();
  UInt32 deadKeyState = 0;
  UniCharCount stringLength = 0;
  OSStatus err = UCKeyTranslate (layout,
                                 keycode, kUCKeyActionDown, modifiers,
                                 type, 0, &deadKeyState,
                                 3, &stringLength, string);
  if (noErr == err) {
    if (stringLength == 0 && deadKeyState != 0) {
      UCKeyTranslate (layout,
                      kVirtualSpaceKey , kUCKeyActionDown, 0, // => No Modifier 
                      type, kUCKeyTranslateNoDeadKeysMask, &deadKeyState,
                      3, &stringLength, string);
    }
    if (stringLength > 0) {
      return string[0];
    }
  }    
  return kHKNilUnichar;
}

static
UniChar UchrCharacterForKeyCode(UchrContext *ctxt, HKKeycode keycode, HKModifier modifiers) {
  return UchrCharacterForKeyCodeAndKeyboard(ctxt->layout, keycode, modifiers);
}

static
NSUInteger UchrKeycodesForCharacter(UchrContext *ctxt, UniChar character, HKKeycode *keys, HKModifier *modifiers, NSUInteger maxsize) {
  NSUInteger count = 0;
  NSUInteger limit = 10;
  HKKeycode ikeys[10];
  HKModifier imodifiers[10];
  
  UInt32 d = 0;
  HKKeycode k = 0;
  HKModifier m = 0;
  NSInteger flat = (NSInteger)NSMapGet(ctxt->chars, (void *)(intptr_t)character);
  while (flat && count < limit) {
    __HKUtilsDeflatKey(flat, &k, &m, &d);
    ikeys[count] = k;
    imodifiers[count] = m;
    count++;
    if (d) {
      flat = (NSInteger)NSMapGet(ctxt->stats, (void *)(intptr_t)d);
    } else {
      flat = 0;
    }
  }
  NSUInteger idx = 0;
  while (idx < count && idx < maxsize) {
    keys[idx] = ikeys[count - idx - 1];
    modifiers[idx] = imodifiers[count - idx - 1];
    idx++;
  }
  return count;
}

static 
void UchrContextDealloc(HKKeyMapContext *ctxt) {
  UchrContext *uchr = ctxt->data;
  if (uchr->chars)
    NSFreeMapTable(uchr->chars);
  if (uchr->stats)
    NSFreeMapTable(uchr->stats);  
  free(ctxt->data);
}

HK_INLINE 
const UCKeyboardTypeHeader *__UCKeyboardHeaderForCurrentKeyboard(const UCKeyboardLayout* layout) {
  NSUInteger idx = 0;
  UInt8 kbType = LMGetKbdType();
  const UCKeyboardTypeHeader *head = layout->keyboardTypeList;
  while (idx < layout->keyboardTypeCount) {
    if (layout->keyboardTypeList[idx].keyboardTypeFirst <= kbType && layout->keyboardTypeList[idx].keyboardTypeLast >= kbType) {
      head = &layout->keyboardTypeList[idx];
      break;
    }
    idx++;
  }
  return head;
}

#pragma mark -
OSStatus HKKeyMapContextWithUchrData(const UCKeyboardLayout *layout, Boolean reverse, HKKeyMapContext *ctxt) {
  ctxt->dealloc = UchrContextDealloc;
  ctxt->baseMap = (HKBaseCharacterForKeyCodeFunction)UchrBaseCharacterForKeyCode;
  ctxt->fullMap = (HKCharacterForKeyCodeFunction)UchrCharacterForKeyCode;
  ctxt->reverseMap = (HKKeycodesForCharacterFunction)UchrKeycodesForCharacter;
  
  // Allocate UCHR Context
  ctxt->data = calloc(1, sizeof(UchrContext));
  UchrContext *uchr = (UchrContext *)ctxt->data;
  uchr->layout = layout;
  /* set nil unichar in all blocks */
  memset(uchr->map, 0xff, sizeof(uchr->map));
  
  // Load table and reverse table
  const void *data = layout;
  
  const UCKeyboardTypeHeader *header = __UCKeyboardHeaderForCurrentKeyboard(layout);
  const UCKeyToCharTableIndex *tables = data + header->keyToCharTableIndexOffset;
  const UCKeyModifiersToTableNum *modifiers = data + header->keyModifiersToTableNumOffset;

  const UCKeyStateTerminators * terminators = header->keyStateTerminatorsOffset ? data + header->keyStateTerminatorsOffset : NULL;
  
  /* Computer Table to modifiers map */
  NSUInteger tmod[tables->keyToCharTableCount];
  memset(tmod, 0xff, tables->keyToCharTableCount * sizeof(*tmod));
  
  NSUInteger idx = 0;
  /* idx is a modifier combination */
  while (idx < modifiers->modifiersCount) {
    /* get table index */
    NSUInteger table = modifiers->tableNum[idx];
    /* check table overflow */
    if (table < tables->keyToCharTableCount) {
      /* try to find combination with minimum keys */
      if (__GetModifierCount(tmod[table]) > __GetModifierCount(idx))
          tmod[table] = idx;
    } else {
      /* Table overflow, should not append */
      WCLog("Invalid Keyboard layout, table %tu does not exists", idx);
    }
    idx++;
  }
  __HKUtilsConvertModifiers(tmod, tables->keyToCharTableCount);
  
  /* Map contains a character to keycode +  dead state mapping */
  NSMapTable *map = reverse ? NSCreateMapTable(NSIntMapKeyCallBacks, NSIntMapValueCallBacks, 0) : NULL;
  /* Dead contains a dead state to keycode + dead state mapping */
  NSMapTable *dead = reverse ? NSCreateMapTable(NSIntMapKeyCallBacks, NSIntMapValueCallBacks, 0) : NULL;
  
  /* Deadr is a temporary map that map deadkey record index to keycode */
  NSMapTable *deadr = NSCreateMapTable(NSIntMapKeyCallBacks, NSIntMapValueCallBacks, 0);
  
  /* Foreach key in each table */
  for (idx = 0; idx < tables->keyToCharTableCount; idx++) { 
    NSUInteger key = 0;
    const UCKeyOutput *output = data + tables->keyToCharTableOffsets[idx];
    while (key < tables->keyToCharTableSize) {
      if (output[key] >= 0xFFFE) {
        // Illegal character => no output, skip it
      } else {
        if (output[key] & (1 << 14)) {
          NSUInteger state = output[key] & 0x3fff;
          // State record. save it into deadr table
          NSMapInsertIfAbsent(deadr, (void *)state, (void *)__HKUtilsFlatKey(key, (HKModifier)tmod[idx], 0));
          
          /* for table without modifiers only */
          if (tmod[idx] == 0 && key < 128) {
            if (state >= 0 && state < terminators->keyStateTerminatorCount) {
              UniChar unicode = terminators->keyStateTerminators[state];
              if (unicode & (1 << 15)) {
                // Sequence
                unicode = kHKNilUnichar;
              }
              uchr->map[key] = unicode;
            } else {
              uchr->map[key] = kHKNilUnichar;
            }
          }
        } else if (output[key] & (1 << 15)) {
          // Sequence record. Useless for reverse mapping, so ignore it
          // Maybe check if sequence contains only one char.
        } else {
          if (map) {
            // Simple unichar output. Save it into map table.
            UniChar unicode = output[key];
            NSMapInsertIfAbsent(map, (void *)(intptr_t)unicode, (void *)__HKUtilsFlatKey(key, (HKModifier)tmod[idx], 0));
          }
          // Save it into simple mapping table
          if (tmod[idx] == 0 && key < 128)
            uchr->map[key] = output[key];
        }
      }
      key++;
    }
  }
  
  /* handle deadstate record */
  if (header->keyStateRecordsIndexOffset) {
    const UCKeyStateRecordsIndex *records = data + header->keyStateRecordsIndexOffset;
    for (idx = 0; idx < records->keyStateRecordCount; idx++) {
      NSUInteger code = (NSUInteger)NSMapGet(deadr, (void *)idx);
      if (0 == code) {
        WCLog("Unreachable block: %tu", idx);
      } else {
        const UCKeyStateRecord *record = data + records->keyStateRecordOffsets[idx];
        if (record->stateZeroCharData != 0 && record->stateZeroNextState == 0) {
          UniChar unicode = record->stateZeroCharData;
          if (unicode & (1 << 15)) {
            // Warning: sequence
          } else {
            if (map) {
              /* Get keycode to access record idx */
              NSMapInsertIfAbsent(map, (void *)(intptr_t)unicode, (void *)(intptr_t)code);
            } 
            /* Update fast table map */
            UInt32 d;
            HKKeycode k = 0;
            HKModifier m = 0;
            __HKUtilsDeflatKey(code, &k, &m, &d);
            if (0 == m && kHKNilUnichar == uchr->map[k]) {
              uchr->map[k] = unicode;
            }
          }
        } else if ((record->stateZeroCharData == 0 || record->stateZeroCharData >= 0xFFFE) && record->stateZeroNextState != 0) {
          // No output and next state not null
          if (dead) {
            NSUInteger next = record->stateZeroNextState;
            // Map dead state to keycode
            NSMapInsertIfAbsent(dead, (void *)next, (void *)(intptr_t)code);
          }
        } 
        // Browse all record output
        if (reverse && record->stateEntryCount) {
          NSUInteger entry = 0;
          if (kUCKeyStateEntryTerminalFormat == record->stateEntryFormat) {
            const UCKeyStateEntryTerminal *term = (const void *)record->stateEntryData;
            while (entry < record->stateEntryCount) {
              UniChar unicode = term->charData;
              // Should resolve sequence
              if (unicode & (1 << 15)) {
                //DLog(@"WARNING: Sequence: %u", unicode & 0x3fff);
              } else {
                // Get previous keycode and append dead key state
                code = __HKUtilsFlatDead(code, term->curState);
                NSMapInsertIfAbsent(map, (void *)(intptr_t)unicode, (void *)(intptr_t)code);
              }
              term++;
              entry++;
            }
          } else if (kUCKeyStateEntryRangeFormat == record->stateEntryFormat) {
            WCLog("Range entry not implemented");
          }
        } // reverse
      }
    }
  }
  
  if (map) {
    __HKUtilsNormalizeEndOfLine(map);
  }
  
  uchr->chars = map;
  uchr->stats = dead;
  NSFreeMapTable(deadr);
  
  return noErr;
}

#pragma mark -
#pragma mark KCHR

/* KCHR does not exist in 64 bits */
#if !__LP64__
typedef struct _KCHRContext {
  UniChar map[128];
  UInt32 *stats;
  NSMapTable *chars;
  UniChar unicode[256];
  const void *layout;
} KCHRContext;

static
void KCHRContextDealloc(HKKeyMapContext *ctxt) {
  KCHRContext *kchr = ctxt->data;
  if (kchr->chars)
    NSFreeMapTable(kchr->chars);
  if (kchr->stats)
    free(kchr->stats);  
  free(ctxt->data);
}

static
UniChar KCHRBaseCharacterForKeyCode(KCHRContext *ctxt, HKKeycode keycode) {
  if (keycode < 128)
    return ctxt->map[keycode];
  return kHKNilUnichar;
}

static
UniChar KCHRCharacterForKeyCode(KCHRContext *ctxt, HKKeycode keycode, HKModifier modifiers) {
  UInt32 state = 0;
  UInt32 keyTrans = 0;
  unsigned char result;
  keyTrans = KeyTranslate(ctxt->layout, keycode | modifiers, &state); /* try to convert */
  /* si result == 0 and deadkey state isn't 0... */
  if (keyTrans == 0 && state != 0) { 
    /* ...try to resolve deadkey */
    keyTrans = KeyTranslate(ctxt->layout, kVirtualSpaceKey, &state);
  }
  result = keyTrans;
  if (!result) 
    result = (keyTrans >> 16);
  
  return ctxt->unicode[result];
}

static
NSUInteger KCHRKeycodesForCharacter(KCHRContext *ctxt, UniChar character, HKKeycode *keys, HKModifier *modifiers, NSUInteger maxsize) {
  NSUInteger count = 0;
  HKKeycode ikeys[2];
  HKModifier imodifiers[2];
  
  UInt32 d;
  HKKeycode k = 0;
  HKModifier m = 0;
  NSUInteger flat = (NSUInteger)NSMapGet(ctxt->chars, (void *)(intptr_t)character);
  while (flat && count < 2) {
    __HKUtilsDeflatKey(flat, &k, &m, &d);
    ikeys[count] = k;
    imodifiers[count] = m;
    count++;
    if (d) {
      flat = ctxt->stats[d];
    } else {
      flat = 0;
    }
  }
  UInt32 idx = 0;
  while (idx < count && idx < maxsize) {
    keys[idx] = ikeys[count - idx - 1];
    modifiers[idx] = imodifiers[count - idx - 1];
    idx++;
  }
  return count;
}

static 
NSMapTable *_UpgradeToUnicode(ScriptCode script, UInt32 *keys, UInt32 count, UniChar *umap, Boolean reverse);

#pragma mark -
OSStatus HKKeyMapContextWithKCHRData(const void *layout, Boolean reverse, HKKeyMapContext *ctxt) {
  ctxt->dealloc = KCHRContextDealloc;
  ctxt->baseMap = (HKBaseCharacterForKeyCodeFunction)KCHRBaseCharacterForKeyCode;
  ctxt->fullMap = (HKCharacterForKeyCodeFunction)KCHRCharacterForKeyCode;
  ctxt->reverseMap = (HKKeycodesForCharacterFunction)KCHRKeycodesForCharacter;

  // Allocate KCHR Context
  ctxt->data = calloc(1, sizeof(KCHRContext));
  KCHRContext *kchr = (KCHRContext *)ctxt->data;
  kchr->layout = layout;
  /* set nil unichar in all blocks */
  memset(kchr->map, 0xff, sizeof(kchr->map));
  memset(kchr->unicode, 0xff, sizeof(kchr->unicode));
  
  // Load table and reverse table
  const void *data = layout;
  
  UInt16 count = *((UInt16 *)(data + 258)); // version (2) + map table (256)
  
  /* Computer Table to modifiers map */
  NSUInteger tmod[count];
  memset(tmod, 0xff, count * sizeof(*tmod));
  
  NSUInteger idx = 0;
  UInt8 *tableNum = (UInt8 *)(data + 2); // version (2)
  /* idx is a modifier combination */
  while (idx < 256) {
    /* get table index */
    NSUInteger table = tableNum[idx];
    /* check table overflow */
    if (table < count) {
      /* try to find combination with minimum keys */
      if (__GetModifierCount(tmod[table]) > __GetModifierCount(idx))
        tmod[table] = idx;
    } else {
      /* Table overflow, should not append */
      WCLog("Invalid Keyboard layout, table %tu does not exists", table);
    }
    idx++;
  }
  __HKUtilsConvertModifiers(tmod, count);
  
  UInt32 charToKey[256];
  bzero(charToKey, 256 * sizeof(*charToKey));
  
  /* Foreach key in each table */
  for (idx = 0; idx < count; idx++) { 
    NSUInteger key = 0;
    const unsigned char *output = data + 260 + (128 * idx); // version (2) + map table (256) + map count (2)
    while (key < 128) {
      if (output[key] != 0) {
        //not a dead key state
        if (0 == charToKey[output[key]]) {
          /* Insert if absent */
          charToKey[output[key]] = __HKUtilsFlatKey(key, (HKModifier)tmod[idx], 0);
        }
        // Save it into simple mapping table
        if (0 == tmod[idx])
          kchr->map[key] = output[key];
      }
      key++;
    }
  }
  
  const UInt8 *record = data + 260 + (128 * count) + 2;
  UInt16 records =  *((UInt16 *)(data + 260 + (128 * count)));
  
  kchr->stats = records ? malloc(sizeof(*kchr->stats) * records) : NULL;
  
  for (idx = 0; idx < records; idx++) {
    UInt16 size = *((UInt16 *)(record + 2));
    UInt8 table = *record;
    UInt8 key = *(record + 1);
    if (table < count) {
      kchr->stats[idx] = __HKUtilsFlatKey(key, (HKModifier)tmod[table], 0);
    } else {
      WCLog("Invalid Keyboard layout, table %hhu does not exists", table);
    }
    const struct {
      UInt8 previous;
      UInt8 output;
    } *entry = (void *)(record + 4);
    if (reverse) {
      for (NSInteger i = 0; i < size; i++) {
        /* If previous has an entry in table and output has currently no entry */
        if (charToKey[entry->previous] != 0 && charToKey[entry->output] == 0) {
          /* add a new entry: output = previous + dead state index */
          charToKey[entry->output] = __HKUtilsFlatDead(charToKey[entry->previous], idx);
        }
        entry++;
      }
    } else {
      entry += size;
    }
    /* Save terminator into fast map. Terminator is registred in one of the two field (ppc/x86 not the same) */
    if (0 == tmod[table] && kchr->map[key] == kHKNilUnichar && (entry->output != 0 || entry->previous != 0)) {
      kchr->map[key] = entry->output ? : entry->previous;
    }
    /* advance to next record */
    record = record + 4 + (size * 2) + 2;
  }
  
  /* Now we have to convert char table into unicode */
  kchr->chars = _UpgradeToUnicode(smCurrentScript, charToKey, 256, kchr->unicode, reverse);
  /* Upgrade fast map to unicode */
  for (idx = 0; idx < 128; idx++) {
    if (kchr->map[idx] != kHKNilUnichar && kchr->map[idx] < 256)
      kchr->map[idx] = kchr->unicode[kchr->map[idx]];
  }
  
  /* Check end of lines */
  if (kchr->chars)
    __HKUtilsNormalizeEndOfLine(kchr->chars);
  
  return noErr;
}

#pragma mark -
NSMapTable *_UpgradeToUnicode(ScriptCode script, UInt32 *keys, UInt32 count, UniChar *umap, Boolean reverse) {
  OSStatus err;
  UniChar result[4];
  ByteCount len = 0;
  TextEncoding encoding;
  TextToUnicodeInfo info;

  NSMapTable *map = reverse ? NSCreateMapTable(NSIntMapKeyCallBacks, NSIntMapValueCallBacks, 0) : NULL;
      
  err = UpgradeScriptInfoToTextEncoding(script,
                                        kTextLanguageDontCare,
                                        kTextRegionDontCare,
                                        NULL,
                                        &encoding);
  if (noErr == err) {
    err = CreateTextToUnicodeInfoByEncoding (encoding, &info);
  }
  if (noErr == err) {
    for (NSUInteger idx = 0; idx < count; idx++) {
      /* If has a valid mapping entry */
      if (keys[idx] != 0) {
        ByteCount readed;
        UInt8 character = idx;
        /* Convert character 'idx' */
        err = ConvertFromTextToUnicode(info, 1, &character,
                                       kUnicodeUseFallbacksMask,
                                       0, NULL, 0, NULL,
                                       4, &readed, &len,
                                       result);
        if (noErr == err && len == 2) {
          UniChar chr = result[0];
          if (umap) umap[idx] = chr;
          if (map) {
            long k = chr, v = keys[idx];
            NSMapInsertIfAbsent(map, (void *)k, (void *)v);
          }
        } else {
          WCLog("Unable to convert char (%d): 0x%x, len: %lu", (int32_t)err, idx, len);
        }
      }
    }
    DisposeTextToUnicodeInfo(&info);
  }
  
  return map;
}

#endif /* __LP64__ */
