//
//  HKHotKey.m
//  Spark
//
//  Created by Fox on Mon Jan 05 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "HKHotKey.h"

#import "HKKeyMap.h"
#import "HKHotKeyManager.h"

#ifdef DEBUG
#warning Debug defined in HotKeyToolKit!
#endif

@interface HKHotKey (Private) 
- (void)_invalidateTimer;
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
  copy->hk_keyRepeat = hk_keyRepeat;
  
  /* Key isn't registred */
  copy->hk_isRegistred = NO;
  return copy;
}

#pragma mark -
#pragma mark Convenient constructors.

+ (id)hotkey {
  return [[[self alloc] init] autorelease];
}
+ (id)hotkeyWithKeycode:(int)code modifier:(int)modifier {
  return [[[self alloc] initWithKeycode:code modifier:modifier] autorelease];
}
+ (id)hotkeyWithUnichar:(unichar)character modifier:(int)modifier {
  return [[[self alloc] initWithUnichar:character modifier:modifier] autorelease];
}

#pragma mark -
#pragma mark Initializers

- (id)init {
  if (self = [super init]) {
    hk_isRegistred = NO;
    hk_character = kHKNilUnichar;
    hk_keycode = kHKNilVirtualKeyCode;
  }
  return self;
}

- (id)initWithKeycode:(int)code modifier:(int)modifier {
  if (self = [self init]) {
    [self setModifier:modifier];
    [self setKeycode:code];
  }
  return self;
}

- (id)initWithUnichar:(unichar)character modifier:(int)modifier {
  if (self = [self init]) {
    [self setModifier:modifier];
    [self setCharacter:character];
  }
  return self;
}

- (void)dealloc {
  [self _invalidateTimer];
  [self setRegistred:NO];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@, %p> {keycode:0x%x character:%C modifier:0x%x repeat:%f isRegistred:%@ }",
    [self className], self,
    [self keycode], [self character], [self modifier], [self keyRepeat],
    ([self isRegistred] ? @"YES" : @"NO")];
}

#pragma mark -
#pragma mark Misc Properties

- (BOOL)isValid {
  return ([self character] != kHKNilUnichar) && ([self keycode] != kHKNilVirtualKeyCode);
}

- (NSString*)shortCut {
  return HKStringRepresentationForCharacterAndModifier([self character], hk_mask);
}
- (void)setShortCut:(NSString *)sc {
#pragma unused(sc)
}

#pragma mark -
#pragma mark iVar Accessors.

- (unsigned int)modifier {
  return hk_mask;
}
- (void)setModifier:(unsigned int)modifier {
  if (![self isRegistred]) {
    hk_mask = modifier;
  }
  else {
    [NSException raise:@"HKInvalidHotKeyChangeException" format:@"Cannot change modifier when Hotkey is registred"];
  }
}

- (unsigned short)keycode {
  if (hk_keycode == kHKNilVirtualKeyCode && hk_character != kHKNilUnichar)
    [self setKeycode:HKKeycodeForUnichar(hk_character) andCharacter:hk_character];
  return hk_keycode;
}
- (void)setKeycode:(unsigned short)keycode {
  [self setKeycode:keycode andCharacter:kHKNilUnichar];
}

- (unichar)character {
  if (hk_character == kHKNilUnichar && hk_keycode != kHKNilVirtualKeyCode)
    [self setKeycode:hk_keycode andCharacter:HKUnicharForKeycode(hk_keycode)];
  return hk_character;
}
- (void)setCharacter:(unichar)character {
  [self setKeycode:kHKNilVirtualKeyCode andCharacter:character];
}

- (void)setKeycode:(unsigned short)keycode andCharacter:(unichar)character {
  if (![self isRegistred]) { 
    hk_keycode = keycode;
    hk_character = character;
  }
  else {
    [NSException raise:@"HKInvalidHotKeyChangeException" format:@"Cannot change keycode or character when Hotkey is registred"];
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
  return hk_isRegistred;
}
- (BOOL)setRegistred:(BOOL)flag {
  // Si la clŽ n'est pas valide
  if (![self isValid]) {
    return NO;
  }
  BOOL result;
  @synchronized (self) {
    // Si la clŽ est dŽja dans l'Žtat demandŽ
    if (flag == hk_isRegistred) {
      return YES;
    }
    result = YES;
    if (flag) { // Si on veut l'enregister
      if ([[HKHotKeyManager sharedManager] registerHotKey:self]) {
        hk_isRegistred = YES; // On note qu'elle est enregistrŽ
      }
      else {
        result = NO;
      }
    }
    else { // Si on veut la supprimer
      [self _invalidateTimer];
      result = [[HKHotKeyManager sharedManager] unregisterHotKey:self];
      hk_isRegistred = NO;
    }
  }
  return result;
}

- (NSTimeInterval)keyRepeat {
  return hk_keyRepeat;
}

- (void)setKeyRepeat:(NSTimeInterval)interval {
  hk_keyRepeat = interval;
}

#pragma mark -
#pragma mark Invoke
- (void)keyPressed {
  [self _invalidateTimer];
  [self invoke];
  if ([self keyRepeat] > 0) {
    id fire = [[NSDate alloc] initWithTimeIntervalSinceNow:HKGetSystemInitialKeyRepeatInterval()];
    hk_repeatTimer = [[NSTimer alloc] initWithFireDate:fire interval:[self keyRepeat] target:self selector:@selector(invoke:) userInfo:nil repeats:YES];
    [fire release];
    [[NSRunLoop currentRunLoop] addTimer:hk_repeatTimer forMode:NSDefaultRunLoopMode];
  }
}

- (void)keyReleased {
  [self _invalidateTimer];
}

- (void)invoke {
  @try {
    if (hk_action && [hk_target respondsToSelector:hk_action]) {
      [hk_target performSelector:hk_action withObject:self];
    }
  } 
  @catch (id exception) {
#if defined(DEBUG)
    NSLog(@"Exception occured in [%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), exception);
#endif
  }
}

#pragma mark -
#pragma mark Private
- (void)_invalidateTimer {
  if (hk_repeatTimer) {
    [hk_repeatTimer invalidate];
    [hk_repeatTimer release];
    hk_repeatTimer = nil;
  }
}

- (void)invoke:(NSTimer *)timer {
#if defined (DEBUG)
  NSLog(@"Repeat Key");
#endif
  [self invoke];
}

@end

#pragma mark -
NSTimeInterval HKGetSystemKeyRepeatInterval() {
  Boolean exist;
  CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);  
  CFIndex pref = CFPreferencesGetAppIntegerValue(CFSTR("KeyRepeat"), kCFPreferencesAnyApplication, &exist);
  if (!exist) {
    pref = 6;
  }
  return 0.015 * pref;
}

NSTimeInterval HKGetSystemInitialKeyRepeatInterval() {
  Boolean exist;
  CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
  CFIndex pref = CFPreferencesGetAppIntegerValue(CFSTR("InitialKeyRepeat"), kCFPreferencesAnyApplication, &exist);
  if (!exist) {
    pref = 35;
  }
  return 0.015 * pref;
}
