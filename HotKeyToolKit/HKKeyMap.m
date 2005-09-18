//
//  KeyCodeFunctions.m
//  Short-Cut
//
//  Created by Fox on Tue Dec 09 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "HKKeyMap.h"
#import "KeyMap.h"

#define SpecialChar(n)        				[NSString stringWithFormat:@"%C", n]

#define kHotKeyToolKitBundleIdentifier		@"org.shadowlab.HotKeyToolKit"
#define kHotKeyToolKitBundle				[NSBundle bundleWithIdentifier:kHotKeyToolKitBundleIdentifier]

const unsigned short kHKNilVirtualKeyCode = 0xffff;
const unichar kHKNilUnichar = 0xffff;

static HKKeyMapRef SharedKeyMap() {
  static HKKeyMapRef sharedKeyMap = nil;
  if (nil == sharedKeyMap) {
    sharedKeyMap = HKKeyMapCreate();
    if (nil == sharedKeyMap) {
      NSLog(@"Unable to init Translate Table");
    }
#if defined(DEBUG)
    else {
      NSLog(@"Translate Table initialized");
    }
#endif
  }
  return sharedKeyMap;
}

#pragma mark -
#pragma mark Statics Functions Declaration
static unsigned short HKSpecialKeyCodeForUnichar(unichar charCode);
static NSString *HKModifierStringForMask(unsigned int mask);
static NSString *HKStringForUnichar(unichar unicode);

#pragma mark -
#pragma mark Publics Functions Definition

unsigned int HKKeycodeAndModifierForUnichar(unichar character) {
  unsigned int keycodes = kHKNilVirtualKeyCode;
  if (character != kHKNilUnichar) {
    keycodes = HKSpecialKeyCodeForUnichar(character);
    if (keycodes == kHKNilVirtualKeyCode) {
      keycodes = HKKeyMapUnicharToKeycodes(SharedKeyMap(), character);
    }
  }
  return keycodes;
}

unsigned short HKKeycodeForUnichar(unichar character) {
  unsigned short keycode = kHKNilVirtualKeyCode;
  unsigned int codes = HKKeycodeAndModifierForUnichar(character);
  if (codes != kHKNilVirtualKeyCode) {
    keycode = codes & 0xffff;
  }
  return keycode;
}

unichar HKUnicharForKeycode(unsigned short keycode) {
  unichar unicode;
  if (keycode == kHKNilVirtualKeyCode) {
    unicode = kHKNilUnichar; 
  }
  else {
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
        unicode = HKKeyMapKeycodeToUniChar(SharedKeyMap(), keycode);
    }
  }
  return unicode;
}

NSString* HKCurrentKeyMapName() {
  return (NSString *)HKKeyMapGetName(SharedKeyMap());
}

NSString* HKStringRepresentationForCharacterAndModifier(unichar character, unsigned int modifier) {
  if (character != kHKNilUnichar) {
    return [HKModifierStringForMask(modifier) stringByAppendingString:HKStringForUnichar(character)];
  }
  return nil;
}

#pragma mark -
#pragma mark Statics Functions Definition
unsigned short HKSpecialKeyCodeForUnichar(unichar character) {
  unsigned short keyCode = kHKNilVirtualKeyCode;
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

NSString* HKModifierStringForMask(unsigned int mask) {
  unichar *modifier = NSZoneMalloc(nil, 4*sizeof(unichar));
  unichar *symbol = modifier;
  if (NSControlKeyMask & mask) {
    *(symbol++) = kControlUnicode; // Ctrl
  }
  if (NSAlternateKeyMask & mask) {
    *(symbol++) = kOptionUnicode; // Opt
  }
  if (NSShiftKeyMask & mask) {
    *(symbol++) = kShiftUnicode; // Shift
  }
  if (NSCommandKeyMask & mask) {
    *(symbol++) = kCommandUnicode; //Cmd
  }
  NSString *result = [NSString stringWithCharacters:modifier length:symbol - modifier];
  NSZoneFree(nil, modifier);
  return result;
}

NSString* HKStringForUnichar(unichar character) {
  id str = nil;
  if (kHKNilUnichar == character)
    return str;
  switch (character) {
    case kF1Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F1", @"ShortCut", kHotKeyToolKitBundle, @"F1 Key display String");
      break;
    case kF2Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F2", @"ShortCut", kHotKeyToolKitBundle, @"F2 Key display String");
      break;
    case kF3Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F3", @"ShortCut", kHotKeyToolKitBundle, @"F3 Key display String");
      break;
    case kF4Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F4", @"ShortCut", kHotKeyToolKitBundle, @"F4 Key display String");
      break;
      /* functions Unicodes */
    case kF5Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F5", @"ShortCut", kHotKeyToolKitBundle, @"F5 Key display String");
      break;
    case kF6Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F6", @"ShortCut", kHotKeyToolKitBundle, @"F6 Key display String");
      break;
    case kF7Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F7", @"ShortCut", kHotKeyToolKitBundle, @"F7 Key display String");
      break;
    case kF8Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F8", @"ShortCut", kHotKeyToolKitBundle, @"F8 Key display String");
      break;
      /* functions Unicodes */
    case kF9Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F9", @"ShortCut", kHotKeyToolKitBundle, @"F9 Key display String");
      break;
    case kF10Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F10", @"ShortCut", kHotKeyToolKitBundle, @"F10 Key display String");
      break;
    case kF11Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F11", @"ShortCut", kHotKeyToolKitBundle, @"F11 Key display String");
      break;
    case kF12Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F12", @"ShortCut", kHotKeyToolKitBundle, @"F12 Key display String");
      break;
      /* functions Unicodes */
    case kF13Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F13", @"ShortCut", kHotKeyToolKitBundle, @"F13 Key display String");
      break;
    case kF14Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F14", @"ShortCut", kHotKeyToolKitBundle, @"F14 Key display String");
      break;
    case kF15Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F15", @"ShortCut", kHotKeyToolKitBundle, @"F15 Key display String");
      break;
    case kF16Unicode:
      str = NSLocalizedStringFromTableInBundle(@"F16", @"ShortCut", kHotKeyToolKitBundle, @"F16 Key display String");
      break;
      /* editing utility Unicodes */
    case kHelpUnicode:
      str = NSLocalizedStringFromTableInBundle(@"help", @"ShortCut", kHotKeyToolKitBundle, @"Help Key display String");
      break;
    case kSpaceUnicode:
      str = NSLocalizedStringFromTableInBundle(@"spc", @"ShortCut", kHotKeyToolKitBundle, @"Space Key display String");
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
