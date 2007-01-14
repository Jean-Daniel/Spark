/*
 *  ServerController.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "SEServerConnection.h"
#import "SDVersion.h"

#import "SEPreferences.h"
#import "SEScriptHandler.h"

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkLibrarySynchronizer.h>

#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKProcessFunctions.h>

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
    se_sync = [[SparkLibrarySynchronizer alloc] initWithLibrary:SparkActiveLibrary()];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [se_server release];
  [se_sync release];
  [super dealloc];
}

- (void)serverDidClose {
  if (se_server) {
    [se_sync setDistantLibrary:nil];
    [se_server release];
    se_server = nil;
  }
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
    [self serverDidClose];
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

/* MUST be called after connection */
- (void)configure {
  [se_sync setDistantLibrary:(NSDistantObject *)[se_server library]];
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
    [self serverDidClose];
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
      if ([self connect])
        [self configure];
      break;
    case kSparkDaemonStopped:
      if (se_server) {
        DLog(@"Server shutdown");
        [[se_server connectionForProxy] invalidate];
        [self serverDidClose];
        break;
      }
    default:
      break;
  }
}

@end

NSString * const kSparkDaemonExecutableName = @"Spark Daemon.app";

NSString *SESparkDaemonPath() {
#if defined(DEBUG)
  return kSparkDaemonExecutableName;
#else
  return [[NSBundle mainBundle] pathForAuxiliaryExecutable:kSparkDaemonExecutableName];
#endif
}

BOOL SELaunchSparkDaemon() {
  [SEPreferences synchronize];
  [SparkActiveLibrary() synchronize];
  NSString *path = SESparkDaemonPath();
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
    NSString *path = SESparkDaemonPath();
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
  
  SEServerConnection *connection = [SEServerConnection defaultConnection];
  if ([connection connect]) {
    int sversion = [connection version];
    if (sversion >= 0 && sversion < kSparkServerVersion) {
      DLog(@"Daemon older than expected. Restart it");
      [connection restart];
    } else {
      @try {
        [connection configure];
        [NSApp setServerStatus:kSparkDaemonStarted];
      } @catch (id exception) {
        DLog(@"Error while getting remote library. Try to restart daemon to resync");
        [connection restart];
      }
    }
  } else {
    [NSApp setServerStatus:kSparkDaemonStopped];
  }
}
