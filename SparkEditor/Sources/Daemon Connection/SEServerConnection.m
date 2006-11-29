/*
 *  ServerController.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "SEServerConnection.h"
#import "SDVersion.h"

#import "SEScriptHandler.h"

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>

#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKProcessFunctions.h>

#define SparkRemoteMessage(msg)		({ @try { [[self server] msg]; } @catch (id exception) { SKLogException(exception); } })

@implementation SEServerConnection

+ (SEServerConnection *)defaultConnection {
  static SEServerConnection *sConnection = nil;
  if (sConnection)
    return sConnection;
  @synchronized(self) {
    if (!sConnection) {
      sConnection = [[SEServerConnection alloc] init];
    }
  }
  return sConnection;
}

- (id)init {
  if (self = [super init]) {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(connectionDidDie:)
                   name:NSConnectionDidDieNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(serverStatusDidChange:)
                   name:SEServerStatusDidChangeNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(didAddObject:)
                   name:kSparkLibraryDidAddObjectNotification 
                 object:nil];
    [center addObserver:self
               selector:@selector(didUpdateObject:)
                   name:kSparkLibraryDidUpdateObjectNotification 
                 object:nil];
    [center addObserver:self
               selector:@selector(willRemoveObject:)
                   name:kSparkLibraryWillRemoveObjectNotification 
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
               selector:@selector(didChangeStatus:)
                   name:SparkEntryManagerDidChangeEntryEnabledNotification 
                 object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [se_server release];
  [super dealloc];
}
#pragma mark -
- (int)version {
  if ([self isConnected]) {
    if ([[self server] respondsToSelector:@selector(version)]) {
      @try {
        return [[self server] version];
      } @catch (id exception) {
        SKLogException(exception);
      }
    } 
    return 0;
  }
  return -1;
}

- (void)restart {
  if ([self isConnected]) {
    se_scFlags.restart = 1;
    [self shutdown];
  }
}

- (void)shutdown {
  if ([self isConnected]) {
    if ([[self server] respondsToSelector:@selector(shutdown)]) {
      @try {
        [[self server] shutdown];
        return;
      } @catch (id exception) {
        SKLogException(exception);
      }
    }
    ProcessSerialNumber psn = SKProcessGetProcessWithSignature(kSparkDaemonHFSCreatorType);
    if (psn.lowLongOfPSN != kNoProcess)
      KillProcess(&psn);
  }
}

- (BOOL)connect {
  if ([self isConnected])
    return YES;
  
  /* Not connected but server alive */
  if (se_server) {
    DLog(@"Undetected invalid connection");
    [se_server release];
    se_server = nil;
  }
  
  @try {
    se_server = [NSConnection rootProxyForConnectionWithRegisteredName:kSparkConnectionName host:nil];
    if (se_server) {
      [se_server retain];
      [se_server setProtocolForProxy:@protocol(SparkServer)];
      DLog(@"Server Connection OK");
    } else {
      DLog(@"Server Connection down");
    }
  } @catch (id exception) {
    SKLogException(exception);
  }
  return se_server != nil;
}

- (BOOL)isConnected {
  return se_server && [[se_server connectionForProxy] isValid];
}

- (NSDistantObject<SparkServer> *)server {
  return se_server;
}

- (void)connectionDidDie:(NSNotification *)aNotification {
  if (se_server && [aNotification object] == [se_server connectionForProxy]) {
    DLog(@"Connection did close");
    [se_server release];
    se_server = nil;
    if (se_scFlags.restart) {
      se_scFlags.restart = 0;
      SELaunchSparkDaemon();
    } else {
      [NSApp setServerStatus:kSparkDaemonStopped];
    }
  }
}

- (void)serverStatusDidChange:(NSNotification *)aNotification {
  SparkDaemonStatus status = [[aNotification object] serverStatus];
  switch (status) {
    case kSparkDaemonStarted:
      [self connect];
      break;
    case kSparkDaemonStopped:
      if (se_server) {
        DLog(@"Server shutdown");
        [[se_server connectionForProxy] invalidate];
        [se_server release];
        se_server = nil;
        break;
      }
    default:
      break;
  }
}

