//
//  FirstRunController.m
//  Spark
//
//  Created by Fox on Sat Feb 21 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "FirstRunController.h"
#import "Preferences.h"
#import "ServerController.h"

@implementation FirstRunController

- (NSString *)readFirstPath {
  return [[NSBundle mainBundle] pathForResource:@"Read First" ofType:@"rtf"];
}

- (IBAction)closeSheet:(id)sender {
  if (autorun) {
    [Preferences setAutoStart:YES];
  }
  [[NSUserDefaults standardUserDefaults] setBool:autorun forKey:kSparkPrefAutoStart];
  [[NSUserDefaults standardUserDefaults] synchronize];
  if (run) {
    [[ServerController sharedController] startServer];
  }
  [NSApp stopModal];
}

@end
