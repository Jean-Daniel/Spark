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

#import "SparkLibraryPrivate.h"
#import "SparkEntryManagerPrivate.h"

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
  [sp_child release];
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
- (BOOL)isSystem {
  return [sp_application uid] == kSparkApplicationSystemUID;
}
- (BOOL)isOverridden {
  NSParameterAssert([self isSystem]);
  return sp_child != nil;
}

- (BOOL)isActive {
  return [self isEnabled] && [self isPlugged];
}

- (BOOL)isEnabled {
  return sp_seFlags.enabled;
}
- (void)setEnabled:(BOOL)flag {
  bool enabled = SKFlagTestAndSet(sp_seFlags.enabled, flag);
  if (enabled != sp_seFlags.enabled && sp_manager) {
    if (flag)
      [sp_manager enableEntry:self];
    else
      [sp_manager disableEntry:self];
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

- (void)setUID:(UInt32)anUID {
  sp_uid = anUID;
}

- (SparkEntryManager *)manager {
  return sp_manager;
}
- (void)setManager:(SparkEntryManager *)aManager {
  sp_manager = aManager;
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

/* update object */
- (void)appendChild:(SparkEntry *)anEntry {
  NSParameterAssert([self isSystem]);
  anEntry->sp_child = sp_child;
  sp_child = [anEntry retain];
}
- (void)removeChild:(SparkEntry *)aChild {
  NSParameterAssert([self isSystem]);
  NSParameterAssert([aChild parent] == self);
  
  SparkEntry *item = self;
  while (item = item->sp_child) {
    if (item == aChild) {
      item->sp_child = aChild->sp_child;
      [aChild setParent:nil];
      [aChild release];
      break;
    }
  }
}

- (void)setParent:(SparkEntry *)aParent {
  NSParameterAssert(![self isSystem]);
  if (aParent != sp_parent) {
    if (sp_parent) {
      /* remove from previous */
      [sp_parent removeChild:self];
    }
    sp_parent = aParent;
    if (sp_parent) {
      [sp_parent appendChild:self];
    }
  }
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

- (SparkEntry *)childWithApplication:(SparkApplication *)anApplication {
  NSParameterAssert([anApplication isSystem]);
  SparkEntry *child = self;
  SparkUID uid = [anApplication uid];
  while (child = self->sp_child) {
    if ([child applicationUID] == uid)
      return child;
  }
  return NULL;
}

- (SparkEntry *)firstChild {
  NSParameterAssert([self isSystem]);
  return sp_child;
}
- (SparkEntry *)sibling {
  NSParameterAssert(![self isSystem]);
  return sp_child;
}

@end

@implementation SparkEntry (SparkNetworkMessage)

- (id)replacementObjectForPortCoder:(NSPortCoder *)encoder {
  if ([encoder isByref]) {
    WLog(@"SparkEntry does not support by ref messaging");
    return nil;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super init]) {
    SparkLibrary *library = nil;
    if ([coder isKindOfClass:[NSPortCoder class]] ) {
      library = SparkActiveLibrary();
      SparkUID uid = SKDecodeInteger(coder, @"parent");
      if (uid) {
        /* TODO: restore parent */
      }
    } else if ([coder isKindOfClass:[SparkLibraryUnarchiver class]]) {
      library = [(SparkLibraryUnarchiver *)coder library];
      sp_parent = [coder decodeObjectForKey:@"parent"];
      sp_child = [[coder decodeObjectForKey:@"child"] retain];
    } 
    if (!library) {
      [self release];
      [NSException raise:NSInvalidArchiveOperationException format:@"Unsupported coder: %@", coder];
    }
    /* decode entry */
    sp_uid = SKDecodeInteger(coder, @"uid");
    
    SparkUID uid;
    uid = SKDecodeInteger(coder, @"action");
    [self setAction:[library actionWithUID:uid]];
    
    uid = SKDecodeInteger(coder, @"trigger");
    [self setTrigger:[library triggerWithUID:uid]];
    
    uid = SKDecodeInteger(coder, @"application");
    [self setApplication:[library applicationWithUID:uid]];
    
    [self setEnabled:[coder decodeBoolForKey:@"enabled"]];
  }
  return self;
}

- (void)sp_encodeWithCoder:(NSCoder *)coder {
  SKEncodeInteger(coder, sp_uid, @"uid");
  SKEncodeInteger(coder, [sp_action uid], @"action");
  SKEncodeInteger(coder, [sp_trigger uid], @"trigger");
  SKEncodeInteger(coder, [sp_application uid], @"application");
  /* flags */
  [coder encodeBool:[self isEnabled] forKey:@"enabled"];
}

- (void)encodeWithCoder:(NSCoder *)coder {
  if ([coder isKindOfClass:[NSPortCoder class]]) {
    SKEncodeInteger(coder, [sp_parent uid], @"parent");
  } else if ([coder isKindOfClass:[SparkLibraryArchiver class]]) {
    [coder encodeObject:sp_child forKey:@"child"];
    [coder encodeConditionalObject:sp_parent forKey:@"parent"];
  } else {
    [NSException raise:NSInvalidArchiveOperationException format:@"Unsupported coder: %@", coder];
  }
  [self sp_encodeWithCoder:coder];
}

@end
