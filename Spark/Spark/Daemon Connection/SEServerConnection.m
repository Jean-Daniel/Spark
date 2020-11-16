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

#import <WonderBox/WonderBox.h>

#import <ServiceManagement/ServiceManagement.h>

/* If YES, do not daemon (and don't register it as a login item) */
static
NSString * const kSparkAgentDisabled  = @"SparkDaemonDisabled";

static
NSString * const kSparkDaemonExecutableName = @"Spark Daemon.app";

NSString * const SEServerStatusDidChangeNotification = @"SEServerStatusDidChange";

@interface SEAgentConnection ()
- (void)connect;
@end

static void *runningApplicationsObserver = NULL;

@implementation SEAgentConnection {
@private
  pid_t _pid;
  NSXPCConnection *_connection;
  SparkDaemonStatus se_status;
  SparkLibrarySynchronizer *se_sync;
}

+ (NSURL *)agentURL {
#if defined(DEBUG)
  return [NSURL fileURLWithPath:kSparkDaemonExecutableName];
#else
  return [[NSBundle mainBundle] URLForAuxiliaryExecutable:kSparkDaemonExecutableName];
#endif
}

+ (SEAgentConnection *)defaultConnection {
  static SEAgentConnection *sConnection = nil;
  if (!sConnection) {
    sConnection = [[SEAgentConnection alloc] init];
    // If agent disable and should be enabled -> register it
    if (!SESparkAgentIsEnabled(NULL) &&
        ![NSUserDefaults.standardUserDefaults boolForKey:kSparkAgentDisabled]) {
      SESparkAgentSetEnabled(YES);
    }
  }
  return sConnection;
}

- (id)init {
  if (self = [super init]) {
    se_status = kSparkDaemonStatusStopped;
    // add runningApplication observer
    [NSWorkspace.sharedWorkspace addObserver:self
                                  forKeyPath:@"runningApplications"
                                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                     context:&runningApplicationsObserver];
    
  }
  return self;
}

- (void)dealloc {
  // remove running applications observer
  [NSWorkspace.sharedWorkspace removeObserver:self forKeyPath:@"runningApplications"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (context == &runningApplicationsObserver) {
    assert([keyPath isEqual:@"runningApplications"]);
    for (NSRunningApplication *app in change[NSKeyValueChangeNewKey]) {
      if ([app.bundleIdentifier isEqualToString:kSparkDaemonBundleIdentifier]) {
        if (app.processIdentifier != _pid) {
          _pid = app.processIdentifier;
          // if new daemon pid -> connect

          // TODO: Validate that it matches our current daemon (path and version).
//          NSURL *selfdaemon = SESparkDaemonURL();
//          for (NSRunningApplication *daemon in [NSRunningApplication runningApplicationsWithBundleIdentifier:kSparkDaemonBundleIdentifier]) {
//            if (!daemon.terminated && !WBFSCompareURLs(SPXNSToCFURL(selfdaemon), SPXNSToCFURL(daemon.bundleURL))) {
//              // The running daemon does not match the embedded one.
//              spx_debug("Terminate Running daemon: %@", daemon);
//        #if !defined (DEBUG)
//              SEDaemonTerminate(daemon);
//        #endif
//            }
//          }

          [self connect];
        }
        break;
      }
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

// MARK:  -
- (void)connectionDidClose {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self setLibrary:nil uuid:nil];
    self->_connection = nil;
    [self setStatus:kSparkDaemonStatusStopped];
  });
  // TODO: notify ?
}

- (void)connect {
  if (_connection != nil)
    return;

  _connection = [[NSXPCConnection alloc] initWithMachServiceName:kSparkDaemonServiceName options:0];

  _connection.remoteObjectInterface = SparkAgentInterface();

  _connection.invalidationHandler = ^{
    NSLog(@"invalidation");
    [self connectionDidClose];
  };
  _connection.interruptionHandler = ^{
    NSLog(@"interruption");
    [self connectionDidClose];
  };
  [_connection resume];
  [(id<SparkAgent>)[_connection remoteObjectProxy] register:self];
}

- (void)disconnect {
  [_connection invalidate];
  _connection = nil;
}

- (void)restart {
  pid_t pid = 0;
  if (SESparkAgentIsEnabled(&pid)) {
    NSRunningApplication *agent = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
    // terminate the agent and let launchd restart it.
    if ([agent.bundleIdentifier isEqualToString:kSparkDaemonBundleIdentifier]) {
      if (![agent terminate])
        [agent forceTerminate];
    }
  }
}

// MARK: SparkEditor Protocol
- (void)setDaemonEnabled:(BOOL)isEnabled {
  [self setStatus:isEnabled ? kSparkDaemonStatusEnabled : kSparkDaemonStatusDisabled];
}

- (void)setLibrary:(id<SparkLibrary>)library uuid:(NSUUID *)uuid {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!self->se_sync)
      self->se_sync = [[SparkLibrarySynchronizer alloc] initWithLibrary:SparkActiveLibrary()];

    [self->se_sync setDistantLibrary:library uuid:uuid];
  });
}

- (SparkDaemonStatus)status {
  return se_status;
}
- (void)setStatus:(SparkDaemonStatus)status {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self->se_status != status) {
      self->se_status = status;
      [[NSNotificationCenter defaultCenter] postNotificationName:SEServerStatusDidChangeNotification
                                                          object:self];
    }
  });
}

- (BOOL)isRunning {
  return se_status == kSparkDaemonStatusEnabled || se_status == kSparkDaemonStatusDisabled;
}

@end

BOOL SESparkAgentIsEnabled(pid_t *pid) {
  BOOL isEnabled  = NO;

  // the easy and sane method (SMJobCopyDictionary) can pose problems when sandboxed. -_-
  NSArray* jobDicts = CFBridgingRelease(SMCopyAllJobDictionaries(kSMDomainUserLaunchd));
  if (jobDicts && jobDicts.count > 0) {
      for (NSDictionary* job in jobDicts) {
        if ([kSparkDaemonServiceName isEqualToString:job[@"Label"]]) {
          if (pid)
            *pid = (pid_t)[job[@"PID"] integerValue];
          NSLog(@"job: %@", job);
          return [job[@"OnDemand"] boolValue];
        }
      }
  }

  return isEnabled;
}

BOOL SESparkAgentSetEnabled(BOOL enabled) {
  // Make sure libary is saved before starting the agent
  if (enabled)
    [SparkActiveLibrary() synchronize];

  spx_log_info("set spark agent %s", enabled ? "enabled" : "disabled");
  [NSUserDefaults.standardUserDefaults setBool:!enabled forKey:kSparkAgentDisabled];
  return SMLoginItemSetEnabled(SPXNSToCFString(kSparkDaemonServiceName), enabled);
}
