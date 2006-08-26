/*
 *  ServerController.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

//#import "SEPreferences.h"
#import "SEServerConnection.h"
#import "SEScriptHandler.h"

#define SparkRemoteMsgSend(method, object, log)		    \
id<SparkServer> server;				\
if (server = [self serverProxy]) {	\
  @try {							\
    [server method object];			\
  }									\
  @catch (id exception) {			\
    SKLogException(exception);		\
  }									\
  DLog(log);						\
}

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionDidDie:)
                                                 name:NSConnectionDidDieNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(serverStatusDidChange:)
                                                 name:SEServerStatusDidChangeNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [se_server release];
  [super dealloc];
}

- (BOOL)connect {
  if ([self isConnected])
    return YES;
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

- (id<SparkServer>)server {
  return se_server;
}

- (void)connectionDidDie:(NSNotification *)aNotification {
  if (se_server && [aNotification object] == [se_server connectionForProxy]) {
    DLog(@"Connection did close");
    [se_server release];
    se_server = nil;
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

@end

#if 0
/* If a daemon is runnnig, check if it is the bundled Daemon.
* If not, kill it and launch the bundled one */
- (void)checkRunningDaemon {
  id sparkPath = [[NSBundle mainBundle] bundlePath];
  ProcessSerialNumber psn = SKGetProcessWithSignature(kSparkDaemonHFSCreatorType);
  if (psn.lowLongOfPSN != kNoProcess) {
    FSRef location;
    if (noErr == GetProcessBundleLocation(&psn, &location)) {
      CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &location);
      id daemonPath = (id)CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
      [(id)url release];
      if (daemonPath && ![daemonPath hasPrefix:sparkPath]) {
#if !defined (DEBUG)
        if ([self serverProxy]) {
          DLog(@"Shut down old daemon");
          [self shutDownServer];
        } else {
          pid_t pid;
          if (noErr == GetProcessPID(&psn, &pid)) {
            DLog(@"Nice kill old daemon");
            kill(pid, SIGTERM);
          } else {
            DLog(@"Violent kill old daemon");
            KillProcess(&psn);
          }
        }
        [self shutDownServer];
        [self startServer];
#else
#warning Disable Check Daemon
        DLog(@"Found old daemon at %@", daemonPath);
#endif
      }
      [daemonPath release];
    }
  }
}

- (void)startServer {
  if (kSparkDaemonStarted != [[self class] serverState]) {
    [SparkDefaultLibrary() synchronize];
    id path = [[[NSBundle mainBundle] executablePath] stringByDeletingLastPathComponent];
    if (![[NSWorkspace sharedWorkspace] launchApplication:[path stringByAppendingPathComponent:(id)kSparkDaemonExecutable]]) {
      DLog(@"Error cannot launch daemon app");
      [[NSApp delegate] setServerState:kSparkDaemonError];
    }
  }
  else {
    // Dire à Spark que le serveur tourne déjà
    DLog(@"Daemon already running");
    [[NSApp delegate] setServerState:kSparkDaemonStarted];
  }
}

#endif /* 0 */
