/*
 *  SparkLibrarySynchronizer.m
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkLibrarySynchronizer.h>

#import <SparkKit/SparkPreferences.h>

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkActionLoader.h>

#import "SparkEntryPrivate.h"
#import "SparkLibraryPrivate.h"
#import "SparkEntryManagerPrivate.h"

typedef NS_ENUM(OSType, SparkObjectType) {
  kSparkActionType      = 'acti',
  kSparkTriggerType     = 'trig',
  kSparkApplicationType = 'appl'
};

bool SparkLogSynchronization = false;

@protocol SparkLibrary

- (void)addObject:(NSDictionary *)plist type:(SparkObjectType)type;
- (void)removeObject:(SparkUID)uid type:(SparkObjectType)type;

#pragma mark Entries Management
- (void)addEntry:(SparkEntry *)anEntry parent:(SparkUID)parent;
- (void)updateEntry:(SparkEntry *)newEntry;
- (void)removeEntry:(SparkUID)anEntry;

- (void)enableEntry:(SparkUID)anEntry;
- (void)disableEntry:(SparkUID)anEntry;

#pragma mark Application Specific
- (void)enableApplication:(SparkUID)uid;
- (void)disableApplication:(SparkUID)uid;

#pragma mark PlugIns Management
- (void)registerPlugIn:(NSURL *)bundlePath;

- (void)setObject:(__nullable id)object forKey:(NSString *)key;

@end

#pragma mark -
@implementation SparkLibrarySynchronizer {
@private
  SparkLibrary *_library;
  id<SparkLibrary> _remote;
  void(^_observer)(NSString *, id);
}

+ (NSXPCInterface *)sparkLibraryInterface {
  return [NSXPCInterface interfaceWithProtocol:@protocol(SparkLibrary)];
}

- (id)init {
  Class cls = [self class];
	SPXThrowException(NSInvalidArgumentException, @"%@ does not recognized selector %@", NSStringFromClass(cls), NSStringFromSelector(_cmd));
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  NSParameterAssert(aLibrary != nil);
  if (self = [super init]) {
    _library = aLibrary;
  }
  return self;
}

- (void)dealloc {
  [self setDistantLibrary:nil uuid:nil];
}

#pragma mark -
- (void)registerObserver {
  NSNotificationCenter *center = _library.notificationCenter;
  
  [center addObserver:self
             selector:@selector(didAddObject:)
                 name:SparkObjectSetDidAddObjectNotification 
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
             selector:@selector(didRemoveEntry:)
                 name:SparkEntryManagerDidRemoveEntryNotification 
               object:nil];
  [center addObserver:self
             selector:@selector(didChangeEntryStatus:)
                 name:SparkEntryManagerDidChangeEntryStatusNotification 
               object:nil];

  /* Applications */
  [center addObserver:self
             selector:@selector(didChangeApplicationStatus:)
                 name:SparkApplicationDidChangeEnabledNotification 
               object:nil];

  _observer = ^(NSString *key, __nullable id value) {
    [self setObject:value forKey:key];
  };
  [[_library preferences] registerObserver:_observer forKey:nil];

  /* PlugIns */
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didRegisterPlugIn:)
                                               name:SparkActionLoaderDidRegisterPlugInNotification
                                             object:nil];
}
- (void)removeObserver {
  if (_observer != nil) {
    [_library.preferences unregisterObserver:_observer forKey:nil];
    _observer = nil;
  }

  [_library.notificationCenter removeObserver:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id<SparkLibrary>)distantLibrary {
  return _remote;
}
- (BOOL)isConnected {
  return _remote != nil;
}

- (void)setDistantLibrary:(id<SparkLibrary>)remoteLibrary uuid:(NSUUID *)uuid {
  if (remoteLibrary != _remote) {
    /* If set null => unregister */
    if (!remoteLibrary) {
      [self removeObserver];
    } else {
      /* Check library UUID */
      NSAssert(_library.uuid, @"Invalid Library UUID (null)");
      if (!uuid) {
        SPXThrowException(NSInvalidArgumentException, @"Invalid Remote Library UUID (nil)");
      } else if (![uuid isEqual:_library.uuid]) {
        SPXThrowException(NSInvalidArgumentException, @"Remote Library UUID does not match active library: %@", uuid);
      }
      
      /* UUID OK, if not already registred => register */
      if (!_remote)
        [self registerObserver];
    }
    /* Swap instance variable */
    _remote = remoteLibrary;
    if (SparkLogSynchronization)
      spx_debug("Set Remote library: %@", uuid);
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
  spx_log_exception(exception); \
  if (SparkLogSynchronization) { \
    NSLog(@"Remote message exception: %@", exception); \
  } \
} })

WB_INLINE
SparkObjectType SparkServerObjectType(SparkObject *anObject) {
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
    SparkObjectType type;
    SparkObject *object = SparkNotificationObject(aNotification);
    if (object && (type = SparkServerObjectType(object))) {
      NSDictionary *plist = [aNotification.object serialize:object error:NULL];
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

- (void)willRemoveObject:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkObjectType type;
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
      SparkRemoteMessage(addEntry:entry parent:[[entry parent] uid]);
    }
  }
}
- (void)didUpdateEntry:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkEntry *entry = SparkNotificationObject(aNotification);
    if (entry) {
      SparkRemoteMessage(updateEntry:entry);
    }
  }
}
- (void)didRemoveEntry:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkEntry *entry = SparkNotificationObject(aNotification);
    if (entry) {
      SparkRemoteMessage(removeEntry:[entry uid]);
    }
  }
}

