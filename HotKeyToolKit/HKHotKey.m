/*
 *  HKHotKey.m
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "HKHotKey.h"

#import "HKKeyMap.h"
#import "HKHotKeyManager.h"
#include <IOKit/hidsystem/IOHIDLib.h>
#include <IOKit/hidsystem/IOHIDParameter.h>

@interface HKHotKey (Private) 
- (void)hk_invalidateTimer;

- (BOOL)shouldChangeKeystroke;
@end

@implementation HKHotKey

- (id)copyWithZone:(NSZone *)zone {
  HKHotKey *copy = [[[self class] allocWithZone:zone] init];
  copy->hk_target = hk_target;
  copy->hk_action = hk_action;
  
  copy->hk_mask = hk_mask;
  copy->hk_keycode = hk_keycode;
  copy->hk_character = hk_character;
  
  copy->hk_repeatTimer = nil;
  copy->hk_repeatInterval = hk_repeatInterval;
  
  /* Key isn't registred */
  copy->hk_hkFlags.onrelease = hk_hkFlags.onrelease;
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeConditionalObject:hk_target forKey:@"HKTarget"];
  [aCoder encodeObject:NSStringFromSelector(hk_action) forKey:@"HKAction"];
  
  [aCoder encodeInt32:hk_mask forKey:@"HKMask"];
  [aCoder encodeInt32:hk_keycode forKey:@"HKKeycode"];
  [aCoder encodeInt32:hk_character forKey:@"HKCharacter"];
  
  [aCoder encodeDouble:hk_repeatInterval forKey:@"HKRepeatInterval"];
}

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super init]) {
    hk_target = [aCoder decodeObjectForKey:@"HKTarget"];
    NSString *action = [aCoder decodeObjectForKey:@"HKAction"];
    if (action)
      hk_action = NSSelectorFromString(action);
    
    hk_mask = [aCoder decodeInt32ForKey:@"HKMask"];
    hk_keycode = [aCoder decodeInt32ForKey:@"HKKeycode"];
    hk_character = [aCoder decodeInt32ForKey:@"HKCharacter"];
    
    hk_repeatInterval = [aCoder decodeDoubleForKey:@"HKRepeatInterval"];
  }
  return self;
}

#pragma mark -
#pragma mark Convenient constructors.
+ (id)hotkey {
  return [[[self alloc] init] autorelease];
}
+ (id)hotkeyWithKeycode:(HKKeycode)code modifier:(NSUInteger)modifier {
  return [[[self alloc] initWithKeycode:code modifier:modifier] autorelease];
}
+ (id)hotkeyWithUnichar:(UniChar)character modifier:(NSUInteger)modifier {
  return [[[self alloc] initWithUnichar:character modifier:modifier] autorelease];
}

#pragma mark -
#pragma mark Initializers

- (id)init {
  if (self = [super init]) {
    hk_character = kHKNilUnichar;
    hk_keycode = kHKInvalidVirtualKeyCode;
  }
  return self;
}

- (id)initWithKeycode:(HKKeycode)code modifier:(NSUInteger)modifier {
  if (self = [self init]) {
    [self setKeycode:code];
    [self setModifier:modifier];
  }
  return self;
}

- (id)initWithUnichar:(UniChar)character modifier:(NSUInteger)modifier {
  if (self = [self init]) {
    [self setModifier:modifier];
    [self setCharacter:character];
  }
  return self;
}

- (void)dealloc {
  [self hk_invalidateTimer];
  [self setRegistred:NO];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> {keycode:%#x character:%#x modifier:%#x repeat:%f isRegistred:%@ }",
    [self class], self,
    [self keycode], [self character], [self modifier], [self repeatInterval],
    ([self isRegistred] ? @"YES" : @"NO")];
}

#pragma mark -
#pragma mark Misc Properties

- (BOOL)isValid {
  return ([self character] != kHKNilUnichar) && ([self keycode] != kHKInvalidVirtualKeyCode);
}

- (NSString*)shortcut {
  return HKMapGetStringRepresentationForCharacterAndModifier([self character], hk_mask);
}
/* KVC compliance */
- (void)setShortcut:(NSString *)sc {
#pragma unused(sc)
}

#pragma mark -
#pragma mark iVar Accessors.
- (BOOL)shouldChangeKeystroke {
  if ([self isRegistred]) {
		SKThrowException(NSInvalidArgumentException, @"Cannot change keystroke when the receiver is registred");
  }
  return YES;
}

- (NSUInteger)modifier {
  return HKUtilsConvertModifier(hk_mask, kHKModifierFormatNative, kHKModifierFormatCocoa);
}
- (void)setModifier:(NSUInteger)modifier {
  if ([self shouldChangeKeystroke]) {
    hk_mask = (HKModifier)HKUtilsConvertModifier(modifier, kHKModifierFormatCocoa, kHKModifierFormatNative);
  }
}
- (HKModifier)nativeModifier {
  return hk_mask;
}
- (void)setNativeModifier:(HKModifier)modifier {
  if ([self shouldChangeKeystroke]) {
    hk_mask = modifier;
  }
}

