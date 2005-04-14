//
//  ServerController.m
//  Spark
//
//  Created by Fox on Sun Dec 14 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
#import <SparkKit/SparkKit.h>

#import "ScriptHandler.h"
#import "ServerController.h"
#import "SparkServerProtocol.h"

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

#ifdef DEBUG
NSString * const kSparkDaemonConnectionName = @"SparkServer_Debug";
#else
NSString * const kSparkDaemonConnectionName = @"SparkServer";
#endif

NSString * const kSparkListDidChangeNotification = @"SparkListDidChangeNotification";
NSString * const kSparkActionDidChangeNotification = @"SparkActionDidChangeNotification";
NSString * const kSparkHotKeyDidChangeNotification = @"SparkHotKeyDidChangeNotification";
NSString * const kSparkApplicationDidChangeNotification = @"SparkApplicationDidChangeNotification";

NSString * const kSparkHotKeyStateDidChangeNotification = @"SparkHotKeyStateDidChangeNotification";

@implementation ServerController

- (id)init {
  if (self = [super init]) {
    [self registerNotification];
    [self checkRunningDaemon];
    DLog(@"Debug Connection OK");
  }
  return self;
}

/* If a daemon is runnnig, check if it is the bundled Daemon.
 * If not, kill it and launch the bundled one */
- (void)checkRunningDaemon {
#if !defined (DEBUG)
  id sparkPath = [[NSBundle mainBundle] bundlePath];
  ProcessSerialNumber psn = SKGetProcessWithSignature(kSparkDaemonHFSCreatorType);
  if (psn.lowLongOfPSN != kNoProcess) {
    FSRef location;
    if (noErr == GetProcessBundleLocation(&psn, &location)) {
      CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &location);
      id daemonPath = (id)CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
      [(id)url release];
      if (daemonPath && ![daemonPath hasPrefix:sparkPath]) {
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
      }
      [daemonPath release];
    }
  }
#else
#warning Disable Check Daemon
#endif
}

