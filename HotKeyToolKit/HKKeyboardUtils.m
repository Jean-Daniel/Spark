/*
 *  HKKeyboardUtils.c
 *  HotKeyToolKit
 *
 *  Created by Grayfox.
 *  Copyright 2004-2006 Shadow Lab. All rights reserved.
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

static __inline__
UInt32 __HKUtilsFlatKey(UInt32 code, UInt32 modifier, UInt32 dead) {
  check(code < 128);
  /* Avoid null code */
  /* modifier: modifier use only 16 high bits and 0x3ff00 is 0x3ff << 8 */
  return ((code ? : 0xff) & 0xff) | ((modifier >> 8) & 0x3ff00) | (dead & 0x3fff) << 18;
}
static __inline__
UInt32 __HKUtilsFlatDead(UInt32 flat, UInt32 dead) {
  /* Avoid null code */
  return (flat & 0x3ffff) | ((dead & 0x3fff) << 18);
}
static __inline__
void __HKUtilsDeflatKey(UInt32 key, UInt32 *code, UInt32 *modifier, UInt32 *dead) {
  *code = key & 0xff;
  if (*code == 0xff) *code = 0;
  *modifier = (key & 0x3ff00) << 8;
  *dead = (key >> 18) & 0x3fff;
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

static __inline__
UInt32 __GetModifierCount(UInt8 idx) {
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
void __HKUtilsConvertModifiers(UInt32 *mods, UInt32 count) {
  while (count-- > 0) {
    UInt32 modifier = 0;
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

static UniChar UchrBaseCharacterForKeyCode(UchrContext *ctxt, UInt32 keycode) {
  if (keycode < 128)
    return ctxt->map[keycode];
  return kHKNilUnichar;
}

static UniChar UchrCharacterForKeyCode(UchrContext *ctxt, UInt32 keycode, UInt32 modifiers) {
  UniChar string[3];
  SInt32 type = LMGetKbdType();
  UInt32 deadKeyState = 0, stringLength = 0;
  OSStatus err = UCKeyTranslate (ctxt->layout,
                                 keycode, kUCKeyActionDown, modifiers,
                                 type, 0, &deadKeyState,
                                 3, &stringLength, string);
  if (noErr == err) {
    if (stringLength == 0 && deadKeyState != 0) {
      UCKeyTranslate (ctxt->layout,
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

static UInt32 UchrKeycodesForCharacter(UchrContext *ctxt, UniChar character, UInt32 *keys, UInt32 *modifiers, UInt32 maxsize) {
  UInt32 count = 0;
  UInt32 limit = 10;
  UInt32 ikeys[10];
  UInt32 imodifiers[10];
  
  long chara = character;
  UInt32 k = 0, m = 0, d = 0;
  UInt32 flat = (UInt32)NSMapGet(ctxt->chars, (void *)chara);
  while (flat && count < limit) {
    __HKUtilsDeflatKey(flat, &k, &m, &d);
    ikeys[count] = k;
    imodifiers[count] = m;
    count++;
    if (d) {
      flat = (UInt32)NSMapGet(ctxt->stats, (void *)d);
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

static void UchrContextDealloc(HKKeyMapContext *ctxt) {
  UchrContext *uchr = ctxt->data;
  if (uchr->chars)
    NSFreeMapTable(uchr->chars);
  if (uchr->stats)
    NSFreeMapTable(uchr->stats);  
  free(ctxt->data);
}

static __inline__ 
const UCKeyboardTypeHeader *UCKeyboardHeaderForCurrentKeyboard(const UCKeyboardLayout* layout) {
  unsigned idx = 0;
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
  
  const UCKeyboardTypeHeader *header = UCKeyboardHeaderForCurrentKeyboard(layout);
  const UCKeyToCharTableIndex *tables = data + header->keyToCharTableIndexOffset;
  const UCKeyModifiersToTableNum *modifiers = data + header->keyModifiersToTableNumOffset;

  const UCKeyStateTerminators * terminators = header->keyStateTerminatorsOffset ? data + header->keyStateTerminatorsOffset : NULL;
  
  /* Computer Table to modifiers map */
  UInt32 tmod[tables->keyToCharTableCount];
  memset(tmod, 0xff, tables->keyToCharTableCount * sizeof(UInt32));
  
  unsigned idx = 0;
  /* idx is a modifier combination */
  while (idx < modifiers->modifiersCount) {
    /* get table index */
    unsigned int table = modifiers->tableNum[idx];
    /* check table overflow */
    if (table < tables->keyToCharTableCount) {
      /* try to find combination with minimum keys */
      if (__GetModifierCount(tmod[table]) > __GetModifierCount(idx))
          tmod[table] = idx;
    } else {
      /* Table overflow, should not append */
      NSLog(@"WARNING: invalid table idx: %u", idx);
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
  for (idx=0; idx < tables->keyToCharTableCount; idx++) { 
    unsigned key = 0;
    const UCKeyOutput *output = data + tables->keyToCharTableOffsets[idx];
    while (key < tables->keyToCharTableSize) {
      if (output[key] >= 0xFFFE) {
        // Illegal character => no output, skip it
      } else {
        if (output[key] & (1 << 14)) {
          long state = output[key] & 0x3fff;
          // State record. save it into deadr table
          NSMapInsertIfAbsent(deadr, (void *)state, (void *)__HKUtilsFlatKey(key, tmod[idx], 0));
          
          /* for table without modifiers only */
          if (tmod[idx] == 0 && key < 128) {
            if (state > 0 && state < terminators->keyStateTerminatorCount) {
              UniChar unicode = terminators->keyStateTerminators[state - 1];
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
            long unicode = output[key];
            NSMapInsertIfAbsent(map, (void *)unicode, (void *)__HKUtilsFlatKey(key, tmod[idx], 0));
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
    for (idx=0; idx < records->keyStateRecordCount; idx++) {
      UInt32 code = (UInt32)NSMapGet(deadr, (void *)idx);
      if (0 == code) {
        NSLog(@"Unreachable block: %u", idx);
      } else {
        const UCKeyStateRecord *record = data + records->keyStateRecordOffsets[idx];
        if (record->stateZeroCharData != 0 && record->stateZeroNextState == 0) {
          long unicode = record->stateZeroCharData;
          if (unicode & (1 << 15)) {
            // Warning: sequence
          } else {
            if (map) {
              /* Get keycode to access record idx */
              NSMapInsertIfAbsent(map, (void *)unicode, (void *)code);
            } 
            /* Update fast table map */
            UInt32 k = 0, m = 0, d = 0;
            __HKUtilsDeflatKey(code, &k, &m, &d);
            if (0 == m && kHKNilUnichar == uchr->map[k]) {
              uchr->map[k] = unicode;
            }
          }
        } else if ((record->stateZeroCharData == 0 || record->stateZeroCharData >= 0xFFFE) && record->stateZeroNextState != 0) {
          // No output and next state not null
          if (dead) {
            long next = record->stateZeroNextState;
            // Map dead state to keycode
            NSMapInsertIfAbsent(dead, (void *)next, (void *)code);
          }
        } 
        // Browse all record output
        if (reverse) {
          unsigned entry = 0;
          if (kUCKeyStateEntryTerminalFormat == record->stateEntryFormat) {
            const UCKeyStateEntryTerminal *term = (const void *)record->stateEntryData;
            while (entry < record->stateEntryCount) {
              long unicode = term->charData;
              // Should resolve sequence
              if (unicode & (1 << 15)) {
                //DLog(@"WARNING: Sequence: %u", unicode & 0x3fff);
              } else {
                // Get previous keycode and append dead key state
                code = __HKUtilsFlatDead(code, term->curState);
                NSMapInsertIfAbsent(map, (void *)unicode, (void *)code);
              }
              term++;
              entry++;
            }
          } else if (kUCKeyStateEntryRangeFormat == record->stateEntryFormat) {
            NSLog(@"WARNING: Range entry not implemented");
          }
        } /* reverse */
      }
    }
  }
  uchr->chars = map;
  uchr->stats = dead;
  NSFreeMapTable(deadr);
  
  return noErr;
}

#pragma mark -
#pragma mark KCHR
typedef struct _KCHRContext {
  UniChar map[128];
  UInt32 *stats;
  NSMapTable *chars;
  UniChar unicode[256];
  const void *layout;
} KCHRContext;

static void KCHRContextDealloc(HKKeyMapContext *ctxt) {
  KCHRContext *kchr = ctxt->data;
  if (kchr->chars)
    NSFreeMapTable(kchr->chars);
  if (kchr->stats)
    free(kchr->stats);  
  free(ctxt->data);
}

static UniChar KCHRBaseCharacterForKeyCode(KCHRContext *ctxt, UInt32 keycode) {
  if (keycode < 128)
    return ctxt->map[keycode];
  return kHKNilUnichar;
}

static UniChar KCHRCharacterForKeyCode(KCHRContext *ctxt, UInt32 keycode, UInt32 modifiers) {
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

static UInt32 KCHRKeycodesForCharacter(KCHRContext *ctxt, UniChar character, UInt32 *keys, UInt32 *modifiers, UInt32 maxsize) {
  UInt32 count = 0;
  UInt32 ikeys[2];
  UInt32 imodifiers[2];
  
  long chara = character;
  UInt32 k = 0, m = 0, d = 0;
  UInt32 flat = (UInt32)NSMapGet(ctxt->chars, (void *)chara);
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

static NSMapTable *UpgradeToUnicode(ScriptCode script, UInt32 *keys, UInt32 count, UniChar *umap, Boolean reverse);

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
  UInt32 tmod[count];
  memset(tmod, 0xff, count * sizeof(UInt32));
  
  unsigned idx = 0;
  UInt8 *tableNum = (UInt8 *)(data + 2); // version (2)
  /* idx is a modifier combination */
  while (idx < 256) {
    /* get table index */
    unsigned char table = tableNum[idx];
    /* check table overflow */
    if (table < count) {
      /* try to find combination with minimum keys */
      if (__GetModifierCount(tmod[table]) > __GetModifierCount(idx))
        tmod[table] = idx;
    } else {
      /* Table overflow, should not append */
      DLog(@"WARNING: invalid table idx: %u", table);
    }
    idx++;
  }
  __HKUtilsConvertModifiers(tmod, count);
  
  UInt32 charToKey[256];
  bzero(charToKey, 256 * sizeof(UInt32));
  
  /* Foreach key in each table */
  for (idx=0; idx < count; idx++) { 
    unsigned key = 0;
    const unsigned char *output = data + 260 + (128 * idx); // version (2) + map table (256) + map count (2)
    while (key < 128) {
      if (output[key] != 0) {
        //not a dead key state
        if (0 == charToKey[output[key]]) {
          /* Insert if absent */
          charToKey[output[key]] = __HKUtilsFlatKey(key, tmod[idx], 0);
        }
        // Save it into simple mapping table
        if (tmod[idx] == 0)
          kchr->map[key] = output[key];
      }
      key++;
    }
  }
  
  const UInt8 *record = data + 260 + (128 * count) + 2;
  UInt16 records =  *((UInt16 *)(data + 260 + (128 * count)));
  
  kchr->stats = records ? malloc(sizeof(UInt32) * records) : NULL;
  
  for (idx=0; idx < records; idx++) {
    UInt16 size = *((UInt16 *)(record + 2));
    UInt8 table = *record;
    UInt8 key = *(record + 1);
    if (table < count) {
      kchr->stats[idx] = __HKUtilsFlatKey(key, tmod[table], 0);
    } else {
      NSLog(@"Warning: table %i out of bound", table);
    }
    const struct {
      UInt8 previous;
      UInt8 output;
    } *entry = (void *)(record + 4);
    if (reverse) {
      int i;
      for (i=0; i < size; i++) {
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
    /* Save terminator into fast map. Terminator is registred in first entry byte (entry->previous, not entry->output) */
    if (tmod[table] == 0 && kchr->map[key] == kHKNilUnichar && (entry->output != 0 || entry->previous != 0)) {
      kchr->map[key] = entry->output ? : entry->previous;
    }
    /* advance to next record */
    record = record + 4 + (size * 2) + 2;
  }
  
  /* Now we have to convert char table into unicode */
  kchr->chars = UpgradeToUnicode(smCurrentScript, charToKey, 256, kchr->unicode, reverse);
  /* Upgrade fast map to unicode */
  for (idx=0; idx < 128; idx++) {
    if (kchr->map[idx] != kHKNilUnichar && kchr->map[idx] < 256)
      kchr->map[idx] = kchr->unicode[kchr->map[idx]];
  }
  return noErr;
}

#pragma mark -
NSMapTable *UpgradeToUnicode(ScriptCode script, UInt32 *keys, UInt32 count, UniChar *umap, Boolean reverse) {
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
    unsigned idx = 0;
    for (idx = 0; idx < count; idx++) {
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
          NSLog(@"Unable to convert char (%i): 0x%x, len: %u", err, idx, len);
        }
      }
    }
    DisposeTextToUnicodeInfo(&info);
  }
  
  return map;
}
