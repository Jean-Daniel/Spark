/*
 *  HKKeyMap.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2008 Shadow Lab. All rights reserved.
 */

#import "HKKeyMap.h"
#import "KeyMap.h"

HK_INLINE
NSString *SpecialChar(UniChar ch) {
  return [NSString stringWithCharacters:&ch length:1]; 
}

#define kHotKeyToolKitBundleIdentifier @"org.shadowlab.HotKeyToolKit"
#define kHotKeyToolKitBundle           [NSBundle bundleWithIdentifier:kHotKeyToolKitBundleIdentifier]

const UniChar kHKNilUnichar = 0xffff;

static
HKKeyMapRef SharedKeyMap() {
  static HKKeyMapRef sharedKeyMap = nil;
  if (!sharedKeyMap) {
    sharedKeyMap = HKKeyMapCreateWithCurrentLayout(YES);
    if (!sharedKeyMap) {
      DLog(@"Error while initializing Keyboard Map");
    } else {
      DLog(@"Keyboard Map initialized");
    }
  }
  return sharedKeyMap;
}

#pragma mark -
#pragma mark Statics Functions Declaration
static 
HKKeycode HKMapGetSpecialKeyCodeForCharacter(UniChar charCode);
static 
UniChar HKMapGetSpecialCharacterForKeycode(HKKeycode keycode);

static
NSString *HKMapGetModifierString(HKModifier mask);
static
NSString *HKMapGetSpeakableModifierString(HKModifier mask);
static
NSString *HKMapGetStringForUnichar(UniChar unicode);

#pragma mark -
#pragma mark Publics Functions Definition
UniChar HKMapGetUnicharForKeycode(HKKeycode keycode) {
  UniChar unicode = HKMapGetSpecialCharacterForKeycode(keycode);
  if (kHKNilUnichar == unicode)
    unicode = HKKeyMapGetUnicharForKeycode(SharedKeyMap(), keycode);
  return unicode;
}

NSString *HKMapGetCurrentMapName() {
  return (NSString *)HKKeyMapGetName(SharedKeyMap());
}

NSString *HKMapGetStringRepresentationForCharacterAndModifier(UniChar character, HKModifier modifier) {
  if (character && character != kHKNilUnichar) {
    NSString *str = nil;
    NSString *mod = HKMapGetModifierString(modifier);
    if (modifier & kCGEventFlagMaskNumericPad) {
      if (character >= '0' && character <= '9') {
        UniChar chrs[2] = { character, '*' };
        str = [NSString stringWithCharacters:chrs length:2];
      }
    }
    if ([mod length] > 0) {
      return [mod stringByAppendingString:str ? : HKMapGetStringForUnichar(character)];
    } else {
      return str ? : HKMapGetStringForUnichar(character);
    }
  }
  return nil;
}

NSString *HKMapGetSpeakableStringRepresentationForCharacterAndModifier(UniChar character, HKModifier modifier) {
  if (character && character != kHKNilUnichar) {
    NSString *mod = HKMapGetSpeakableModifierString(modifier);
    if ([mod length] > 0) {
      return [NSString stringWithFormat:@"%@ + %@", mod, HKMapGetStringForUnichar(character)];
    } else {
      return HKMapGetStringForUnichar(character);
    }
  }
  return nil;
}

#pragma mark Reverse Mapping
HKKeycode HKMapGetKeycodeAndModifierForUnichar(UniChar character, HKModifier *modifier) {
  if (kHKNilUnichar == character)
    return kHKInvalidVirtualKeyCode;
  HKKeycode key[4];
  HKModifier mod[4];
  NSUInteger cnt = HKMapGetKeycodesAndModifiersForUnichar(character, key, mod, 4);
  /* if not found, or need more than 2 keystroke */
  if (!cnt || cnt > 2 || kHKInvalidVirtualKeyCode == key[0])
    return kHKInvalidVirtualKeyCode;
  
  /* dead key: the second keycode is space key */
  if (cnt == 2 && key[1] != kHKVirtualSpaceKey)
    return kHKInvalidVirtualKeyCode;
  
  if (modifier) *modifier = mod[0];
  
  return key[0];
}

NSUInteger HKMapGetKeycodesAndModifiersForUnichar(UniChar character, HKKeycode *keys, HKModifier *modifiers, NSUInteger maxcount) {
  NSUInteger count = 0;
  if (character != kHKNilUnichar) {
    HKKeycode keycode = HKMapGetSpecialKeyCodeForCharacter(character);
    if (keycode == kHKInvalidVirtualKeyCode) {
      count = HKKeyMapGetKeycodesForUnichar(SharedKeyMap(), character, keys, modifiers, maxcount);
    } else {
      count = 1;
      if (maxcount > 0) {
        if (keys) keys[0] = keycode & 0xffff;
        if (modifiers) modifiers[0] = 0;
      }
    }
  }
  return count;
}

