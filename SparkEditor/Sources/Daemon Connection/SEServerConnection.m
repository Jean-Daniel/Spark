/*
 *  ServerController.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEServerConnection.h"
#import "SDVersion.h"

#import "SEPreferences.h"

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkAppleScriptSuite.h>
#import <SparkKit/SparkLibrarySynchronizer.h>

#import WBHEADER(WBAEFunctions.h)
#import WBHEADER(WBFSFunctions.h)
#import WBHEADER(WBLSFunctions.h)
#import WBHEADER(WBProcessFunctions.h)

NSString * const SEServerStatusDidChangeNotification = @"SEServerStatusDidChange";

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
    
    center = [NSDistributedNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(serverStatusDidChange:)
                   name:(id)SparkDaemonStatusDidChangeNotification
                 object:kSparkConnectionName];
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
    [se_sync release];
    se_sync = nil;
    
    [se_server release];
    se_server = nil;
  }
}
#pragma mark -
- (UInt32)version {
  if ([self isConnected]) {
    if ([[self server] respondsToSelector:@selector(version)]) {
      @try {
        return [[self server] version];
      } @catch (id exception) {
        WBLogException(exception);
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
    @try {
      if ([[self server] respondsToSelector:@selector(shutdown)]) {
        [[self server] shutdown];
        return;
      }
    } @catch (id exception) {
      WBLogException(exception);
    }
    ProcessSerialNumber psn = WBProcessGetProcessWithSignature(kSparkDaemonSignature);
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
    NSConnection *cnt = [NSConnection connectionWithRegisteredName:kSparkConnectionName host:nil];
    if (!cnt)
      cnt = [NSConnection connectionWithRegisteredName:@"SparkServer" host:nil];
    
    if (cnt) {
      [cnt setReplyTimeout:5];
      se_server = [cnt rootProxy];
    }
    
    if (se_server) {
      [se_server retain];
      [se_server setProtocolForProxy:@protocol(SparkServer)];
      DLog(@"Server Connection OK");
    } else {
      DLog(@"Server Connection down");
    }
  } @catch (id exception) {
    WBLogException(exception);
    if ([NSPortTimeoutException isEqualToString:[exception name]]) {
      /* timeout, the daemon is probably in a dead state => restart it */
      ProcessSerialNumber psn = WBProcessGetProcessWithSignature(kSparkDaemonSignature);
      if (psn.lowLongOfPSN != kNoProcess) {
        KillProcess(&psn);
        SELaunchSparkDaemon(&psn);
      }
    }
  }
  return se_server != nil;
}

- (void)disconnect {
  if ([self isConnected]) {
    [[se_server connectionForProxy] invalidate];
  }
}

/* MUST be called after connection */
- (void)configure {
  if (!se_sync)
    se_sync = [[SparkLibrarySynchronizer alloc] initWithLibrary:SparkActiveLibrary()];
  
  [se_sync setDistantLibrary:(NSDistantObject *)[se_server library]];
}

- (BOOL)isConnected {
  return se_server && [[se_server connectionForProxy] isValid];
}

- (SparkDaemonStatus)status {
  return se_status;
}
- (void)setStatus:(SparkDaemonStatus)status {
  if (se_status != status) {
    se_status = status;
    [[NSNotificationCenter defaultCenter] postNotificationName:SEServerStatusDidChangeNotification
                                                        object:self];
  }
}

- (BOOL)isRunning {
  return se_status == kSparkDaemonStatusEnabled || se_status == kSparkDaemonStatusDisabled;
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
      SELaunchSparkDaemon(NULL);
    } else {
      [self setStatus:kSparkDaemonStatusShutDown];
    }
  }
}

- (void)serverStatusDidChange:(NSNotification *)aNotification {
  SparkDaemonStatus status = SparkDaemonGetStatus(aNotification);
  switch (status) {
    case kSparkDaemonStatusEnabled:
    case kSparkDaemonStatusDisabled:
      if (![self isConnected] && [self connect]) {
        [self configure];
        [self setStatus:status];
      } else if ([self isConnected]) {
        [self setStatus:status];
      }
      break;
    case kSparkDaemonStatusError:
      DLog(@"Daemon error");
      status = kSparkDaemonStatusShutDown;
      // Fall throught
    case kSparkDaemonStatusShutDown:
      if (se_server) {
        DLog(@"Server shutdown");
        [[se_server connectionForProxy] invalidate];
        [self serverDidClose];
      }
      [self setStatus:status];
      break;
    default:
      break;
  }
}

@end

NSString * const kSparkDaemonExecutableName = @"Spark Daemon.app";

NSString *SESparkDaemonPath(void) {
#if defined(DEBUG)
  return kSparkDaemonExecutableName;
#else
  return [[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:kSparkDaemonExecutableName];
#endif
}

BOOL SELaunchSparkDaemon(ProcessSerialNumber *psn) {
  [SEPreferences synchronize];
  [SparkActiveLibrary() synchronize];
  NSString *path = SESparkDaemonPath();
  if (path) {
    if (noErr != WBLSLaunchApplicationAtPath((CFStringRef)path, kCFURLPOSIXPathStyle, kLSLaunchDefaults | kLSLaunchDontSwitch | kLSLaunchDontAddToRecents, psn)) {
      DLog(@"Error cannot launch daemon app");
      [[SEServerConnection defaultConnection] setStatus:kSparkDaemonStatusError];
      return NO;
    }
  }  
  return YES;
}

void SEServerStartConnection(void) {
  /* Verify daemon validity */
  ProcessSerialNumber psn = WBProcessGetProcessWithSignature(kSparkDaemonSignature);
  if (psn.lowLongOfPSN != kNoProcess) {
    FSRef dRef;
    NSString *path = SESparkDaemonPath();
    if (path && [path getFSRef:&dRef]) {
      FSRef location;
      if (noErr == GetProcessBundleLocation(&psn, &location) && noErr != FSCompareFSRefs(&location, &dRef)) {
        DLog(@"Should Kill Running daemon.");
#if !defined (DEBUG)
        KillProcess(&psn);
        SELaunchSparkDaemon(&psn);
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
        if (SEDaemonIsEnabled()) {
          [connection setStatus:kSparkDaemonStatusEnabled];
        } else {
          [connection setStatus:kSparkDaemonStatusDisabled];
        }
      } @catch (id exception) {
        WBCLogException(exception);
        DLog(@"Out of sync remote library. Automatically resyncs library and restarts daemon.");
        [connection restart];
      }
    }
  } else {
    [connection setStatus:kSparkDaemonStatusShutDown];
  }
}

void SEServerStopConnection(void) {
  SEServerConnection *connection = [SEServerConnection defaultConnection];
  if ([connection isConnected]) {
    [connection disconnect];
  }
}

BOOL SEDaemonIsEnabled(void) {
  ProcessSerialNumber psn = WBProcessGetProcessWithSignature(kSparkDaemonSignature);
  if (psn.lowLongOfPSN != kNoProcess) {
    Boolean result = false;
    AppleEvent aevt = WBAEEmptyDesc();
    OSStatus err = WBAECreateEventWithTargetProcess(&psn, kAECoreSuite, kAEGetData, &aevt);
    require_noerr(err, bail);
    
    err = WBAESetStandardAttributes(&aevt);
    require_noerr(err, bail);
    
    err = WBAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, typeBoolean, 'pSta', NULL);
    require_noerr(err, bail);
    
    err = WBAESendEventReturnBoolean(&aevt, &result);
    require_noerr(err, bail);
bail:
      WBAEDisposeDesc(&aevt);
    
    return result;
  }
  return NO;
}

