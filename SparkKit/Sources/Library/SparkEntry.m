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

enum {
  /* Persistents flags */
  kSparkEntryEnabled = 1 << 0,
  /* Volatile flags */
  kSparkEntryUnplugged = 1 << 16,
  kSparkPersistentFlagsMask = 0xffff,
};

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
  return (sp_flags & kSparkEntryEnabled) != 0;
}
- (void)setEnabled:(BOOL)enabled {
  if (enabled) sp_flags |= kSparkEntryEnabled;
  else sp_flags &= ~kSparkEntryEnabled;
}

- (BOOL)isPlugged {
  return (sp_flags & kSparkEntryUnplugged) == 0;
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

- (void)setUID:(UInt32)anUID {
  sp_uid = anUID;
}

/* cached status */
- (void)setPlugged:(BOOL)flag {
  if (flag) sp_flags &= ~kSparkEntryUnplugged;
  else sp_flags |= kSparkEntryUnplugged;
}

/* fast access */
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