#pragma mark Functions Keys
bool HKMapIsFunctionKey(HKKeycode code) {
  UniChar chr = HKMapGetSpecialCharacterForKeycode(code);
  if (kHKNilUnichar != chr)
    return HKMapIsFunctionKeyForCharacter(chr);
  return false;
}

bool HKMapIsFunctionKeyForCharacter(UniChar chr) {
  return 0xF700 <= chr && chr <= 0xF8FF;
}

#pragma mark -
#pragma mark Statics Functions Definition
HKKeycode HKMapGetSpecialKeyCodeForCharacter(UniChar character) {
  HKKeycode keyCode = kHKInvalidVirtualKeyCode;
  switch (character) {
      /* functions keys */
    case kHKF1Unicode:
      keyCode = kHKVirtualF1Key;
      break;
    case kHKF2Unicode:
      keyCode = kHKVirtualF2Key;
      break;
    case kHKF3Unicode:
      keyCode = kHKVirtualF3Key;
      break;
    case kHKF4Unicode:
      keyCode = kHKVirtualF4Key;
      break;
      /* functions keys */
    case kHKF5Unicode:
      keyCode = kHKVirtualF5Key;
      break;
    case kHKF6Unicode:
      keyCode = kHKVirtualF6Key;
      break;
    case kHKF7Unicode:
      keyCode = kHKVirtualF7Key;
      break;
    case kHKF8Unicode:
      keyCode = kHKVirtualF8Key;
      break;
      /* functions keys */
    case kHKF9Unicode:
      keyCode = kHKVirtualF9Key;
      break;
    case kHKF10Unicode:
      keyCode = kHKVirtualF10Key;
      break;
    case kHKF11Unicode:
      keyCode = kHKVirtualF11Key;
      break;
    case kHKF12Unicode:
      keyCode = kHKVirtualF12Key;
      break;
      /* functions keys */
    case kHKF13Unicode:
      keyCode = kHKVirtualF13Key;
      break;
    case kHKF14Unicode:
      keyCode = kHKVirtualF14Key;
      break;
    case kHKF15Unicode:
      keyCode = kHKVirtualF15Key;
      break;
    case kHKF16Unicode:
      keyCode = kHKVirtualF16Key;
      break;
      /* aluminium keyboard */
    case kHKF17Unicode:
      keyCode = kHKVirtualF17Key;
      break;
    case kHKF18Unicode:
      keyCode = kHKVirtualF18Key;
      break;
    case kHKF19Unicode:
      keyCode = kHKVirtualF19Key;
      break;
      /* editing utility keys */
    case kHKHelpUnicode:
      keyCode = kHKVirtualHelpKey;
      break;
    case kHKDeleteUnicode: 
      keyCode = kHKVirtualDeleteKey;
      break;
    case kHKTabUnicode:
      keyCode = kHKVirtualTabKey;
      break;
    case kHKEnterUnicode:
      keyCode = kHKVirtualEnterKey;
      break;
    case kHKReturnUnicode:
      keyCode = kHKVirtualReturnKey;
      break;
    case kHKEscapeUnicode:
      keyCode = kHKVirtualEscapeKey;
      break;
    case kHKForwardDeleteUnicode:
      keyCode = kHKVirtualForwardDeleteKey;
      break;
      /* navigation keys */
    case kHKHomeUnicode: 
      keyCode = kHKVirtualHomeKey;
      break;
    case kHKEndUnicode:
      keyCode = kHKVirtualEndKey;
      break;
    case kHKPageUpUnicode:
      keyCode = kHKVirtualPageUpKey;
      break;
    case kHKPageDownUnicode:
      keyCode = kHKVirtualPageDownKey;
      break;
    case kHKLeftArrowUnicode:
      keyCode = kHKVirtualLeftArrowKey;
      break;
    case kHKRightArrowUnicode:
      keyCode = kHKVirtualRightArrowKey;
      break;
    case kHKUpArrowUnicode:
      keyCode = kHKVirtualUpArrowKey;
      break;
    case kHKDownArrowUnicode:
      keyCode = kHKVirtualDownArrowKey;
      break;
    case kHKClearLineUnicode:
      keyCode = kHKVirtualClearLineKey;
      break;
    case kHKNoBreakSpaceUnicode:
      keyCode = kHKVirtualSpaceKey;
      break;
  }
  return keyCode;
}