- (HKKeycode)keycode {
  return hk_keycode;
}
- (void)setKeycode:(HKKeycode)keycode {
  if ([self shouldChangeKeystroke]) {
    hk_keycode = keycode;
    if (hk_keycode != kHKInvalidVirtualKeyCode) {
      hk_character = HKMapGetUnicharForKeycode(hk_keycode);  
    } else {
      hk_character = kHKNilUnichar;
    }
  }
}

- (UniChar)character {
  return hk_character;
}
- (void)setCharacter:(UniChar)character {
  if ([self shouldChangeKeystroke]) {
    [self setKeycode:HKMapGetKeycodeAndModifierForUnichar(character, NULL)];
  }
}

- (void)setKeycode:(HKKeycode)keycode character:(UniChar)character {
  if ([self shouldChangeKeystroke]) {
    hk_keycode = keycode;
    hk_character = character;
  }
}

- (id)target {
  return hk_target;
}
- (void)setTarget:(id)newTarget {
  hk_target = newTarget;
}

- (SEL)action {
  return hk_action;
}
- (void)setAction:(SEL)newAction {
  hk_action = newAction;
}

- (BOOL)isRegistred {
  return hk_hkFlags.registred;
}
- (BOOL)setRegistred:(BOOL)flag {
  // Si la clé n'est pas valide
  if (![self isValid]) {
    return NO;
  }
  BOOL result;
  @synchronized (self) {
    flag = flag ? 1 : 0;
    // Si la clé est déja dans l'état demandé
    if (flag == hk_hkFlags.registred) {
      return YES;
    }
    result = YES;
    if (flag) { // if register
      if ([[HKHotKeyManager sharedManager] registerHotKey:self]) {
        hk_hkFlags.registred = 1; // Set registred flag
      } else {
        result = NO;
      }
    } else { // If unregister
      [self hk_invalidateTimer];
      hk_hkFlags.registred = 0;
      result = [[HKHotKeyManager sharedManager] unregisterHotKey:self];
    }
  }
  return result;
}

- (BOOL)invokeOnKeyUp {
  return hk_hkFlags.onrelease;
}
- (void)setInvokeOnKeyUp:(BOOL)flag {
  SKFlagSet(hk_hkFlags.onrelease, flag);
}

- (NSTimeInterval)repeatInterval {
  return hk_repeatInterval;
}

- (void)setRepeatInterval:(NSTimeInterval)interval {
  hk_repeatInterval = interval;
}

#pragma mark Key Serialization
- (UInt64)rawkey {
  return HKHotKeyPackKeystoke([self keycode], [self nativeModifier], [self character]);
}

- (void)setRawkey:(UInt64)rawkey {
  HKKeycode keycode;
  UniChar character;
  HKModifier modifier;
  HKHotKeyUnpackKeystoke(rawkey, &keycode, &modifier, &character);
  [self setKeycode:keycode character:character];
  [self setNativeModifier:modifier];
}

#pragma mark -
#pragma mark Invoke
- (void)keyPressed {
  [self hk_invalidateTimer];
  if (hk_hkFlags.onrelease) {
    hk_hkFlags.invoked = 0;
  } else {
    /* Flags used to avoid double invocation if 'on release' change during invoke */
    hk_hkFlags.invoked = 1;
    [self invoke:NO];
    if ([self repeatInterval] > 0) {
      NSTimeInterval value = HKGetSystemInitialKeyRepeatInterval();
      if (value > 0) {
        NSDate *fire = [[NSDate alloc] initWithTimeIntervalSinceNow:value];
        hk_repeatTimer = [[NSTimer alloc] initWithFireDate:fire 
                                                  interval:[self repeatInterval]
                                                    target:self
                                                  selector:@selector(hk_invoke:)
                                                  userInfo:nil
                                                   repeats:YES];
        [fire release];
        [[NSRunLoop currentRunLoop] addTimer:hk_repeatTimer forMode:NSDefaultRunLoopMode];
      }
    }
  }
}

- (void)keyReleased {
  [self hk_invalidateTimer];
  if (hk_hkFlags.onrelease && !hk_hkFlags.invoked) {
    [self invoke:NO];
  }
}

- (void)invoke:(BOOL)repeat {
  if (!hk_hkFlags.lock) {
    SKFlagSet(hk_hkFlags.repeat, repeat);
    [self willInvoke:repeat];
    hk_hkFlags.lock = 1;
    @try {
      if (hk_action && [hk_target respondsToSelector:hk_action]) {
        [hk_target performSelector:hk_action withObject:self];
      }
    } 
    @catch (id exception) {
      SKLogException(exception);
    }
    hk_hkFlags.lock = 0;
    [self didInvoke:repeat];
    SKFlagSet(hk_hkFlags.repeat, NO);
  } else {
    WLog(@"Recursive call in %@", self);
    // Maybe resend event ?
  }
}

