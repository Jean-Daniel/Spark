/*
 *  HKKeyMap.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "HKKeyMap.h"
#import "KeyMap.h"

#define SpecialChar(n)        				[NSString stringWithFormat:@"%C", n]

#define kHotKeyToolKitBundleIdentifier		@"org.shadowlab.HotKeyToolKit"
#define kHotKeyToolKitBundle				[NSBundle bundleWithIdentifier:kHotKeyToolKitBundleIdentifier]

static
BOOL HKUseReverseKeyMap = YES;

const UniChar kHKNilUnichar = 0xffff;

static HKKeyMapRef SharedKeyMap() {
  static HKKeyMapRef sharedKeyMap = nil;
  if (!sharedKeyMap) {
    sharedKeyMap = HKKeyMapCreateWithCurrentLayout(HKUseReverseKeyMap);
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
HKKeycode HKMapGetSpecialKeyCodeForUnichar(UniChar charCode);
static
NSString *HKMapGetModifierString(HKModifier mask);
static
NSString *HKMapGetSpeakableModifierString(HKModifier mask);
static
NSString *HKMapGetStringForUnichar(UniChar unicode);

#pragma mark -
#pragma mark Publics Functions Definition
UniChar HKMapGetUnicharForKeycode(HKKeycode keycode) {
  UniChar unicode = kHKNilUnichar;
  if (keycode == kHKInvalidVirtualKeyCode) {
    return unicode;
  } else {
    switch (keycode) {
      /* functions keys */
      case kVirtualF1Key:
        unicode = kF1Unicode;
        break;
      case kVirtualF2Key:
        unicode = kF2Unicode;
        break;
      case kVirtualF3Key:
        unicode = kF3Unicode;
        break;
      case kVirtualF4Key:
        unicode = kF4Unicode;
        break;
        /* functions keys */
      case kVirtualF5Key:
        unicode = kF5Unicode;
        break;
      case kVirtualF6Key:
        unicode = kF6Unicode;
        break;
      case kVirtualF7Key:
        unicode = kF7Unicode;
        break;
      case kVirtualF8Key:
        unicode = kF8Unicode;
        break;
        /* functions keys */
      case kVirtualF9Key:
        unicode = kF9Unicode;
        break;
      case kVirtualF10Key:
        unicode = kF10Unicode;
        break;
      case kVirtualF11Key:
        unicode = kF11Unicode;
        break;
      case kVirtualF12Key:
        unicode = kF12Unicode;
        break;
        /* functions keys */
      case kVirtualF13Key:
        unicode = kF13Unicode;
        break;
      case kVirtualF14Key:
        unicode = kF14Unicode;
        break;
      case kVirtualF15Key:
        unicode = kF15Unicode;
        break;
      case kVirtualF16Key:
        unicode = kF16Unicode;
        break;
        /* editing utility keys */
      case kVirtualHelpKey:
        unicode = kHelpUnicode;
        break;
      case kVirtualDeleteKey:
        unicode = kDeleteUnicode;
        break;
      case kVirtualTabKey:
        unicode = kTabUnicode;
        break;
      case kVirtualEnterKey:
        unicode = kEnterUnicode;
        break;
      case kVirtualReturnKey:
        unicode = kReturnUnicode;
        break;
      case kVirtualEscapeKey:
        unicode = kEscapeUnicode;
        break;
      case kVirtualForwardDeleteKey:
        unicode = kForwardDeleteUnicode;
        break;
        /* navigation keys */
      case kVirtualHomeKey: 
        unicode = kHomeUnicode;
        break;
      case kVirtualEndKey:
        unicode = kEndUnicode;
        break;
      case kVirtualPageUpKey:
        unicode = kPageUpUnicode;
        break;
      case kVirtualPageDownKey:
        unicode = kPageDownUnicode;
        break;
      case kVirtualLeftArrowKey:
        unicode = kLeftArrowUnicode;
        break;
      case kVirtualRightArrowKey:
        unicode = kRightArrowUnicode;
        break;
      case kVirtualUpArrowKey:
        unicode = kUpArrowUnicode;
        break;
      case kVirtualDownArrowKey:
        unicode = kDownArrowUnicode;
        break;
      case kVirtualClearLineKey:
        unicode = kClearLineUnicode;
        break;
      case kVirtualSpaceKey:
        unicode = kSpaceUnicode;
        break;
      default:
        unicode = HKKeyMapGetUnicharForKeycode(SharedKeyMap(), keycode);
    }
  }
  return unicode;
}