UniChar HKMapGetSpecialCharacterForKeycode(HKKeycode keycode) {
  switch (keycode) {
    case kHKInvalidVirtualKeyCode: return kHKNilUnichar;
      /* functions keys */
    case kHKVirtualF1Key: return kHKF1Unicode;
    case kHKVirtualF2Key: return kHKF2Unicode;
    case kHKVirtualF3Key: return kHKF3Unicode;
    case kHKVirtualF4Key: return kHKF4Unicode;
      /* functions keys */
    case kHKVirtualF5Key: return kHKF5Unicode;
    case kHKVirtualF6Key: return kHKF6Unicode;
    case kHKVirtualF7Key: return kHKF7Unicode;
    case kHKVirtualF8Key: return kHKF8Unicode;
      /* functions keys */
    case kHKVirtualF9Key:  return kHKF9Unicode;
    case kHKVirtualF10Key: return kHKF10Unicode;
    case kHKVirtualF11Key: return kHKF11Unicode;
    case kHKVirtualF12Key: return kHKF12Unicode;
      /* functions keys */
    case kHKVirtualF13Key: return kHKF13Unicode;
    case kHKVirtualF14Key: return kHKF14Unicode;
    case kHKVirtualF15Key: return kHKF15Unicode;
    case kHKVirtualF16Key: return kHKF16Unicode;
      /* aluminium keyboard */
    case kHKVirtualF17Key: return kHKF17Unicode;
    case kHKVirtualF18Key: return kHKF18Unicode;
    case kHKVirtualF19Key: return kHKF19Unicode;
      /* editing utility keys */
    case kHKVirtualHomeKey:          return kHKHomeUnicode;
    case kHKVirtualEndKey:           return kHKEndUnicode;
    case kHKVirtualPageUpKey:        return kHKPageUpUnicode;
    case kHKVirtualPageDownKey:      return kHKPageDownUnicode;
    case kHKVirtualHelpKey:          return kHKHelpUnicode;
    case kHKVirtualForwardDeleteKey: return kHKForwardDeleteUnicode;
      /* navigation keys */
    case kHKVirtualLeftArrowKey:  return kHKLeftArrowUnicode;
    case kHKVirtualRightArrowKey: return kHKRightArrowUnicode;
    case kHKVirtualUpArrowKey:    return kHKUpArrowUnicode;
    case kHKVirtualDownArrowKey:  return kHKDownArrowUnicode;
      /* special num-pad key */
    case kHKVirtualClearLineKey:  return kHKClearLineUnicode;
      /* key with special representation */
    case kHKVirtualEnterKey:  return kHKEnterUnicode;
    case kHKVirtualTabKey:    return kHKTabUnicode;
    case kHKVirtualReturnKey: return kHKReturnUnicode;
    case kHKVirtualDeleteKey: return kHKDeleteUnicode;
    case kHKVirtualEscapeKey: return kHKEscapeUnicode;
  }
  return kHKNilUnichar;
}

#pragma mark String representation
NSString* HKMapGetModifierString(HKModifier mask) {
  UniChar modifier[5];
  UniChar *symbol = modifier;
  if (kCGEventFlagMaskAlphaShift & mask) {
    *(symbol++) = 0x21ea; // Caps lock
  }
  if (kCGEventFlagMaskControl & mask) {
    *(symbol++) = 0x2303; // kControlUnicode;
  }
  if (kCGEventFlagMaskAlternate & mask) {
    *(symbol++) = 0x2325; // kOptionUnicode
  }
  if (kCGEventFlagMaskShift & mask) {
    *(symbol++) = 0x21E7; // kShiftUnicode
  }
  if (kCGEventFlagMaskCommand & mask) {
    *(symbol++) = 0x2318; // kCommandUnicode
  }
  NSString *result = symbol - modifier > 0 ? [NSString stringWithCharacters:modifier length:symbol - modifier] : nil;
  return result;
}

NSString* HKMapGetSpeakableModifierString(HKModifier mask) {
  NSMutableString *str = mask ? [[NSMutableString alloc] init] : nil;
  if (kCGEventFlagMaskAlphaShift & mask) {
    [str appendString:NSLocalizedStringFromTableInBundle(@"Caps Lock", @"Keyboard", kHotKeyToolKitBundle, @"Speakable Caps Lock Modifier")];
  }
  if (kCGEventFlagMaskControl & mask) {
    if ([str length])
      [str appendString:@" + "];
    [str appendString:NSLocalizedStringFromTableInBundle(@"Control", @"Keyboard", kHotKeyToolKitBundle, @"Speakable Control Modifier")];
  }
  if (kCGEventFlagMaskAlternate & mask) {
    if ([str length])
      [str appendString:@" + "];
    [str appendString:NSLocalizedStringFromTableInBundle(@"Option", @"Keyboard", kHotKeyToolKitBundle, @"Speakable Option Modifier")];
  }
  if (kCGEventFlagMaskShift & mask) {
    if ([str length])
      [str appendString:@" + "];
    [str appendString:NSLocalizedStringFromTableInBundle(@"Shift", @"Keyboard", kHotKeyToolKitBundle, @"Speakable Shift Modifier")];
  }
  if (kCGEventFlagMaskCommand & mask) {
    if ([str length])
      [str appendString:@" + "];
    [str appendString:NSLocalizedStringFromTableInBundle(@"Command", @"Keyboard", kHotKeyToolKitBundle, @"Speakable Command Modifier")];
  }
  return [str autorelease];
}

