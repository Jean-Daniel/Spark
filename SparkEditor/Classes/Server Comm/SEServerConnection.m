//
//  ServerController.m
//  Spark
//
//  Created by Fox on Sun Dec 14 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
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
      DLog(@"Server connection failed");
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

//- (void)registerNotification {
//  id center = [NSNotificationCenter defaultCenter];
//  /* Hotkey */
//  [center addObserver:self
//             selector:@selector(addKeyNotification:)
//                 name:kSparkLibraryDidAddKeyNotification
//               object:SparkDefaultLibrary()];
//  [center addObserver:self
//             selector:@selector(removeKeyNotification:)
//                 name:kSparkLibraryDidRemoveKeyNotification
//               object:SparkDefaultLibrary()];
//  [center addObserver:self
//             selector:@selector(updateKeyNotification:)
//                 name:kSparkHotKeyDidChangeNotification
//               object:nil];
//  [center addObserver:self
//             selector:@selector(keyStatDidChangeNotification:)
//                 name:kSparkHotKeyStateDidChangeNotification
//               object:nil];
//}

//#pragma mark -
//#pragma mark HotKeys
//- (void)addKeyNotification:(NSNotification *)aNotification {
//  ShadowTrace();
//  SparkRemoteMsgSend(addHotKey:, SparkSerializeObject(SparkNotificationObject(aNotification)), @"Add Key on server");
//}
//- (void)updateKeyNotification:(NSNotification *)aNotification {
//  ShadowTrace();
//  SparkRemoteMsgSend(updateHotKey:, SparkSerializeObject([aNotification object]), @"Update Key on server");
//}
//- (void)removeKeyNotification:(NSNotification *)aNotification {
//  ShadowTrace();
//  SparkRemoteMsgSend(removeHotKey:, [[SparkNotificationObject(aNotification) uid] unsignedIntValue], @"Remove Key from server");
//}
//
//- (void)keyStatDidChangeNotification:(NSNotification *)aNotification {
//  id key = [aNotification object];
//  if (([key library] == SparkDefaultLibrary())
//      && [SparkDefaultKeyLibrary() objectWithId:[key uid]]) {
//    ShadowTrace();
//    id<SparkServer> server;
//    if (server = [self serverProxy]) {
//      @try {
//        [server setActive:[key isActive] forHotKey:[[key uid] unsignedIntValue]];
//      }
//      @catch (id exception) {
//        SKLogException(exception);
//      }
//      DLog(@"State Change Notification");
//    }
//  }
//}

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
          DLog(@"Shut Down old daemon");
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
