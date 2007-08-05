/*
 *  SparkEntry.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkLibrary.h>

#import <ShadowKit/SKSerialization.h>
#import <ShadowKit/SKAppKitExtensions.h>

static
NSImage *SparkEntryDefaultIcon() {
  static NSImage *__simage = nil;
  if (!__simage) 
    __simage = [[NSImage imageNamed:@"SparkEntry" inBundle:[NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]] retain];
  return __simage;
}

@implementation SparkEntry

- (id)copyWithZone:(NSZone *)aZone {
  SparkEntry *copy = (SparkEntry *)NSCopyObject(self, 0, aZone);
  [copy->sp_action retain];
  [copy->sp_trigger retain];
  [copy->sp_application retain];
  return copy;
}

+ (id)entryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  return [[[self alloc] initWithAction:anAction trigger:aTrigger application:anApplication] autorelease];
}

- (id)initWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication {
  if (self = [super init]) {
    [self setAction:anAction];
    [self setTrigger:aTrigger];
    [self setApplication:anApplication];
  }
  return self;
}

- (void)dealloc {
  [sp_action release];
  [sp_trigger release];
  [sp_application release];
  [super dealloc];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"{ Trigger: %@, Action: %@, Application: %@}", 
    sp_trigger, sp_action, [sp_application name]];
}

- (NSUInteger)hash {
  return [sp_application uid] << 16 & [sp_trigger uid];
}

- (BOOL)isEqual:(id)object {
  if ([object class] != [self class]) return NO;
  SparkEntry *entry = (SparkEntry *)object;
  return [sp_action uid] == [[entry action] uid] &&
    [sp_trigger uid] == [[entry trigger] uid] &&
    [sp_application uid] == [[entry application] uid];
}

#pragma mark -
- (SparkAction *)action {
  return sp_action;
}
- (void)setAction:(SparkAction *)action {
  SKSetterRetain(sp_action, action);
}

- (id)trigger {
  return sp_trigger;
}
- (void)setTrigger:(SparkTrigger *)trigger {
  SKSetterRetain(sp_trigger, trigger);
}

- (SparkApplication *)application {
  return sp_application;
}
- (void)setApplication:(SparkApplication *)anApplication {
  SKSetterRetain(sp_application, anApplication);
}

- (SparkEntryType)type {
  return sp_seFlags.type;
}
- (void)setType:(SparkEntryType)type {
  sp_seFlags.type = type;
}

- (BOOL)isActive {
  return [self isEnabled] && [self isPlugged];
}

- (BOOL)isEnabled {
  return sp_seFlags.enabled;
}
- (void)setEnabled:(BOOL)enabled {
  SKSetFlag(sp_seFlags.enabled, enabled);
}

- (BOOL)isPlugged {
  return !sp_seFlags.unplugged;
}
- (void)setPlugged:(BOOL)flag {
  SKSetFlag(sp_seFlags.unplugged, !flag);
}

- (NSImage *)icon {
  return [sp_action icon] ? : SparkEntryDefaultIcon();
}
- (void)setIcon:(NSImage *)anIcon {
  [sp_action setIcon:anIcon];
}

- (NSString *)name {
  return [sp_action name];
}
- (void)setName:(NSString *)aName {
  [sp_action setName:aName];
}

- (NSString *)categorie {
  return [sp_action categorie];
}
- (NSString *)actionDescription {
  return [sp_action actionDescription];
}
- (NSString *)triggerDescription {
  return [sp_trigger triggerDescription];
}

- (BOOL)serialize:(NSMutableDictionary *)plist {
  BOOL ok = NO;
  [plist setObject:SKUInt(0) forKey:@"version"];
  NSDictionary *dict = SKSerializeObject(sp_action, NULL);
  if (dict) {
    ok = YES;
    [plist setObject:dict forKey:@"action"];
    
    if (sp_application && [sp_application uid] != kSparkApplicationSystemUID) {
      NSMutableDictionary *app = [[NSMutableDictionary alloc] init];
      ok = [[sp_application application] serialize:app];
      if (ok) {
        [plist setObject:app forKey:@"application"];
      }
      [app release];
    } 
      
    /* Serialize Trigger */
    if (ok) {
      NSMutableDictionary *key = [[NSMutableDictionary alloc] init];
      
      NSMutableArray *modifiers = [[NSMutableArray alloc] init];
      HKModifier modifier = [(SparkHotKey *)sp_trigger modifier];
      if (modifier & NSShiftKeyMask) [modifiers addObject:@"shift"];
      if (modifier & NSCommandKeyMask) [modifiers addObject:@"cmd"];
      if (modifier & NSControlKeyMask) [modifiers addObject:@"ctrl"];
      if (modifier & NSAlternateKeyMask) [modifiers addObject:@"option"];

      //      if (modifier & NSHelpKeyMask) [modifiers addObject:@"help"];
      //      if (modifier & NSFunctionKeyMask) [modifiers addObject:@"function"];
      if (modifier & NSNumericPadKeyMask) [modifiers addObject:@"num-pad"];
      //      if (modifier & NSAlphaShiftKeyMask) [modifiers addObject:@"alpha-shift"];
      if ([modifiers count] > 0)
        [key setObject:modifiers forKey:@"modifiers"];
      [modifiers release];
      
      HKKeycode code = [(SparkHotKey *)sp_trigger keycode];
      [key setObject:SKUInteger(code) forKey:@"keycode"];
      
      UniChar ch = [(SparkHotKey *)sp_trigger character];
      if (CFCharacterSetIsCharacterMember(CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric), ch) ||
          CFCharacterSetIsCharacterMember(CFCharacterSetGetPredefined(kCFCharacterSetPunctuation), ch) ||
          CFCharacterSetIsCharacterMember(CFCharacterSetGetPredefined(kCFCharacterSetSymbol), ch)) {
        NSString *str = [NSString stringWithCharacters:&ch length:1];
        if (str)
          [key setObject:str forKey:@"character"];
      } else {
        NSString *str = HKMapGetStringRepresentationForCharacterAndModifier(ch, 0);
        if (str)
          [key setObject:str forKey:@"character"];
      }
      [key setObject:SKUInteger(ch) forKey:@"unichar"];
      [plist setObject:key forKey:@"trigger"];
      [key release];
    }
  }
  return ok;
}

@end
