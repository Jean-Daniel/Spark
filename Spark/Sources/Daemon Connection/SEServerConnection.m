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

#import <WonderBox/WBAEFunctions.h>
#import <WonderBox/WBFSFunctions.h>

NSString * const SEServerStatusDidChangeNotification = @"SEServerStatusDidChange";

SPARK_INLINE
BOOL SEDaemonTerminate(NSRunningApplication *daemon) {
  if (![daemon terminate])
    return [daemon forceTerminate];
  return YES;
}

@implementation SEServerConnection {
@private
  struct _se_scFlags {
    unsigned int fail:1;
    unsigned int restart:1;
    unsigned int reserved:30;
  } se_scFlags;
  SparkDaemonStatus se_status;
  SparkLibrarySynchronizer *se_sync;
  NSDistantObject<SparkServer> *se_server;
}

+ (SEServerConnection *)defaultConnection {
  static SEServerConnection *sConnection = nil;
  if (sConnection)
    return sConnection;
  @synchronized(self) {
    if (!sConnection)
      sConnection = [[SEServerConnection alloc] init];
  }
  return sConnection;
}

- (id)init {
  if (self = [super init]) {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(connectionDidDie:)
                                               name:NSConnectionDidDieNotification
                                             object:nil];
    
    [NSDistributedNotificationCenter.defaultCenter addObserver:self
                                                      selector:@selector(serverStatusDidChange:)
                                                          name:SparkDaemonStatusDidChangeNotification
                                                        object:kSparkConnectionName];
  }
  return self;
}

- (void)dealloc {
  [NSDistributedNotificationCenter.defaultCenter removeObserver:self];
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)serverDidClose {
  if (se_server) {
    [se_sync setDistantLibrary:nil];
    se_sync = nil;
    se_server = nil;
  }
}

