/*
 *  SparkLibrarySynchronizer.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkLibrarySynchronizer.h>

#import "SparkEntryManagerPrivate.h"

#import <SparkKit/SparkPrivate.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkActionLoader.h>

enum {
  kSparkActionType      = 'acti',
  kSparkTriggerType     = 'trig',
  kSparkApplicationType = 'appl'
};

BOOL SparkLogSynchronization = NO;

@protocol SparkLibrary

- (bycopy NSString *)uuid;

- (oneway void)addObject:(bycopy id)plist type:(in OSType)type;
- (oneway void)updateObject:(bycopy id)plist type:(in OSType)type;
- (oneway void)removeObject:(in SparkUID)uid type:(in OSType)type;

#pragma mark Entries Management
- (oneway void)addLibraryEntry:(in SparkLibraryEntry *)anEntry;
- (oneway void)removeLibraryEntry:(in SparkLibraryEntry *)anEntry;
- (oneway void)replaceLibraryEntry:(in SparkLibraryEntry *)anEntry withLibraryEntry:(in SparkLibraryEntry *)newEntry;

- (oneway void)enableLibraryEntry:(in SparkLibraryEntry *)anEntry;
- (oneway void)disableLibraryEntry:(in SparkLibraryEntry *)anEntry;

#pragma mark Plugins Management
- (oneway void)enablePlugIn:(bycopy NSString *)plugin;
- (oneway void)disablePlugIn:(bycopy NSString *)plugin;

- (oneway void)registerPlugIn:(bycopy NSString *)bundlePath;

#pragma mark Preferences
- (oneway void)setPreferenceValue:(bycopy id)value forKey:(bycopy NSString *)key;

@end

#pragma mark -
@implementation SparkLibrarySynchronizer

- (id)init {
  Class cls = [self class];
  [self release];
  [NSException raise:NSInvalidArgumentException format:@"%@ does not recognized selector %@", NSStringFromClass(cls), NSStringFromSelector(_cmd)];
  return nil;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  NSParameterAssert(aLibrary != nil);
  if (self = [super init]) {
    sp_library = [aLibrary retain];
  }
  return self;
}

- (void)dealloc {
  [self setDistantLibrary:nil];
  [sp_library release];
  [super dealloc];
}

#pragma mark -
- (void)registerObserver {
  NSNotificationCenter *center = [sp_library notificationCenter];
  
  [center addObserver:self
             selector:@selector(didAddObject:)
                 name:SparkObjectSetDidAddObjectNotification 
               object:nil];
  [center addObserver:self
             selector:@selector(didUpdateObject:)
                 name:SparkObjectSetDidUpdateObjectNotification 
               object:nil];
  [center addObserver:self
             selector:@selector(willRemoveObject:)
                 name:SparkObjectSetWillRemoveObjectNotification 
               object:nil];
  
  /* Entry Manager */
  [center addObserver:self
             selector:@selector(didAddEntry:)
                 name:SparkEntryManagerDidAddEntryNotification 
               object:nil];
  [center addObserver:self
             selector:@selector(didUpdateEntry:)
                 name:SparkEntryManagerDidUpdateEntryNotification 
               object:nil];
  [center addObserver:self
             selector:@selector(willRemoveEntry:)
                 name:SparkEntryManagerWillRemoveEntryNotification 
               object:nil];
  [center addObserver:self
             selector:@selector(didChangeEntryStatus:)
                 name:SparkEntryManagerDidChangeEntryEnabledNotification 
               object:nil];

  /* Preferences */
  [center addObserver:self
             selector:@selector(didSetPreference:)
                 name:SparkLibraryDidSetPreferenceNotification
               object:nil];
  
  /* Plugins */
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePluginStatus:)
                                               name:SparkPlugInDidChangeStatusNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didRegisterPlugIn:)
                                               name:SparkActionLoaderDidRegisterPlugInNotification
                                             object:nil];
}
- (void)removeObserver {
  [[sp_library notificationCenter] removeObserver:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSDistantObject<SparkLibrary> *)distantLibrary {
  return sp_remote;
}
- (BOOL)isConnected {
  return sp_remote && [[sp_remote connectionForProxy] isValid];
}

- (void)setDistantLibrary:(NSDistantObject<SparkLibrary> *)remoteLibrary {
  if (remoteLibrary && ![remoteLibrary conformsToProtocol:@protocol(SparkLibrary)]) {
    [NSException raise:NSInvalidArgumentException format:@"Remote Library %@ MUST conform to <SparkLibrary>", remoteLibrary];
  }
  
  NSString *uuidstr = nil;
  if (remoteLibrary != sp_remote) {
    /* If set null => unregister */
    if (!remoteLibrary) {
      [self removeObserver];
    } else {
      /* Check library UUID */
      uuidstr = [remoteLibrary uuid];
      if (!uuidstr) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid Remote Library UUID (null)"];
      }
      NSAssert([sp_library uuid], @"Invalid Library UUID (null)");
      CFUUIDRef uuid = CFUUIDCreateFromString(kCFAllocatorDefault, (CFStringRef)uuidstr);
      if (!uuid) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid Remote Library UUID %@", uuidstr];
      } else if (!CFEqual(uuid, [sp_library uuid])) {
        CFRelease(uuid);
        [NSException raise:NSInvalidArgumentException format:@"Remote Library UUID does not match: %@", uuidstr];
      }
      CFRelease(uuid);
      
      /* UUID OK, if not already registred => register */
      if (!sp_remote) {
        [self registerObserver];
      }
    }
    /* Swap instance variable */
    [sp_remote release];
    sp_remote = [remoteLibrary retain];
    [sp_remote setProtocolForProxy:@protocol(SparkLibrary)];
    if (SparkLogSynchronization) {
      NSLog(@"Set Remote library: %@", uuidstr);
    }
  }
    
}

