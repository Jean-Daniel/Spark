/*
 *  SparkHotKey.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkAction.h>

#import WBHEADER(WBForwarding.h)
#import WBHEADER(WBObjCRuntime.h)
#import WBHEADER(NSImage+WonderBox.h)

#import <HotKeyToolKit/HotKeyToolKit.h>

static
NSString * const kHotKeyRawCodeKey = @"STRawKey";

static
SparkFilterMode sSparkKeyStrokeFilterMode = kSparkEnableSingleFunctionKey;

SparkFilterMode SparkGetFilterMode(void) { return sSparkKeyStrokeFilterMode; }
void SparkSetFilterMode(SparkFilterMode mode) { sSparkKeyStrokeFilterMode = mode; }

/*
 Fonction qui permet de définir la validité d'un raccouci. Depuis 10.3, les raccourcis sans "modifier" sont acceptés.
 Jugés trop génant, seul les touches Fx peuvent être utilisées sans "modifier"
*/
static
const NSInteger kCommonModifierMask = kCGEventFlagMaskCommand | kCGEventFlagMaskControl | kCGEventFlagMaskShift | kCGEventFlagMaskAlternate;

BOOL SparkHotKeyFilter(HKKeycode code, HKModifier modifier) {
  if ((modifier & kCommonModifierMask) != 0) {
    return YES;
  }
  
  switch (sSparkKeyStrokeFilterMode) {
    case kSparkDisableAllSingleKey:
      return NO;
    case kSparkEnableAllSingleKey:
      return YES;
    case kSparkEnableAllSingleButNavigation:
      switch (code) {
        case kHKVirtualTabKey:
        case kHKVirtualEnterKey:
        case kHKVirtualReturnKey:
        case kHKVirtualEscapeKey:
        case kHKVirtualLeftArrowKey:
        case kHKVirtualRightArrowKey:
        case kHKVirtualUpArrowKey:
        case kHKVirtualDownArrowKey:
          return NO;
      }
      return YES;
    case kSparkEnableSingleFunctionKey:
      switch (code) {
        case kHKVirtualF1Key:
        case kHKVirtualF2Key:
        case kHKVirtualF3Key:
        case kHKVirtualF4Key:
        case kHKVirtualF5Key:
        case kHKVirtualF6Key:
        case kHKVirtualF7Key:
        case kHKVirtualF8Key:
        case kHKVirtualF9Key:
        case kHKVirtualF10Key:
        case kHKVirtualF11Key:
        case kHKVirtualF12Key:
        case kHKVirtualF13Key:
        case kHKVirtualF14Key:
        case kHKVirtualF15Key:
        case kHKVirtualF16Key:
				case kHKVirtualF17Key:
				case kHKVirtualF18Key:
				case kHKVirtualF19Key:
        case kHKVirtualHelpKey:
        case kHKVirtualClearLineKey:
          return YES;
      }
      break;
  }
  return NO;
}

#pragma mark -
@implementation SparkHotKey

static CFMutableDictionaryRef sHKParentMap = NULL;
+ (void)initialize {
  if ([SparkHotKey class] == self) {
    /* Special memory management. HKHotKey (key) and SparkHotKey (value) have exactly the same life cycle.
     We must not retain the SparkHotKey (else it would create cycle, as we remove it in dealloc) */
    sHKParentMap = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
  }
}

#pragma mark -
#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeInt64:[sp_hotkey rawkey] forKey:kHotKeyRawCodeKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    UInt64 hotkey = [aDecoder decodeInt64ForKey:kHotKeyRawCodeKey];
    [sp_hotkey setRawkey:hotkey];
  }
  return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  SparkHotKey* copy = [super copyWithZone:zone];
  WBCLogWarning("Warning: hotkey should not be copied");
  copy->sp_hotkey = [sp_hotkey copyWithZone:zone];
  CFDictionarySetValue(sHKParentMap, copy->sp_hotkey, copy);
  return copy;
}

#pragma mark SparkSerialization
- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  UInt64 hotkey = [sp_hotkey rawkey];
  [plist setObject:WBUInt64(hotkey) forKey:kHotKeyRawCodeKey];
  return YES;
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    NSNumber *value = [plist objectForKey:kHotKeyRawCodeKey];
    if (!value)
      value = [plist objectForKey:@"KeyCode"];

    [sp_hotkey setRawkey:value ? [value unsignedLongLongValue] : 0];
  }
  return self;
}

#pragma mark -
#pragma mark Init & Dealloc Methods
- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super initWithName:name icon:icon]) {
    sp_hotkey = [[HKHotKey alloc] init];
    [sp_hotkey setTarget:self];
    [sp_hotkey setAction:@selector(trigger:)];
    CFDictionarySetValue(sHKParentMap, sp_hotkey, self);
  }
  return self;
}

- (void)dealloc {
  CFDictionaryRemoveValue(sHKParentMap, sp_hotkey);
  [sp_hotkey release];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {uid:%u hotkey:'%@'}",
    [self class], self,
    [self uid], [sp_hotkey shortcut]];
}