- (BOOL)isARepeat {
  return hk_hkFlags.repeat;
}

- (void)willInvoke:(BOOL)repeat {}
- (void)didInvoke:(BOOL)repeat {}

#pragma mark -
#pragma mark Private
- (void)hk_invalidateTimer {
  if (hk_repeatTimer) {
    [hk_repeatTimer invalidate];
    [hk_repeatTimer release];
    hk_repeatTimer = nil;
  }
}

- (void)hk_invoke:(NSTimer *)timer {
  if (HKTraceHotKeyEvents) {
    NSLog(@"Repeat event: %@", self);
  }
  [self invoke:YES];
}

@end

UInt64 HKHotKeyPackKeystoke(HKKeycode keycode, HKModifier modifier, UniChar chr) {
  UInt64 packed = chr;
  packed |= modifier & 0x00ff0000;
  packed |= (keycode << 24) & 0xff000000;
  return packed;
}

void HKHotKeyUnpackKeystoke(UInt64 rawkey, HKKeycode *outKeycode, HKModifier *outModifier, UniChar *outChr) {
  UniChar character = rawkey & 0x0000ffff;
  HKModifier modifier = (HKModifier)(rawkey & 0x00ff0000);
  HKKeycode keycode = (rawkey & 0xff000000) >> 24;
  if (keycode == 0xff) keycode = kHKInvalidVirtualKeyCode;
  BOOL isSpecialKey = (modifier & (kCGEventFlagMaskNumericPad | kCGEventFlagMaskSecondaryFn)) != 0;
  if (!isSpecialKey) {
    /* If key is a number (not in numpad) we use keycode, because american keyboard use number */
    if (character >= '0' && character <= '9')
      isSpecialKey = YES;
  }
  /* we should use keycode if this is a special keycode (fonction, numpad, ...). */
  /* else we try to resolve keycode using modifier */
  /* if conversion fail, we use keycode, and we update character */
  if (!isSpecialKey || (kHKInvalidVirtualKeyCode == keycode)) {
    /* update keycode to reflect character */
    HKKeycode newCode = HKMapGetKeycodeAndModifierForUnichar(character, NULL);
    if (kHKInvalidVirtualKeyCode != newCode)
      keycode = newCode;
    else
      character = HKMapGetUnicharForKeycode(keycode);
  } else {
    character = HKMapGetUnicharForKeycode(keycode);
  }
  if (outChr) *outChr = character;
  if (outKeycode) *outKeycode = keycode;
  if (outModifier) *outModifier = modifier;
}

#pragma mark -
static
io_connect_t _HKHIDGetSystemService(void) {
  static mach_port_t sSystemService = 0;
  if (sSystemService)
    return sSystemService;
  @synchronized([HKHotKey class]) {
    if (!sSystemService) {
      kern_return_t kr;
      mach_port_t service, iter;
      
      kr = IOServiceGetMatchingServices(kIOMasterPortDefault, 
                                        IOServiceMatching(kIOHIDSystemClass), &iter);
      check(KERN_SUCCESS == kr);
      
      service = IOIteratorNext(iter);
      check(service);
      
      kr = IOServiceOpen(service, mach_task_self(),  
                         kIOHIDParamConnectType, &sSystemService);
      check(KERN_SUCCESS == kr);
      
      IOObjectRelease(service);
      IOObjectRelease(iter);
    }
  }
  
  return sSystemService;
}

NSTimeInterval HKGetSystemKeyRepeatInterval() {
  uint64_t value = 0;
  NSTimeInterval interval = -1;
  io_connect_t service = _HKHIDGetSystemService();
  if (service) {
    IOByteCount size = 0;
    kern_return_t kr = IOHIDGetParameter(service, CFSTR(kIOHIDKeyRepeatKey), 
                                         (IOByteCount)sizeof(value), &value, &size);
    /* convert nano into seconds */
    if (KERN_SUCCESS == kr && size == sizeof(value))
      interval = value / 1e9;
  }
  return interval;
}

NSTimeInterval HKGetSystemInitialKeyRepeatInterval() {
  uint64_t value = 0;
  NSTimeInterval interval = -1;
  io_connect_t service = _HKHIDGetSystemService();
  if (service) {
    IOByteCount size = 0;
    kern_return_t kr = IOHIDGetParameter(service, CFSTR(kIOHIDInitialKeyRepeatKey), 
                                         (IOByteCount)sizeof(value), &value, &size);
    /* convert nano into seconds */
    if (KERN_SUCCESS == kr && size == sizeof(value))
      interval = value / 1e9;
  }
  return interval;
}
