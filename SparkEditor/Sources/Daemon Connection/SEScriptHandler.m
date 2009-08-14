/*
 *  ScriptHandler.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEScriptHandler.h"

#pragma mark -
@implementation SparkEditor (SEScriptHandler)

- (void)handleHelpScriptCommand:(NSScriptCommand *)scriptCommand {
  NSString *page = [[scriptCommand arguments] objectForKey:@"Page"];
  if (page) {
    [(id)[self delegate] showPlugInHelpPage:page];
  } else {
    [(id)[self delegate] showPlugInHelp:nil];
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

@end