- (void)registerNotification {
  id center = [NSNotificationCenter defaultCenter];
  /* Hotkey */
  [center addObserver:self
             selector:@selector(addKeyNotification:)
                 name:kSparkLibraryDidAddKeyNotification
               object:SparkDefaultLibrary()];
  [center addObserver:self
             selector:@selector(removeKeyNotification:)
                 name:kSparkLibraryDidRemoveKeyNotification
               object:SparkDefaultLibrary()];
  [center addObserver:self
             selector:@selector(updateKeyNotification:)
                 name:kSparkHotKeyDidChangeNotification
               object:nil];
  [center addObserver:self
             selector:@selector(keyStatDidChangeNotification:)
                 name:kSparkHotKeyStateDidChangeNotification
               object:nil];
  /* Action */
  [center addObserver:self
             selector:@selector(addActionNotification:)
                 name:kSparkLibraryDidAddActionNotification
               object:SparkDefaultLibrary()];
  [center addObserver:self
             selector:@selector(removeActionNotification:)
                 name:kSparkLibraryDidRemoveActionNotification
               object:SparkDefaultLibrary()];
  [center addObserver:self
             selector:@selector(updateActionNotification:)
                 name:kSparkActionDidChangeNotification
               object:nil];
  /* List */
  [center addObserver:self
             selector:@selector(addListNotification:)
                 name:kSparkLibraryDidAddListNotification
               object:SparkDefaultLibrary()];
  [center addObserver:self
             selector:@selector(removeListNotification:)
                 name:kSparkLibraryDidRemoveListNotification
               object:SparkDefaultLibrary()];
  [center addObserver:self
             selector:@selector(updateListNotification:)
                 name:kSparkListDidChangeNotification
               object:nil];
  /* Application */
  [center addObserver:self
             selector:@selector(addApplicationNotification:)
                 name:kSparkLibraryDidAddApplicationNotification
               object:SparkDefaultLibrary()];
  [center addObserver:self
             selector:@selector(removeApplicationNotification:)
                 name:kSparkLibraryDidRemoveApplicationNotification
               object:SparkDefaultLibrary()];
  [center addObserver:self
             selector:@selector(updateApplicationNotification:)
                 name:kSparkApplicationDidChangeNotification
               object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

+ (void)start {
  [self sharedController];
}

+ (ServerController *)sharedController {
  static id controller = nil;
  if (!controller) {
    controller = [[self alloc] init]; 
  }
  return controller;
}

+ (DaemonStatus)serverState {
  return ([NSConnection connectionWithRegisteredName:kSparkDaemonConnectionName host:nil] != nil) ? kSparkDaemonStarted : kSparkDaemonStopped;
}

- (id)serverProxy {
  NSDistantObject *theProxy = nil;
  @try {
    theProxy = [NSConnection rootProxyForConnectionWithRegisteredName:kSparkDaemonConnectionName host:nil];
    [theProxy setProtocolForProxy:@protocol(SparkServer)];
    DLog(@"Server State: %@", theProxy ? @"On": @"Off");
  } @catch (id exception) {
    SKLogException(exception);
  }
  return theProxy;
}

- (void)startServer {
  if (kSparkDaemonStarted != [[self class] serverState]) {
    [SparkDefaultLibrary() synchronize];
    id path = [[[NSBundle mainBundle] executablePath] stringByDeletingLastPathComponent];
    if (![[NSWorkspace sharedWorkspace] launchApplication:[path stringByAppendingPathComponent:@"Spark Daemon.app"]]) {
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

- (void)shutDownServer {
  id<SparkServer> server;
  if (server = [self serverProxy]) {
    @try {
      [server shutDown];
    }
    @catch (id exception) {
      SKLogException(exception);
    }
    DLog(@"Shut Down server");
  }
  else {
    // Le logiciel ne sait pas que le serveur est arrêté
    DLog(@"Daemon already stopped");
    [[NSApp delegate] setServerState:kSparkDaemonStopped];
  }
}

#pragma mark -
#pragma mark Lists
- (void)addListNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(addList:, SparkSerializeObject(SparkNotificationObject(aNotification)), @"Add List on server");
}
- (void)updateListNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(updateList:, SparkSerializeObject([aNotification object]), @"Update List on server");
}
- (void)removeListNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(removeList:, [[SparkNotificationObject(aNotification) uid] unsignedIntValue], @"Remove List from server");
}

#pragma mark -
#pragma mark Actions
- (void)addActionNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(addAction:, SparkSerializeObject(SparkNotificationObject(aNotification)), @"Add Action on server");
}
- (void)updateActionNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(updateAction:, SparkSerializeObject([aNotification object]), @"Update Action on server");
}
- (void)removeActionNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(removeAction:, [[SparkNotificationObject(aNotification) uid] unsignedIntValue], @"Remove Action from server");
}

#pragma mark -
#pragma mark HotKeys
- (void)addKeyNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(addHotKey:, SparkSerializeObject(SparkNotificationObject(aNotification)), @"Add Key on server");
}
- (void)updateKeyNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(updateHotKey:, SparkSerializeObject([aNotification object]), @"Update Key on server");
}
- (void)removeKeyNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(removeHotKey:, [[SparkNotificationObject(aNotification) uid] unsignedIntValue], @"Remove Key from server");
}

- (void)keyStatDidChangeNotification:(NSNotification *)aNotification {
  id key = [aNotification object];
  if (([key library] == SparkDefaultLibrary())
      && [SparkDefaultKeyLibrary() objectWithId:[key uid]]) {
    ShadowTrace();
    id<SparkServer> server;
    if (server = [self serverProxy]) {
      @try {
        [server setActive:[key isActive] forHotKey:[[key uid] unsignedIntValue]];
      }
      @catch (id exception) {
        SKLogException(exception);
      }
      DLog(@"State Change Notification");
    }
  }
}

#pragma mark -
#pragma mark Applications
- (void)addApplicationNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(addApplication:, SparkSerializeObject(SparkNotificationObject(aNotification)), @"Add Application on server");
}
- (void)updateApplicationNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(updateApplication:, SparkSerializeObject([aNotification object]), @"Update Application on server");
}
- (void)removeApplicationNotification:(NSNotification *)aNotification {
  ShadowTrace();
  SparkRemoteMsgSend(removeApplication:, [[SparkNotificationObject(aNotification) uid] unsignedIntValue], @"Remove Application from server");
}

@end
