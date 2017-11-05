/*
 *  ScriptHandler.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEScriptHandler.h"

// MARK: -
@implementation SparkEditor (SEScriptHandler)

- (void)handleHelpScriptCommand:(NSScriptCommand *)scriptCommand {
  NSString *page = [[scriptCommand arguments] objectForKey:@"Page"];
  id delegate = self.delegate;
  if (page) {
    [delegate showPlugInHelpPage:page];
  } else {
    [delegate showPlugInHelp:nil];
  }
}

// MARK: Trapping property accessor
- (BOOL)isTrapping {
  id window = [NSApp keyWindow];
  if (window && [window respondsToSelector:@selector(isTrapping)]) {
    return [window isTrapping];
  }
  return NO;
}

@end