NSString* HKMapGetCurrentMapName() {
  return (NSString *)HKKeyMapGetName(SharedKeyMap());
}

NSString* HKMapGetStringRepresentationForCharacterAndModifier(UniChar character, HKModifier modifier) {
  if (character && character != kHKNilUnichar) {
    NSString *mod = HKMapGetModifierString(modifier);
    if ([mod length] > 0) {
      return [mod stringByAppendingString:HKMapGetStringForUnichar(character)];
    } else {
      return HKMapGetStringForUnichar(character);
    }
  }
  return nil;
}

NSString* HKMapGetSpeakableStringRepresentationForCharacterAndModifier(UniChar character, HKModifier modifier) {
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
HKKeycode HKMapGetKeycodeAndModifierForUnichar(UniChar character, HKModifier *modifier, NSUInteger *count) {
  if (kHKNilUnichar == character)
    return kHKInvalidVirtualKeyCode;
  HKKeycode key[1];
  HKModifier mod[1];
  NSUInteger cnt = HKMapGetKeycodesAndModifiersForUnichar(character, key, mod, 1);
  if (!cnt || kHKInvalidVirtualKeyCode == key[0])
    return kHKInvalidVirtualKeyCode;
  if (count) *count = cnt;
  if (modifier) *modifier = mod[0];
  
  return key[0];
}

NSUInteger HKMapGetKeycodesAndModifiersForUnichar(UniChar character, HKKeycode *keys, HKModifier *modifiers, NSUInteger maxcount) {
  NSUInteger count = 0;
  if (character != kHKNilUnichar) {
    HKKeycode keycode = HKMapGetSpecialKeyCodeForUnichar(character);
    if (keycode == kHKInvalidVirtualKeyCode) {
      count = HKKeyMapGetKeycodesForUnichar(SharedKeyMap(), character, keys, modifiers, maxcount);
    } else {
      count = 1;
      if (maxcount > 0) {
        keys[0] = keycode & 0xffff;
        modifiers[0] = 0;
      }
    }
  }
  return count;
}

#pragma mark -
#pragma mark Statics Functions Definition
HKKeycode HKMapGetSpecialKeyCodeForUnichar(UniChar character) {
  HKKeycode keyCode = kHKInvalidVirtualKeyCode;
  switch (character) {
    /* functions keys */
    case kF1Unicode:
      keyCode = kVirtualF1Key;
      break;
    case kF2Unicode:
      keyCode = kVirtualF2Key;
      break;
    case kF3Unicode:
      keyCode = kVirtualF3Key;
      break;
    case kF4Unicode:
      keyCode = kVirtualF4Key;
      break;
      /* functions keys */
    case kF5Unicode:
      keyCode = kVirtualF5Key;
      break;
    case kF6Unicode:
      keyCode = kVirtualF6Key;
      break;
    case kF7Unicode:
      keyCode = kVirtualF7Key;
      break;
    case kF8Unicode:
      keyCode = kVirtualF8Key;
      break;
      /* functions keys */
    case kF9Unicode:
      keyCode = kVirtualF9Key;
      break;
    case kF10Unicode:
      keyCode = kVirtualF10Key;
      break;
    case kF11Unicode:
      keyCode = kVirtualF11Key;
      break;
    case kF12Unicode:
      keyCode = kVirtualF12Key;
      break;
      /* functions keys */
    case kF13Unicode:
      keyCode = kVirtualF13Key;
      break;
    case kF14Unicode:
      keyCode = kVirtualF14Key;
      break;
    case kF15Unicode:
      keyCode = kVirtualF15Key;
      break;
    case kF16Unicode:
      keyCode = kVirtualF16Key;
      break;
      /* editing utility keys */
    case kHelpUnicode:
      keyCode = kVirtualHelpKey;
      break;
    case kDeleteUnicode: 
      keyCode = kVirtualDeleteKey;
      break;
    case kTabUnicode:
      keyCode = kVirtualTabKey;
      break;
    case kEnterUnicode:
      keyCode = kVirtualEnterKey;
      break;
    case kReturnUnicode:
      keyCode = kVirtualReturnKey;
      break;
    case kEscapeUnicode:
      keyCode = kVirtualEscapeKey;
      break;
    case kForwardDeleteUnicode:
      keyCode = kVirtualForwardDeleteKey;
      break;
      /* navigation keys */
    case kHomeUnicode: 
      keyCode = kVirtualHomeKey;
      break;
    case kEndUnicode:
      keyCode = kVirtualEndKey;
      break;
    case kPageUpUnicode:
      keyCode = kVirtualPageUpKey;
      break;
    case kPageDownUnicode:
      keyCode = kVirtualPageDownKey;
      break;
    case kLeftArrowUnicode:
      keyCode = kVirtualLeftArrowKey;
      break;
    case kRightArrowUnicode:
      keyCode = kVirtualRightArrowKey;
      break;
    case kUpArrowUnicode:
      keyCode = kVirtualUpArrowKey;
      break;
    case kDownArrowUnicode:
      keyCode = kVirtualDownArrowKey;
      break;
    case kClearLineUnicode:
      keyCode = kVirtualClearLineKey;
      break;
    case kSpaceUnicode:
      keyCode = kVirtualSpaceKey;
      break;
  }
  return keyCode;
}

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

NSString* HKMapGetStringForUnichar(UniChar character) {
  id str = nil;
  if (kHKNilUnichar == character)
    return str;
  switch (character) {
    case kF1Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F1", @"Keyboard", kHotKeyToolKitBundle, @"F1 Key display String");
      break;
    case kF2Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F2", @"Keyboard", kHotKeyToolKitBundle, @"F2 Key display String");
      break;
    case kF3Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F3", @"Keyboard", kHotKeyToolKitBundle, @"F3 Key display String");
      break;
    case kF4Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F4", @"Keyboard", kHotKeyToolKitBundle, @"F4 Key display String");
      break;
      /* functions Unicodes */
    case kF5Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F5", @"Keyboard", kHotKeyToolKitBundle, @"F5 Key display String");
      break;
    case kF6Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F6", @"Keyboard", kHotKeyToolKitBundle, @"F6 Key display String");
      break;
    case kF7Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F7", @"Keyboard", kHotKeyToolKitBundle, @"F7 Key display String");
      break;
    case kF8Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F8", @"Keyboard", kHotKeyToolKitBundle, @"F8 Key display String");
      break;
      /* functions Unicodes */
    case kF9Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F9", @"Keyboard", kHotKeyToolKitBundle, @"F9 Key display String");
      break;
    case kF10Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F10", @"Keyboard", kHotKeyToolKitBundle, @"F10 Key display String");
      break;
    case kF11Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F11", @"Keyboard", kHotKeyToolKitBundle, @"F11 Key display String");
      break;
    case kF12Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F12", @"Keyboard", kHotKeyToolKitBundle, @"F12 Key display String");
      break;
      /* functions Unicodes */
    case kF13Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F13", @"Keyboard", kHotKeyToolKitBundle, @"F13 Key display String");
      break;
    case kF14Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F14", @"Keyboard", kHotKeyToolKitBundle, @"F14 Key display String");
      break;
    case kF15Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F15", @"Keyboard", kHotKeyToolKitBundle, @"F15 Key display String");
      break;
    case kF16Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F16", @"Keyboard", kHotKeyToolKitBundle, @"F16 Key display String");
      break;
      /* editing utility Unicodes */
    case kHelpUnicode:
      str = NSLocalizedStringFromTableInBundle(@"help", @"Keyboard", kHotKeyToolKitBundle, @"Help Key display String");
      break;
    case kSpaceUnicode:
      str = NSLocalizedStringFromTableInBundle(@"spc", @"Keyboard", kHotKeyToolKitBundle, @"Space Key display String");
      break;
      /* Special Chars */
    case kDeleteUnicode:
      character = 0x232b;
      break;
    case kTabUnicode:
      character = 0x21e5;
      break;
    case kEnterUnicode:
      character = 0x2305;
      break;
    case kReturnUnicode:
      character = 0x21a9;
      break;  
    case kEscapeUnicode:
      character = 0x238b;
      break;  
    case kForwardDeleteUnicode:
      character = 0x2326;
      break;
      /* navigation keys */
    case kHomeUnicode:
      character = 0x2196;
      break;
    case kEndUnicode:
      character = 0x2198;
      break;  
    case kPageUpUnicode:
      character = 0x21de;
      break;  
    case kPageDownUnicode:
      character = 0x21df;
      break;
    case kLeftArrowUnicode:
      character = 0x21e0;
      break;
    case kUpArrowUnicode:
      character = 0x21e1;
      break;
    case kRightArrowUnicode:
      character = 0x21e2;
      break;
    case kDownArrowUnicode:
      character = 0x21e3;
      break;
      /* others Unicodes */
    case kClearLineUnicode:
      character = 0x2327;
      break;
  }
  if (!str)
    // Si caractère Ascii, on met en majuscule (comme sur les touches du clavier en fait).
    str = (character <= 127) ? [SpecialChar(character) uppercaseString] : SpecialChar(character);
  return str;
}