#pragma mark -
#pragma mark Spark Library Synchronization

#define SparkRemoteMessage(msg)		({ @try { \
  [[self distantLibrary] msg]; \
  if (SparkLogSynchronization) { \
    NSLog(@"Send remote message: -[SparkLibrary %s]", #msg); \
  } \
} @catch (id exception) { \
  SKLogException(exception); \
  if (SparkLogSynchronization) { \
    NSLog(@"Remote message exception: %@", exception); \
  } \
} })

SK_INLINE
OSType SparkServerObjectType(SparkObject *anObject) {
  if ([anObject isKindOfClass:[SparkAction class]])
    return kSparkActionType;
  if ([anObject isKindOfClass:[SparkTrigger class]])
    return kSparkTriggerType;
  if ([anObject isKindOfClass:[SparkApplication class]])
    return kSparkApplicationType;
  return 0;
}

- (void)didAddObject:(NSNotification *)aNotification {
  if ([self isConnected]) {
    OSType type;
    SparkObject *object = SparkNotificationObject(aNotification);
    if (object && (type = SparkServerObjectType(object))) {
      NSDictionary *plist = [[aNotification object] serialize:object error:NULL];
      if (plist) {
        SparkRemoteMessage(addObject:plist type:type);
      } else {
        if (SparkLogSynchronization) {
          NSLog(@"Failed to serialized object: %@", object);
        }
      }
    }
  }
}

- (void)didUpdateObject:(NSNotification *)aNotification {
  if ([self isConnected]) {
    OSType type;
    SparkObject *object = SparkNotificationObject(aNotification);
    if (object && (type = SparkServerObjectType(object))) {
      NSDictionary *plist = [[aNotification object] serialize:object error:NULL];
      if (plist) {
        SparkRemoteMessage(updateObject:plist type:type);
      }
    }
  }
}

- (void)willRemoveObject:(NSNotification *)aNotification {
  if ([self isConnected]) {
    OSType type;
    SparkObject *object = SparkNotificationObject(aNotification);
    if (object && (type = SparkServerObjectType(object))) {
      SparkRemoteMessage(removeObject:[object uid] type:type);
    }
  }
}

#pragma mark Entries
- (void)didAddEntry:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkEntry *entry = SparkNotificationObject(aNotification);
    if (entry) {
      SparkLibraryEntry *lentry = [[aNotification object] libraryEntryForEntry:entry];
      if (lentry) {
        SparkRemoteMessage(addLibraryEntry:lentry);
      }
    }
  }
}
- (void)didUpdateEntry:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkEntry *entry = SparkNotificationObject(aNotification);
    SparkEntry *previous = SparkNotificationUpdatedObject(aNotification);
    
    if (entry && previous) {
      SparkLibraryEntry *lentry = [[aNotification object] libraryEntryForEntry:entry];
      if (lentry) {
        SparkLibraryEntry lprevious;
        lprevious.flags = [previous isEnabled] ? kSparkEntryEnabled : 0;
        lprevious.action = [[previous action] uid];
        lprevious.trigger = [[previous trigger] uid];
        lprevious.application = [[previous application] uid];
        SparkRemoteMessage(replaceLibraryEntry:&lprevious withLibraryEntry:lentry);
      }
    }
  }
}
- (void)willRemoveEntry:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkEntry *entry = SparkNotificationObject(aNotification);
    if (entry) {
      SparkLibraryEntry *lentry = [[aNotification object] libraryEntryForEntry:entry];
      if (lentry) {
        SparkRemoteMessage(removeLibraryEntry:lentry);
      }
    }
  }
}

