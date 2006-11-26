/*
 *  ScriptHandler.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "SEScriptHandler.h"

NSString * const SEServerStatusDidChangeNotification = @"SEServerStatusDidChange";

#pragma mark -
@implementation SparkEditor (SEScriptHandler)

- (void)handleHelpScriptCommand:(NSScriptCommand *)scriptCommand {
  NSString *page = [[scriptCommand arguments] objectForKey:@"Page"];
  if (page) {
    [[self delegate] showPlugInHelpPage:page];
  } else {
    [[self delegate] showPlugInHelp:nil];
  }
}

#pragma mark Trapping property accessor
- (BOOL)isTrapping {
  id window = [NSApp keyWindow];
  if (window && [window respondsToSelector:@selector(isTrapping)]) {
    return [window isTrapping];
  }
  return NO;
}

#pragma mark -
- (SparkDaemonStatus)serverStatus {
  return se_status;
}
- (void)setServerStatus:(SparkDaemonStatus)theStatus {
  if (kSparkDaemonError == theStatus) {
    DLog(@"Error while starting daemon");
    theStatus = kSparkDaemonStopped;
  }
  se_status = theStatus;
  [[NSNotificationCenter defaultCenter] postNotificationName:SEServerStatusDidChangeNotification 
                                                      object:self];
}

@end