- (void)didChangeEntryStatus:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkEntry *entry = SparkNotificationObject(aNotification);
    if (entry) {
      if ([entry isEnabled]) {
        SparkRemoteMessage(enableEntry:[entry uid]);
      } else {
        SparkRemoteMessage(disableEntry:[entry uid]);
      }
    }
  }
}

#pragma mark Applications
- (void)didChangeApplicationStatus:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkApplication *app = [aNotification object];
    if (app) {
      if ([app isEnabled])
        SparkRemoteMessage(enableApplication:[app uid]);
      else
        SparkRemoteMessage(disableApplication:[app uid]);
    }
  }
}

#pragma mark PlugIns Synchronization
- (void)didRegisterPlugIn:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkPlugIn *plugin = [aNotification object];
    SparkRemoteMessage(registerPlugIn:plugin.URL);
  }
}

- (void)setObject:(__nullable id)value forKey:(NSString *)key {
  if ([self isConnected]) {
    SparkRemoteMessage(setObject:value forKey:key);
  }
}

@end

#pragma mark -
@interface SparkDistantLibrary (SparkLibraryProtocol) <SparkLibrary>

@end

@implementation SparkDistantLibrary

- (id)initWithLibrary:(SparkLibrary *)aLibrary {
  if (self = [super init]) {
    _library = aLibrary;
  }
  return self;
}

@end

#pragma mark -
@implementation SparkLibrary (SparkDistantLibrary)

- (id<SparkLibrary>)libraryProxy {
  return [[SparkDistantLibrary alloc] initWithLibrary:self];
}

@end

#pragma mark -
#pragma mark Protocol
WB_INLINE
SparkObjectSet *SparkObjectSetForType(SparkLibrary *library, SparkObjectType type) {
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
  return [_library.uuid UUIDString];
}

#pragma mark Objects Management
- (void)addObject:(id)plist type:(SparkObjectType)type {
  SparkSyncTrace();
  SparkObjectSet *set = SparkObjectSetForType(_library, type);
  if (set) {
    SparkObject *object = [set deserialize:plist error:nil];
    if (object) {
      /* Trigger configuration is handled in notification */
      [set addObject:object];
    }
  }
}
- (void)removeObject:(SparkUID)uid type:(SparkObjectType)type {
  SparkSyncTrace();
  SparkObjectSet *set = SparkObjectSetForType(_library, type);
  if (set) {
    /* Trigger desactivation is handled in notification */
    [set removeObjectWithUID:uid];
  }
}

#pragma mark Entries Management
- (void)addEntry:(SparkEntry *)anEntry parent:(SparkUID)aParent {
  SparkSyncTrace();
	SparkEntry *parent = aParent ? [_library.entryManager entryWithUID:aParent] : nil;
  [_library.entryManager addEntry:anEntry parent:parent];
}

- (void)updateEntry:(SparkEntry *)newEntry {
  SparkSyncTrace();
	SparkEntry *original = [_library.entryManager entryWithUID:[newEntry uid]];
	NSAssert(original, @"invalid request. enrty with UID not found.");
	[original beginEditing];
	[original replaceAction:[newEntry action]];
	[original replaceTrigger:[newEntry trigger]];
	[original replaceApplication:[newEntry application]];
	[original endEditing];
}

- (void)removeEntry:(SparkUID)anEntry {
  SparkSyncTrace();
  SparkEntry *entry = [_library.entryManager entryWithUID:anEntry];
  if (entry)
    [_library.entryManager removeEntry:entry];
}

- (void)enableEntry:(SparkUID)anEntry {
  SparkSyncTrace();
  SparkEntry *entry = [_library.entryManager entryWithUID:anEntry];
  if (entry)
    [entry setEnabled:YES];
}

- (void)disableEntry:(SparkUID)anEntry {
  SparkSyncTrace();
  SparkEntry *entry = [_library.entryManager entryWithUID:anEntry];
  if (entry)
    [entry setEnabled:NO];
}

#pragma mark Applications Specific
- (void)enableApplication:(SparkUID)uid {
  SparkSyncTrace();
  SparkApplication *app = [_library applicationWithUID:uid];
  [app setEnabled:YES];
}
- (void)disableApplication:(SparkUID)uid {
  SparkSyncTrace();
  SparkApplication *app = [_library applicationWithUID:uid];
  [app setEnabled:NO];
}

#pragma mark PlugIns Management
- (void)registerPlugIn:(NSURL *)anURL {
  SparkSyncTrace();
  SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] loadPlugInAtURL:anURL];
  if (!plugin) {
    spx_debug("Error while loading plugin: %@", anURL);
  }
}

- (void)setObject:(__nullable id)object forKey:(NSString *)key {
  [_library.preferences setObject:object forKey:key];
}

@end