- (void)didChangeEntryStatus:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkEntry *entry = SparkNotificationObject(aNotification);
    if (entry) {
      SparkLibraryEntry *lentry = [[aNotification object] libraryEntryForEntry:entry];
      if (lentry) {
        if ([entry isEnabled])
          SparkRemoteMessage(enableLibraryEntry:lentry);
        else
          SparkRemoteMessage(disableLibraryEntry:lentry);
      }
    }
  }
}

- (void)didSetPreference:(NSNotification *)aNotification {
  if ([self isConnected]) {
    NSString *key = [[aNotification userInfo] objectForKey:SparkNotificationPreferenceNameKey];
    id value = [[aNotification userInfo] objectForKey:SparkNotificationPreferenceValueKey];
    SparkRemoteMessage(setPreferenceValue:value forKey:key);
  }
}

#pragma mark Plugins Synchronization
- (void)didRegisterPlugIn:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkPlugIn *plugin = [aNotification object];
    SparkRemoteMessage(registerPlugIn:[plugin path]);
  }
}

- (void)didChangePluginStatus:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkPlugIn *plugin = [aNotification object];
    if ([plugin isEnabled])
      SparkRemoteMessage(enablePlugIn:[plugin identifier]);
    else
      SparkRemoteMessage(disablePlugIn:[plugin identifier]);
  }
}

@end

#pragma mark -
@interface SparkDistantLibrary (SparkLibraryProtocol) <SparkLibrary>

@end

@implementation SparkDistantLibrary

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  if (self = [super init]) {
    sp_library = [aLibrary retain];
  }
  return self;
}

- (void)dealloc {
  [sp_library release];
  [super dealloc];
}

- (SparkLibrary *)library {
  return sp_library;
}
- (id<SparkLibrary>)distantLibrary {
  NSProtocolChecker *checker = [[NSProtocolChecker alloc] initWithTarget:self
                                                                protocol:@protocol(SparkLibrary)];
  return (id<SparkLibrary>)[checker autorelease];
}

- (id)delegate {
  return sp_delegate;
}
- (void)setDelegate:(id)delegate {
  sp_delegate = delegate;
}

@end

#pragma mark -
@implementation SparkLibrary (SparkDistantLibrary)

- (SparkDistantLibrary *)distantLibrary {
  SparkDistantLibrary *library = [[SparkDistantLibrary alloc] initWithLibrary:self];
  return [library autorelease];
}

@end

#pragma mark -
#pragma mark Protocol
SK_INLINE
SparkObjectSet *SparkObjectSetForType(SparkLibrary *library, OSType type) {
  switch (type) {
    case kSparkActionType:
      return [library actionSet];
    case kSparkTriggerType:
      return [library triggerSet];
    case kSparkApplicationType:
      return [library applicationSet];
  }
  return nil;
}

#define SparkSyncTrace() ({if (SparkLogSynchronization) { NSLog(@"-[SparkDistantLibrary %@]", NSStringFromSelector(_cmd)); }})

@implementation SparkDistantLibrary (SparkLibraryProtocol)

- (NSString *)uuid {
  SparkSyncTrace();
  NSString *uuidstr = nil;
  CFUUIDRef uuid = [sp_library uuid];
  if (uuid) {
    uuidstr = (id)CFUUIDCreateString(kCFAllocatorDefault, uuid);
  }
  return [uuidstr autorelease];
}

