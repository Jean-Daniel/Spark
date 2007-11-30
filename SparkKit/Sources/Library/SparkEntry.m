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

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkActionLoader.h>

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
  return sp_uid;
}

- (BOOL)isEqual:(id)object {
  if ([object class] != [self class]) return NO;
  SparkEntry *entry = (SparkEntry *)object;
  return sp_uid == entry->sp_uid;
}

#pragma mark -
- (UInt32)uid {
  return sp_uid;
}
- (SparkEntry *)parent {
  return sp_parent;
}
- (void)setParent:(SparkEntry *)aParent {
}

#pragma mark Spark Objects
- (SparkAction *)action {
  return sp_action;
}

- (SparkTrigger *)trigger {
  return sp_trigger;
}

- (SparkApplication *)application {
  return sp_application;
}

#pragma mark Type
- (SparkEntryType)type {
  if ([self applicationUID] == kSparkApplicationSystemUID) {
    return kSparkEntryTypeDefault;
  } else if (sp_parent) {
    if ([sp_action isEqual:[sp_parent action]])
      return kSparkEntryTypeWeakOverWrite;
    else
      return kSparkEntryTypeOverWrite;
  } else {
    /* no parent and not system application */
    return kSparkEntryTypeSpecific;
  }
}

#pragma mark Status
- (BOOL)isActive {
  return [self isEnabled] && [self isPlugged];
}

- (BOOL)isEnabled {
  return sp_seFlags.enabled;
}
- (void)setEnabled:(BOOL)flag {
  bool enabled = SKFlagTestAndSet(sp_seFlags.enabled, flag);
  if (enabled != sp_seFlags.enabled && [self isManaged]) {
    // notify manager
  }
}

- (BOOL)isPlugged {
  return !sp_seFlags.unplugged;
}

- (BOOL)isPersistent {
  return [sp_action isPersistent];
}

#pragma mark Properties
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

@end

@implementation SparkEntry (SparkEntryManager)

+ (SparkEntry *)entryWithPlaceholder:(SparkEntryPlaceholder *)placeholder library:(SparkLibrary *)aLibrary {
  SparkAction *act = [aLibrary actionWithUID:[placeholder actionUID]];
  SparkTrigger *trg = [aLibrary triggerWithUID:[placeholder triggerUID]];
  SparkApplication *app = [aLibrary applicationWithUID:[placeholder applicationUID]];
  
  SparkEntry *entry = [SparkEntry entryWithAction:act trigger:trg application:app];
  [entry setEnabled:[placeholder isEnabled]];
  return entry;
}

- (void)setUID:(UInt32)anUID {
  sp_uid = anUID;
}

- (BOOL)isManaged {
  return sp_seFlags.managed;
}
- (void)setManaged:(BOOL)managed {
  SKFlagSet(sp_seFlags.managed, managed);
}

/* cached status */
- (void)setPlugged:(BOOL)flag {
  SKFlagSet(sp_seFlags.unplugged, !flag);
}

/* convenient access */
- (SparkUID)actionUID {
  return [sp_action uid];
}
- (SparkUID)triggerUID {
  return [sp_trigger uid];
}
- (SparkUID)applicationUID {
  return [sp_application uid];
}

- (void)setAction:(SparkAction *)action {
  SKSetterRetain(sp_action, action);
  SparkPlugIn *plugin = action ? [[SparkActionLoader sharedLoader] plugInForAction:action] : nil;
  if (plugin) [self setPlugged:[plugin isEnabled]];
}
- (void)setTrigger:(SparkTrigger *)trigger {
  SKSetterRetain(sp_trigger, trigger);
}
- (void)setApplication:(SparkApplication *)anApplication {
  SKSetterRetain(sp_application, anApplication);
}

@end

@implementation SparkEntry (SparkNetworkMessage)

/* TODO */
- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder {
  if ([encoder isByref]) {
    WLog(@"SparkEntry does not support by ref messaging");
    return nil;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    if ([coder isKindOfClass:[NSPortCoder class]] ) {
      // encode object
    } else {
      [self release];
      [NSException raise:NSInvalidArchiveOperationException format:@"Only supports NSPortCoder coders"];
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  if ([coder isKindOfClass:[NSPortCoder class]] ) {
    // encode object
  } else {
    [NSException raise:NSInvalidArchiveOperationException format:@"Only supports NSPortCoder coders"];
  }
}

@end

#pragma mark -
#pragma mark Placeholder
@implementation SparkEntryPlaceholder

- (id)initWithActionUID:(SparkUID)act triggerUID:(SparkUID)trg applicationUID:(SparkUID)app {
  if (self = [super init]) {
    [self setActionUID:act];
    [self setTriggerUID:trg];
    [self setApplicationUID:app];
  }
  return self;
}

- (BOOL)isEnabled {
  return sp_enabled;
}
- (void)setEnabled:(BOOL)flag {
  sp_enabled = flag;
}

- (SparkUID)actionUID {
  return sp_action;
}
- (SparkUID)triggerUID {
  return sp_trigger;
}
- (SparkUID)applicationUID {
  return sp_application;
}

- (void)setActionUID:(SparkUID)action {
  sp_action = action;
}
- (void)setTriggerUID:(SparkUID)trigger {
  sp_trigger = trigger;
}
- (void)setApplicationUID:(SparkUID)application {
  sp_application = application;
}

@end