#pragma mark -
- (UInt32)version {
  if ([self isConnected]) {
    if ([self.server respondsToSelector:@selector(version)]) {
      @try {
        return [self.server version];
      } @catch (id exception) {
        SPXLogException(exception);
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
      SPXLogException(exception);
    }
    NSArray *daemons = [NSRunningApplication runningApplicationsWithBundleIdentifier:kSparkDaemonBundleIdentifier];
    for (NSRunningApplication *daemon in daemons) {
      if (!daemon.isTerminated)
        if (![daemon terminate])
          [daemon forceTerminate];
    }
  }
}

- (BOOL)connect {
  if ([self isConnected])
    return YES;
  
  /* Not connected but server alive */
  if (se_server) {
    SPXDebug(@"Undetected invalid connection");
    [self serverDidClose];
  }
  
  @try {
    NSConnection *cnt = [NSConnection connectionWithRegisteredName:kSparkConnectionName host:nil];
    if (cnt) {
      cnt.replyTimeout = 5;
      se_server = (id)cnt.rootProxy;
    }
    
    if (se_server) {
      [se_server setProtocolForProxy:@protocol(SparkServer)];
      SPXDebug(@"Server Connection OK");
    } else {
      SPXDebug(@"Server Connection down");
    }
  } @catch (id exception) {
    SPXLogException(exception);
    if ([NSPortTimeoutException isEqualToString:[exception name]]) {
      /* timeout, the daemon is probably in a dead state => restart it */
      for (NSRunningApplication *d in [NSRunningApplication runningApplicationsWithBundleIdentifier:kSparkDaemonBundleIdentifier]) {
        SEDaemonTerminate(d);
      }
      SELaunchSparkDaemon(NULL);
    }
  }
  return se_server != nil;
}

- (void)disconnect {
  if ([self isConnected])
    [[se_server connectionForProxy] invalidate];
}

/* MUST be called after connection */
- (void)configure {
  if (!se_sync)
    se_sync = [[SparkLibrarySynchronizer alloc] initWithLibrary:SparkActiveLibrary()];
  
  [se_sync setDistantLibrary:[se_server library]];
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
  if (se_server && aNotification.object == se_server.connectionForProxy) {
    SPXDebug(@"Connection did close");
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
  SparkDaemonStatus status = aNotification.sparkDaemonStatus;
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
      SPXDebug(@"Daemon error");
      status = kSparkDaemonStatusShutDown;
      // Fall throught
    case kSparkDaemonStatusShutDown:
      if (se_server) {
        SPXDebug(@"Server shutdown");
        [[se_server connectionForProxy] invalidate];
        [self serverDidClose];
      }
      [self setStatus:status];
      break;
  }
}

@end

NSString * const kSparkDaemonExecutableName = @"Spark Daemon.app";

NSURL *SESparkDaemonURL(void) {
#if defined(DEBUG)
  return [NSURL fileURLWithPath:kSparkDaemonExecutableName];
#else
  return [[NSBundle mainBundle] URLForAuxiliaryExecutable:kSparkDaemonExecutableName];
#endif
}

BOOL SELaunchSparkDaemon(pid_t *pid) {
  [SEPreferences synchronize];
  [SparkActiveLibrary() synchronize];
  NSURL *url = SESparkDaemonURL();
  if (url) {
    NSError *error = nil;
    NSDictionary *config = @{ NSWorkspaceLaunchConfigurationArguments: @[ @"-nodelay" ] };
    NSRunningApplication *app = [[NSWorkspace sharedWorkspace] launchApplicationAtURL:url
                                                                              options:NSWorkspaceLaunchDefault | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchWithoutAddingToRecents
                                                                        configuration:config error:&error];
    if (!app) {
      SPXLogError(@"Error cannot launch daemon app: %@", error);
      [[SEServerConnection defaultConnection] setStatus:kSparkDaemonStatusError];
      return NO;
    } else if (pid) {
      *pid = app.processIdentifier;
    }
  }  
  return YES;
}

void SEServerStartConnection(void) {
  /* Verify daemon validity */
  NSURL *selfdaemon = SESparkDaemonURL();
  for (NSRunningApplication *daemon in [NSRunningApplication runningApplicationsWithBundleIdentifier:kSparkDaemonBundleIdentifier]) {
    if (!daemon.terminated && !WBFSCompareURLs(SPXNSToCFURL(selfdaemon), SPXNSToCFURL(daemon.bundleURL))) {
      // The running daemon does not match the embedded one.
      SPXDebug(@"Terminate Running daemon: %@", daemon);
#if !defined (DEBUG)
      SEDaemonTerminate(daemon);
#endif
    }
  }
  
  SEServerConnection *connection = [SEServerConnection defaultConnection];
  if ([connection connect]) {
    int sversion = [connection version];
    if (sversion >= 0 && sversion < kSparkServerVersion) {
      SPXDebug(@"Daemon older than expected. Restart it");
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
        SPXLogException(exception);
        SPXDebug(@"Out of sync remote library. Automatically resyncs library and restarts daemon.");
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
  NSRunningApplication *d = [NSRunningApplication runningApplicationsWithBundleIdentifier:kSparkDaemonBundleIdentifier].firstObject;
  if (d) {
    Boolean result = false;
    AppleEvent aevt = WBAEEmptyDesc();
    OSStatus err = WBAECreateEventWithTargetProcessIdentifier(d.processIdentifier, kAECoreSuite, kAEGetData, &aevt);
    spx_require_noerr(err, bail);
    
//    err = WBAESetStandardAttributes(&aevt);
//    require_noerr(err, bail);
    
    err = WBAEAddPropertyObjectSpecifier(&aevt, keyDirectObject, typeBoolean, 'pSta', NULL);
    spx_require_noerr(err, bail);
    
    err = WBAESendEventReturnBoolean(&aevt, &result);
    spx_require_noerr(err, bail);
bail:
    WBAEDisposeDesc(&aevt);
    
    return result;
  }
  return NO;
}