#pragma mark -
#pragma mark Public Methods
- (void)bypass {
  /* 5 ms latency */
  [sp_hotkey sendKeystroke:kHKEventDefaultLatency];
}
- (BOOL)isRegistred {
  return [sp_hotkey isRegistred];
}
- (BOOL)setRegistred:(BOOL)flag {
  return [sp_hotkey setRegistred:flag];
}
- (NSString *)triggerDescription {
  return [sp_hotkey shortcut];
}

- (BOOL)sendKeystroke:(useconds_t)latency {
  return [sp_hotkey sendKeystroke:latency];
}
- (BOOL)sendKeystrokeToApplication:(OSType)signature bundle:(NSString *)bundleId latency:(useconds_t)latency {
  return [sp_hotkey sendKeystrokeToApplication:signature bundle:bundleId latency:latency];
}

- (BOOL)isEqualToTrigger:(SparkTrigger *)aTrigger {
  return [aTrigger isKindOfClass:[SparkHotKey class]] && [self rawkey] == [(id)aTrigger rawkey];
}

#pragma mark -
- (void)trigger:(id)sender {
  [self sendEventWithEntry:sp_entry time:[sp_hotkey eventTime] isARepeat:[sp_hotkey isARepeat]];
}

- (void)prepareHotKey {
  sp_entry = [self resolveEntry];
  if (sp_entry) {
    SparkAction *action = [sp_entry action];
    NSAssert(action, @"Invalid entry. Does not contains action!");
    if ([action performOnKeyUp]) {
      [sp_hotkey setInvokeOnKeyUp:YES];
    } else {
      [sp_hotkey setInvokeOnKeyUp:NO];
      [sp_hotkey setRepeatInterval:[action repeatInterval]];
      [sp_hotkey setInitialRepeatInterval:[action initialRepeatInterval]];
    }
  }
}

//- (void)didInvoke {
//  [sp_hotkey setInvokeOnKeyUp:NO];
//}

#pragma mark -
#pragma mark Accessors
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    [self setIcon:[NSImage imageNamed:@"hotkey" inBundle:kSparkKitBundle]];
    icon = [super icon];
  }
  return icon;
}

//- (id)initFromExternalRepresentation:(id)rep {
//  return nil;
//}

//- (id)externalRepresentation {
//  NSMutableDictionary *plist = [super externalRepresentation];
//  if (plist) {
//    NSMutableArray *modifiers = [NSMutableArray array];
//    HKModifier modifier = [self modifier];
//    if (modifier & NSShiftKeyMask) [modifiers addObject:@"shift"];
//    if (modifier & NSCommandKeyMask) [modifiers addObject:@"cmd"];
//    if (modifier & NSControlKeyMask) [modifiers addObject:@"ctrl"];
//    if (modifier & NSAlternateKeyMask) [modifiers addObject:@"option"];
//    
//    // if (modifier & NSHelpKeyMask) [modifiers addObject:@"help"];
//    // if (modifier & NSFunctionKeyMask) [modifiers addObject:@"function"];
//    if (modifier & NSNumericPadKeyMask) [modifiers addObject:@"num-pad"];
//    // if (modifier & NSAlphaShiftKeyMask) [modifiers addObject:@"alpha-shift"];
//    if ([modifiers count] > 0)
//      [plist setObject:modifiers forKey:@"modifiers"];
//    
//    HKKeycode code = [self keycode];
//    [plist setObject:WBUInteger(code) forKey:@"keycode"];
//    
//    UniChar ch = [self character];
//    if (CFCharacterSetIsCharacterMember(CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric), ch) ||
//        CFCharacterSetIsCharacterMember(CFCharacterSetGetPredefined(kCFCharacterSetPunctuation), ch) ||
//        CFCharacterSetIsCharacterMember(CFCharacterSetGetPredefined(kCFCharacterSetSymbol), ch)) {
//      NSString *str = [NSString stringWithCharacters:&ch length:1];
//      if (str)
//        [plist setObject:str forKey:@"character"];
//    } else {
//      NSString *str = HKMapGetStringRepresentationForCharacterAndModifier(ch, 0);
//      if (str)
//        [plist setObject:str forKey:@"character"];
//    }
//    [plist setObject:WBUInteger(ch) forKey:@"unichar"];
//  }
//  return plist;
//}

WBForwarding(SparkHotKey, HKHotKey, sp_hotkey);

@end

static SparkHotKey *_SparkHotKeyForHKHotKey(HKHotKey *parent) {
  return (SparkHotKey *)CFDictionaryGetValue(sHKParentMap, parent);
}

#pragma mark -
#pragma mark Key Repeat Support
NSTimeInterval SparkGetDefaultKeyRepeatInterval(void) {
  return HKGetSystemKeyRepeatInterval();
}

@implementation HKHotKey (SparkRepeat)

+ (void)load {
  if (self == [HKHotKey class]) {
    // Swap the implementations of -[HKHotKey keyPressed:] and -[HKHotKey sp_keyPressed:].
    WBRuntimeExchangeInstanceMethods(self, @selector(keyPressed), @selector(sp_keyPressed));
  }
}

- (void)sp_keyPressed {
  /* configure hotkey to match the attached action */
  [_SparkHotKeyForHKHotKey(self) prepareHotKey];
  [self sp_keyPressed];
}

//- (void)didInvoke {
//  [_SparkHotKeyForHKHotKey(self) didInvoke];
//}

@end