#pragma mark Objects Management
- (void)addObject:(id)plist type:(OSType)type {
  SparkSyncTrace();
  SparkObjectSet *set = SparkObjectSetForType(sp_library, type);
  if (set) {
    SparkObject *object = [set deserialize:plist error:nil];
    if (object) {
      /* Trigger configuration is handled in notification */
      [set addObject:object];
    }
  }
}
- (void)updateObject:(id)plist type:(OSType)type {
  SparkSyncTrace();
  SparkObjectSet *set = SparkObjectSetForType(sp_library, type);
  if (set) {
    SparkObject *object = [set deserialize:plist error:nil];
    if (object) {
      /* Trigger state and configuration is handled in notification */
      [set updateObject:object];
    }
  }
}
- (void)removeObject:(SparkUID)uid type:(OSType)type {
  SparkSyncTrace();
  SparkObjectSet *set = SparkObjectSetForType(sp_library, type);
  if (set) {
    /* Trigger desactivation is handled in notification */
    [set removeObjectWithUID:uid];
  }
}

#pragma mark Entries Management
- (void)addLibraryEntry:(SparkLibraryEntry *)anEntry {
  SparkSyncTrace();
  [[sp_library entryManager] addLibraryEntry:anEntry];
  if (SKDelegateHandle(sp_delegate, distantLibrary:didAddEntry:)) {
    SparkEntry *entry = [[sp_library entryManager] entryForLibraryEntry:anEntry];
    if (entry)
      [sp_delegate distantLibrary:self didAddEntry:entry];
  }
}

- (void)removeLibraryEntry:(SparkLibraryEntry *)anEntry {
  SparkSyncTrace();
  SparkEntry *entry = nil;
  if (SKDelegateHandle(sp_delegate, distantLibrary:didRemoveEntry:)) {
    entry = [[sp_library entryManager] entryForLibraryEntry:anEntry];
  }
  [[sp_library entryManager] removeLibraryEntry:anEntry];
  if (entry) {
    [sp_delegate distantLibrary:self didRemoveEntry:entry];
  }
}

- (void)replaceLibraryEntry:(SparkLibraryEntry *)anEntry withLibraryEntry:(SparkLibraryEntry *)newEntry {
  SparkSyncTrace();
  SparkEntry *old = nil, *new = nil;
  if (SKDelegateHandle(sp_delegate, distantLibrary:didReplaceEntry:withEntry:)) {
    old = [[sp_library entryManager] entryForLibraryEntry:anEntry];
  }
  [[sp_library entryManager] replaceLibraryEntry:anEntry withLibraryEntry:newEntry];
  if (old) {
    new = [[sp_library entryManager] entryForLibraryEntry:newEntry];
    if (new)
      [sp_delegate distantLibrary:self didReplaceEntry:old withEntry:new];
  }
}

- (void)enableLibraryEntry:(SparkLibraryEntry *)anEntry {
  SparkSyncTrace();
  [[sp_library entryManager] setEnabled:YES forLibraryEntry:anEntry];
  if (SKDelegateHandle(sp_delegate, distantLibrary:didChangeEntryStatus:)) {
    SparkEntry *entry = [[sp_library entryManager] entryForLibraryEntry:anEntry];
    if (entry)
      [sp_delegate distantLibrary:self didChangeEntryStatus:entry];
  }
}

- (void)disableLibraryEntry:(SparkLibraryEntry *)anEntry {
  SparkSyncTrace();
  [[sp_library entryManager] setEnabled:NO forLibraryEntry:anEntry];
  if (SKDelegateHandle(sp_delegate, distantLibrary:didChangeEntryStatus:)) {
    SparkEntry *entry = [[sp_library entryManager] entryForLibraryEntry:anEntry];
    if (entry)
      [sp_delegate distantLibrary:self didChangeEntryStatus:entry];
  }
}

- (void)setPreferenceValue:(id)value forKey:(NSString *)key {
  SparkSyncTrace();
  [sp_library setPreferenceValue:value forKey:key];
}

#pragma mark Plugins Management
- (void)enablePlugIn:(NSString *)identifier {
  SparkSyncTrace();
  SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] pluginForIdentifier:identifier];
  if (plugin) {
    [plugin setEnabled:YES];
  } else {
    DLog(@"Cannot find plugin: %@", identifier);
  }
}
- (void)disablePlugIn:(NSString *)identifier {
  SparkSyncTrace();
  SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] pluginForIdentifier:identifier];
  if (plugin) {
    [plugin setEnabled:NO];
  } else {
    DLog(@"Cannot find plugin: %@", identifier);
  }
}

- (void)registerPlugIn:(NSString *)path {
  SparkSyncTrace();
  SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] loadPlugin:path];
  if (!plugin) {
    DLog(@"Error while loading plugin: %@", path);
  }
}

@end
