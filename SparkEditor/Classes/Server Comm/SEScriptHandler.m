//
//  ScriptHandler.m
//  Short-Cut
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SEScriptHandler.h"
#import "ServerController.h"
#import <SparkKit/SparkKit.h>

NSString* const kSPServerStatChangeNotification = @"Server State Change";

@implementation Spark (AppleScriptExtension)

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
  return [key isEqualToString:@"serverState"]
  || [key isEqualToString:@"trapping"];
}

- (NSString *)serverStateTitle {
  if (kSparkDaemonStarted == se_serverState) {
    return NSLocalizedString(@"DEACTIVE_SPARK_MENU",
                             @"Spark Daemon Menu Title * Desactive *");
  } else {
    return NSLocalizedString(@"ACTIVE_SPARK_MENU",
                             @"Spark Daemon Menu Title * Active *");
  }
}

- (DaemonStatus)serverState {
  return se_serverState;
}
- (void)setServerState:(DaemonStatus)state {
  if (kSparkDaemonError == state) {
    DLog(@"Error while starting daemon");
    state = kSparkDaemonStopped;
  }
  [self willChangeValueForKey:@"serverStateTitle"];
  se_serverState = state;
  [[NSNotificationCenter defaultCenter] postNotificationName:kSPServerStatChangeNotification object:self];
  [self didChangeValueForKey:@"serverStateTitle"];
}

- (BOOL)isTrapping {
  id window = [NSApp keyWindow];
  if (window && [window respondsToSelector:@selector(isTrapping)]) {
    return [window isTrapping];
  }
  return NO;
}

@end

#pragma mark -
@implementation SparkEditor (SparkScriptSuite)

- (void)handleHelpScriptCommand:(NSScriptCommand *)scriptCommand {
  NSString *page = [[scriptCommand arguments] objectForKey:@"Page"];
  if (page) {
    [[self delegate] showPlugInHelpPage:page];
  } else {
    [[self delegate] showPlugInHelp:nil];
  }
}

@end
