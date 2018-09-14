//
//  SESparkDaemon.m
//  Spark
//
//  Created by Jean-Daniel on 25/11/2017.
//

#import "SESparkDaemon.h"

#import <SparkKit/SparkKit.h>
#import <ServiceManagement/ServiceManagement.h>

@protocol SparkLibrary;
@protocol SparkEditor
- (void)setActive:(BOOL)active;
- (void)setLibrary:(id<SparkLibrary>)aLibrary uuid:(NSUUID *)uuid;
@end

@interface SESparkDaemon () <SparkEditor>
@end

@implementation SESparkDaemon {
  NSXPCConnection *_cnt;
}

+ (SESparkDaemon *)sparkDaemon {
  static SESparkDaemon *_daemon = nil;
  if (!_daemon) {
    _daemon = [[SESparkDaemon alloc] init];
    [_daemon resync];
  }
  return _daemon;
}

- (instancetype)init {
  if (self = [super init]) {
    _active = YES;
  }
  return self;
}

- (BOOL)isEnabled {
  return [NSUserDefaults.standardUserDefaults boolForKey:@"StartsAtLogin"];
}
- (void)setEnabled:(BOOL)enabled {
  [NSUserDefaults.standardUserDefaults setBool:enabled forKey:@"StartsAtLogin"];
  [self resync];
}

- (void)resync {
  if (self.enabled) {
    if (_cnt) // already enabled
      return;
    if (!SMLoginItemSetEnabled(SPXNSToCFString(kSparkDaemonBundleIdentifier), true)) {
      // TODO: handle failure to setup login item
      return;
    }
    _cnt = [[NSXPCConnection alloc] initWithMachServiceName:kSparkDaemonBundleIdentifier options:0];
    __weak SESparkDaemon *wself = self;
    _cnt.interruptionHandler = ^{
      [wself disconnected];
    };
    _cnt.invalidationHandler = ^{
      [wself disconnected];
    };

    // TODO: setup connection
    _cnt.remoteObjectInterface = nil;

    _cnt.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SparkEditor)];
    _cnt.exportedObject = self;
    [_cnt resume];
  } else {
    // Just in case
    if (!SMLoginItemSetEnabled(SPXNSToCFString(kSparkDaemonBundleIdentifier), false)) {
      SPXLogError(@"login item unregistration failed !");
    }
  }
}

- (void)disconnected {
  _cnt = nil;
  // TODO: reconnect ?
}

- (void)setLibrary:(id<SparkLibrary>)aLibrary uuid:(NSUUID *)uuid {
  // after connection established
  
}

@end