#pragma mark -
#pragma mark Spark Library Synchronization
SK_INLINE
OSType SEServerObjectType(SparkObject *anObject) {
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
    if (object && (type = SEServerObjectType(object))) {
      NSDictionary *plist = [[aNotification object] serialize:object error:NULL];
      if (plist) {
        SparkRemoteMessage(addObject:plist type:type);
      }
    }
  }
}

- (void)didUpdateObject:(NSNotification *)aNotification {
  if ([self isConnected]) {
    OSType type;
    SparkObject *object = SparkNotificationObject(aNotification);
    if (object && (type = SEServerObjectType(object))) {
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
    if (object && (type = SEServerObjectType(object))) {
      SparkRemoteMessage(removeObject:[object uid] type:type);
    }
  }
}

/* Entries */
- (void)didAddEntry:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkEntry *entry = [[aNotification userInfo] objectForKey:SparkEntryNotificationKey];
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
    SparkEntry *entry = [[aNotification userInfo] objectForKey:SparkEntryNotificationKey];
    SparkEntry *previous = [[aNotification userInfo] objectForKey:SparkEntryReplacedNotificationKey];
    
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
    SparkEntry *entry = [[aNotification userInfo] objectForKey:SparkEntryNotificationKey];
    if (entry) {
      SparkLibraryEntry *lentry = [[aNotification object] libraryEntryForEntry:entry];
      if (lentry) {
        SparkRemoteMessage(removeLibraryEntry:lentry);
      }
    }
  }
}

- (void)didChangeStatus:(NSNotification *)aNotification {
  if ([self isConnected]) {
    SparkEntry *entry = [[aNotification userInfo] objectForKey:SparkEntryNotificationKey];
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

@end

static 
NSString * const kSparkDaemonExecutableName = @"Spark Daemon.app";

SK_INLINE
NSString *SEServerPath() {
#if defined(DEBUG)
  return kSparkDaemonExecutableName;
#else
  return [[NSBundle mainBundle] pathForAuxiliaryExecutable:kSparkDaemonExecutableName];
#endif
}

BOOL SELaunchSparkDaemon() {
  [SparkSharedLibrary() synchronize];
  NSString *path = SEServerPath();
  if (path) {
    if (noErr != SKLSLaunchApplicationAtPath((CFStringRef)path, kCFURLPOSIXPathStyle, kLSLaunchDefaults | kLSLaunchDontSwitch)) {
      DLog(@"Error cannot launch daemon app");
      [NSApp setServerStatus:kSparkDaemonError];
      return NO;
    }
  }  
  return YES;
}

void SEServerStartConnection() {
  /* Verify daemon validity */
  ProcessSerialNumber psn = SKProcessGetProcessWithSignature(kSparkDaemonHFSCreatorType);
  if (psn.lowLongOfPSN != kNoProcess) {
    FSRef dRef;
    NSString *path = SEServerPath();
    if (path && [path getFSRef:&dRef]) {
      FSRef location;
      if (noErr == GetProcessBundleLocation(&psn, &location) && noErr != FSCompareFSRefs(&location, &dRef)) {
        DLog(@"Should Kill Running daemon.");
#if !defined (DEBUG)
        KillProcess(&psn);
        SELaunchSparkDaemon();
#endif
      }
    }
  }
  
  if ([[SEServerConnection defaultConnection] connect]) {
    int sversion = [[SEServerConnection defaultConnection] version];
    if (sversion >= 0 && sversion < kSparkServerVersion) {
      DLog(@"Daemon older than expected. Restart it");
      [[SEServerConnection defaultConnection] restart];
    } else {
      [NSApp setServerStatus:kSparkDaemonStarted];
    }
  } else {
    [NSApp setServerStatus:kSparkDaemonStopped];
  }
}