NSString *HKMapGetStringForUnichar(UniChar character) {
  NSString *str = nil;
  if (kHKNilUnichar == character)
    return str;
  switch (character) {
    case kHKF1Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F1", @"Keyboard", kHotKeyToolKitBundle, @"F1 Key display String");
      break;
    case kHKF2Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F2", @"Keyboard", kHotKeyToolKitBundle, @"F2 Key display String");
      break;
    case kHKF3Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F3", @"Keyboard", kHotKeyToolKitBundle, @"F3 Key display String");
      break;
    case kHKF4Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F4", @"Keyboard", kHotKeyToolKitBundle, @"F4 Key display String");
      break;
      /* functions Unicodes */
    case kHKF5Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F5", @"Keyboard", kHotKeyToolKitBundle, @"F5 Key display String");
      break;
    case kHKF6Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F6", @"Keyboard", kHotKeyToolKitBundle, @"F6 Key display String");
      break;
    case kHKF7Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F7", @"Keyboard", kHotKeyToolKitBundle, @"F7 Key display String");
      break;
    case kHKF8Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F8", @"Keyboard", kHotKeyToolKitBundle, @"F8 Key display String");
      break;
      /* functions Unicodes */
    case kHKF9Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F9", @"Keyboard", kHotKeyToolKitBundle, @"F9 Key display String");
      break;
    case kHKF10Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F10", @"Keyboard", kHotKeyToolKitBundle, @"F10 Key display String");
      break;
    case kHKF11Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F11", @"Keyboard", kHotKeyToolKitBundle, @"F11 Key display String");
      break;
    case kHKF12Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F12", @"Keyboard", kHotKeyToolKitBundle, @"F12 Key display String");
      break;
      /* functions Unicodes */
    case kHKF13Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F13", @"Keyboard", kHotKeyToolKitBundle, @"F13 Key display String");
      break;
    case kHKF14Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F14", @"Keyboard", kHotKeyToolKitBundle, @"F14 Key display String");
      break;
    case kHKF15Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F15", @"Keyboard", kHotKeyToolKitBundle, @"F15 Key display String");
      break;
    case kHKF16Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F16", @"Keyboard", kHotKeyToolKitBundle, @"F16 Key display String");
      break;
      /* aluminium keyboard */
    case kHKF17Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F17", @"Keyboard", kHotKeyToolKitBundle, @"F17 Key display String");
      break;
    case kHKF18Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F18", @"Keyboard", kHotKeyToolKitBundle, @"F18 Key display String");
      break;
    case kHKF19Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F19", @"Keyboard", kHotKeyToolKitBundle, @"F19 Key display String");
      break;
      /* editing utility Unicodes */
    case kHKHelpUnicode:
      str = NSLocalizedStringFromTableInBundle(@"help", @"Keyboard", kHotKeyToolKitBundle, @"Help Key display String");
      break;
    case ' ':
      str = NSLocalizedStringFromTableInBundle(@"spc", @"Keyboard", kHotKeyToolKitBundle, @"Space Key display String");
      break;
      /* Special Chars */
    case kHKDeleteUnicode:
      character = 0x232b;
      break;
    case kHKTabUnicode:
      character = 0x21e5;
      break;
    case kHKEnterUnicode:
      character = 0x2305;
      break;
    case kHKReturnUnicode:
      character = 0x21a9;
      break;  
    case kHKEscapeUnicode:
      character = 0x238b;
      break;  
    case kHKForwardDeleteUnicode:
      character = 0x2326;
      break;
      /* navigation keys */
    case kHKHomeUnicode:
      character = 0x2196;
      break;
    case kHKEndUnicode:
      character = 0x2198;
      break;  
    case kHKPageUpUnicode:
      character = 0x21de;
      break;  
    case kHKPageDownUnicode:
      character = 0x21df;
      break;
    case kHKLeftArrowUnicode:
      character = 0x21e0;
      break;
    case kHKUpArrowUnicode:
      character = 0x21e1;
      break;
    case kHKRightArrowUnicode:
      character = 0x21e2;
      break;
    case kHKDownArrowUnicode:
      character = 0x21e3;
      break;
      /* others Unicodes */
    case kHKClearLineUnicode:
      character = 0x2327;
      break;
  }
  if (!str)
    // Si caractère Ascii, on met en majuscule (comme sur les touches du clavier en fait).
    str = (character <= 127) ? [SpecialChar(character) uppercaseString] : SpecialChar(character);
  return str;
}
