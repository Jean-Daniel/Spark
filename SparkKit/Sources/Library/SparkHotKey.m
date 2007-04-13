/*
 *  SparkHotKey.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#include <Carbon/Carbon.h>

#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkAction.h>

#import <ShadowKit/SKForwarding.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

static
NSString * const kHotKeyRawCodeKey = @"STRawKey";

SparkFilterMode SparkKeyStrokeFilterMode = kSparkEnableSingleFunctionKey;

/*
 Fonction qui permet de définir la validité d'un raccouci. Depuis 10.3, les raccourcis sans "modifier" sont acceptés.
 Jugés trop génant, seul les touches Fx peuvent être utilisées sans "modifier"
*/
static
const NSInteger kCommonModifierMask = kCGEventFlagMaskCommand | kCGEventFlagMaskControl | kCGEventFlagMaskShift | kCGEventFlagMaskAlternate;

static 
BOOL _SparkKeyStrokeFilter(HKKeycode code, HKModifier modifier) {
  if ((modifier & kCommonModifierMask) != 0) {
    return YES;
  }
  
  switch (SparkKeyStrokeFilterMode) {
    case kSparkDisableAllSingleKey:
      return NO;
    case kSparkEnableAllSingleKey:
      return YES;
    case kSparkEnableAllSingleButNavigation:
      switch (code) {
        case kVirtualTabKey:
        case kVirtualEnterKey:
        case kVirtualReturnKey:
        case kVirtualEscapeKey:
        case kVirtualLeftArrowKey:
        case kVirtualRightArrowKey:
        case kVirtualUpArrowKey:
        case kVirtualDownArrowKey:
          return NO;
      }
      return YES;
    case kSparkEnableSingleFunctionKey:
      switch (code) {
        case kVirtualF1Key:
        case kVirtualF2Key:
        case kVirtualF3Key:
        case kVirtualF4Key:
        case kVirtualF5Key:
        case kVirtualF6Key:
        case kVirtualF7Key:
        case kVirtualF8Key:
        case kVirtualF9Key:
        case kVirtualF10Key:
        case kVirtualF11Key:
        case kVirtualF12Key:
        case kVirtualF13Key:
        case kVirtualF14Key:
        case kVirtualF15Key:
        case kVirtualF16Key:
        case kVirtualHelpKey:
        case kVirtualClearLineKey:
          return YES;
      }
      break;
  }
  return NO;
}

#pragma mark -
@implementation SparkHotKey

+ (void)initialize {
  if ([SparkHotKey class] == self) {
    [HKHotKeyManager setShortcutFilter:_SparkKeyStrokeFilter];
    /* Load current map */
    HKMapGetCurrentMapName();
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
  copy->sp_hotkey = [sp_hotkey retain];
  return copy;
}

#pragma mark SparkSerialization
- (BOOL)serialize:(NSMutableDictionary *)plist {
  [super serialize:plist];
  UInt64 hotkey = [sp_hotkey rawkey];
  [plist setObject:SKULongLong(hotkey) forKey:kHotKeyRawCodeKey];
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
  }
  return self;
}

- (void)dealloc {
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
  [sp_hotkey sendKeystroke];
}
- (BOOL)isRegistred {
  return [sp_hotkey isRegistred];
}
- (BOOL)setRegistred:(BOOL)flag {
  [super setRegistred:flag];
  return [sp_hotkey setRegistred:flag];
}
- (NSString *)triggerDescription {
  return [sp_hotkey shortcut];
}

- (BOOL)isEqualToTrigger:(SparkTrigger *)aTrigger {
  return [aTrigger isKindOfClass:[SparkHotKey class]] && [self rawkey] == [(id)aTrigger rawkey];
}

#pragma mark Current Event
- (NSTimeInterval)eventTime {
  return GetCurrentEventTime();
}
- (void)trigger:(id)sender {
  [self setIsARepeat:[sender isARepeat]];
  [super trigger:sender];
}

#pragma mark -
#pragma mark Accessors
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    [self setIcon:[NSImage imageNamed:@"hotkey" inBundle:SKCurrentBundle()]];
    icon = [super icon];
  }
  return icon;
}


@end

#pragma mark -
SKForwarding(SparkHotKey, HKHotKey, sp_hotkey);

#pragma mark -
#pragma mark Key Repeat Support
NSTimeInterval SparkGetDefaultKeyRepeatInterval() {
  return HKGetSystemKeyRepeatInterval();
}

@implementation HKHotKey (SparkRepeat)

- (void)didInvoke:(BOOL)repeat {
  if (!repeat && ![self invokeOnKeyUp]) {
    // Adjust repeat delay.
    SparkAction *action = [SparkTrigger currentAction];
    [self setRepeatInterval:(action) ? [action repeatInterval] : HKGetSystemKeyRepeatInterval()];    
  }
}

@end
