/*
 *  SparkHotKey.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKForwarding.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

#import <SparkKit/SparkHotKey.h>

#import <SparkKit/SparkAction.h>

#define ICON_SIZE		16

static
NSString * const kHotKeyRawCodeKey = @"STRawKey";

SparkFilterMode SparkKeyStrokeFilterMode = kSparkEnableSingleFunctionKey;

/*
 Fonction qui permet de définir la validité d'un raccouci. Depuis 10.3, les raccourcis sans "modifier" sont acceptés.
 Jugés trop génant, seul les touches Fx peuvent être utilisées sans "modifier"
*/
static
const int kCommonModifierMask = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask;

static 
BOOL KeyStrokeFilter(UInt32 code, UInt32 modifier) {
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
@interface NSMutableDictionary (SetMultiplesValues)
- (void)setObject:(id)anObject forKeys:(NSArray *)keys;
@end

#pragma mark -
@implementation SparkHotKey

+ (void)initialize {
  if ([SparkHotKey class] == self) {
    [HKHotKeyManager setShortcutFilter:KeyStrokeFilter];
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

#pragma mark -
#pragma mark Public Methods
- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {uid:%u name:%@ hotkey:%@}",
    [self class], self,
    [self uid], [self name], sp_hotkey];
}

- (BOOL)setRegistred:(BOOL)flag {
  return [sp_hotkey setRegistred:flag];
}
- (NSString *)triggerDescription {
  return [sp_hotkey shortcut];
}

#pragma mark -
#pragma mark Accessors
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    [self setIcon:[NSImage imageNamed:@"KeyIcon" inBundle:SKCurrentBundle()]];
    icon = [super icon];
  }
  return icon;
}

- (void)setIcon:(NSImage *)icon {
  [super setIcon:SKResizedIcon(icon, NSMakeSize(ICON_SIZE, ICON_SIZE))];
}

@end

#pragma mark -
SKForwarding(SparkHotKey, HKHotKey, sp_hotkey);

#pragma mark -
#pragma mark Key Repeat Support Implementation
NSTimeInterval SparkGetDefaultKeyRepeatInterval() {
  return HKGetSystemKeyRepeatInterval();
}

@implementation HKHotKey (SparkRepeat)

- (void)willInvoke:(BOOL)repeat {
  if (!repeat && ![self invokeOnKeyUp]) {
    // Adjust repeat delay.
    __attribute__((unused)) SparkHotKey *key = [self target];
    SparkAction *action = nil; // Resolve action for trigger: key
    [self setRepeatInterval:(action) ? [action repeatInterval] : 0];    
  }
}

@end

//- (SparkApplication *)applicationForProcess:(ProcessSerialNumber *)psn {
//  CFDictionaryRef dico = ProcessInformationCopyDictionary(psn, kProcessDictionaryIncludeAllInformationMask);
//  id result = nil;
//  if (dico) {
//    id creator = (id)CFDictionaryGetValue(dico, CFSTR("FileCreator"));
//    id bundle = (id)CFDictionaryGetValue(dico, kCFBundleIdentifierKey);
//    id objects = [self objectEnumerator];
//    SparkApplication *object;
//    while (object = [objects nextObject]) {
//      if ([[object identifier] isEqualToString:creator] || [[object identifier] isEqualToString:bundle]) {
//        result = object;
//        break;
//      }
//    }
//    CFRelease(dico);
//  }
//  return result;
//}

//- (SparkAction *)actionForFrontProcess {
//  ProcessSerialNumber psn;
//  if (noErr != GetFrontProcess(&psn)) {
//    DLog(@"Unable to get Front Process");
//    return nil;
//  }
//  id appli = [[[self library] applicationLibrary] applicationForProcess:&psn];
//  return (appli) ? [self actionForApplication:appli] : nil;
//}
//
///* First check if an single application correspond, and if not, check into lists */
//- (SparkAction *)actionForApplication:(SparkApplication *)application {
//  id actionUid = [_simpleMap objectForKey:[application uid]];
//  if (!actionUid) {
//    id lists = [[_listMap allKeys] objectEnumerator];
//    id listUid;
//    while (listUid = [lists nextObject]) {
//      id list = [[[self library] listLibrary] objectWithId:listUid];
//      if ([list containsObject:application]) {
//        actionUid = [_listMap objectForKey:listUid];
//        break;
//      }
//    }
//  }
//  return (actionUid) ? [[[self library] actionLibrary] objectWithId:actionUid] : nil;
//}
//
//- (SparkAction *)actionForEntry:(id)entry {
//  id actionUid = nil;
//  if ([entry isKindOfClass:[SparkObjectList class]]) {
//    actionUid = [_listMap objectForKey:[entry uid]];
//  } else if ([entry isKindOfClass:[SparkApplication class]]) {
//    actionUid = [_simpleMap objectForKey:[entry uid]];
//  }
//  return (actionUid) ? [[[self library] actionLibrary] objectWithId:actionUid] : nil;
//}
