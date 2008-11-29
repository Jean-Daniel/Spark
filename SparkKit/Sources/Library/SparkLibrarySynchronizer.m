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

enum {
  kSparkActionType      = 'acti',
  kSparkTriggerType     = 'trig',
  kSparkApplicationType = 'appl'
};

BOOL SparkLogSynchronization = NO;

@protocol SparkLibrary

- (bycopy NSString *)uuid;

- (oneway void)addObject:(bycopy id)plist type:(in OSType)type;
- (oneway void)removeObject:(in SparkUID)uid type:(in OSType)type;

#pragma mark Entries Management
- (oneway void)addEntry:(bycopy SparkEntry *)anEntry parent:(SparkUID)parent;
- (oneway void)updateEntry:(bycopy SparkEntry *)newEntry;
- (oneway void)removeEntry:(in SparkUID)anEntry;

- (oneway void)enableEntry:(in SparkUID)anEntry;
- (oneway void)disableEntry:(in SparkUID)anEntry;

#pragma mark Application Specific
- (oneway void)enableApplication:(in SparkUID)uid;
- (oneway void)disableApplication:(in SparkUID)uid;

#pragma mark Plugins Management
- (oneway void)registerPlugIn:(bycopy NSString *)bundlePath;

@end

#pragma mark -
@implementation SparkLibrarySynchronizer

- (id)init {
  Class cls = [self class];
  [self release];
	WBThrowException(NSInvalidArgumentException, @"%@ does not recognized selector %@", NSStringFromClass(cls), NSStringFromSelector(_cmd));
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
  
  /* Plugins */
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
    WBThrowException(NSInvalidArgumentException, @"Remote Library %@ MUST conform to <SparkLibrary>", remoteLibrary);
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
        WBThrowException(NSInvalidArgumentException, @"Invalid Remote Library UUID (null)");
      }
      NSAssert([sp_library uuid], @"Invalid Library UUID (null)");
      CFUUIDRef uuid = CFUUIDCreateFromString(kCFAllocatorDefault, (CFStringRef)uuidstr);
      if (!uuid) {
        WBThrowException(NSInvalidArgumentException, @"Invalid Remote Library UUID %@", uuidstr);
      } else if (!CFEqual(uuid, [sp_library uuid])) {
        CFRelease(uuid);
        WBThrowException(NSInvalidArgumentException, @"Remote Library UUID does not match: %@", uuidstr);
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
  WBLogException(exception); \
  if (SparkLogSynchronization) { \
    NSLog(@"Remote message exception: %@", exception); \
  } \
} })

WB_INLINE
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

#pragma mark Plugins Synchronization
- (void)didRegisterPlugIn:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkPlugIn *plugin = [aNotification object];
    SparkRemoteMessage(registerPlugIn:[plugin path]);
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
WB_INLINE
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
- (void)removeObject:(SparkUID)uid type:(OSType)type {
  SparkSyncTrace();
  SparkObjectSet *set = SparkObjectSetForType(sp_library, type);
  if (set) {
    /* Trigger desactivation is handled in notification */
    [set removeObjectWithUID:uid];
  }
}

#pragma mark Entries Management
- (void)addEntry:(SparkEntry *)anEntry parent:(SparkUID)aParent {
  SparkSyncTrace();
	SparkEntry *parent = aParent ? [[sp_library entryManager] entryWithUID:aParent] : nil;
  [[sp_library entryManager] addEntry:anEntry parent:parent];
}

- (void)updateEntry:(SparkEntry *)newEntry {
  SparkSyncTrace();
	SparkEntry *original = [[sp_library entryManager] entryWithUID:[newEntry uid]];
	NSAssert(original, @"invalid request. enrty with UID not found.");
	[original beginEditing];
	[original replaceAction:[newEntry action]];
	[original replaceTrigger:[newEntry trigger]];
	[original replaceApplication:[newEntry application]];
	[original endEditing];
}

- (void)removeEntry:(SparkUID)anEntry {
  SparkSyncTrace();
  SparkEntry *entry = [[sp_library entryManager] entryWithUID:anEntry];
  if (entry)
    [[sp_library entryManager] removeEntry:entry];
}

- (void)enableEntry:(SparkUID)anEntry {
  SparkSyncTrace();
  SparkEntry *entry = [[sp_library entryManager] entryWithUID:anEntry];
  if (entry)
    [entry setEnabled:YES];
}

- (void)disableEntry:(SparkUID)anEntry {
  SparkSyncTrace();
  SparkEntry *entry = [[sp_library entryManager] entryWithUID:anEntry];
  if (entry)
    [entry setEnabled:NO];
}

#pragma mark Applications Specific
- (void)enableApplication:(SparkUID)uid {
  SparkSyncTrace();
  SparkApplication *app = [sp_library applicationWithUID:uid];
  [app setEnabled:YES];
}
- (void)disableApplication:(SparkUID)uid {
  SparkSyncTrace();
  SparkApplication *app = [sp_library applicationWithUID:uid];
  [app setEnabled:NO];
}

#pragma mark Plugins Management
- (void)registerPlugIn:(NSString *)path {
  SparkSyncTrace();
  SparkPlugIn *plugin = [[SparkActionLoader sharedLoader] loadPluginAtPath:path];
  if (!plugin) {
    DLog(@"Error while loading plugin: %@", path);
  }
}

@end
