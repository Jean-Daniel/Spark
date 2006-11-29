/*
 *  SEFirstRun.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "SEFirstRun.h"

#import "Spark.h"
#import "SEServerConnection.h"

#import <ShadowKit/SKFunctions.h>

static const int kSparkVersion = 0x030000; /* 3.0.0 */

@implementation Spark (SEFirstRun)

- (void)displayFirstRunIfNeeded {
  int version = [[NSUserDefaults standardUserDefaults] integerForKey:@"SparkVersion"];
  if (0 == version) {
    /* SparkEditor preferences does not exists => Clear old .Spark Preferences */
    CFArrayRef keys = CFPreferencesCopyKeyList((CFStringRef)kSparkBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (keys) {
      CFPreferencesSetMultiple(nil, keys,
                               (CFStringRef)kSparkBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
      CFPreferencesSynchronize((CFStringRef)kSparkBundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
      CFRelease(keys);
    }
  }
  if (version < kSparkVersion) {
    SEFirstRun *first = [[SEFirstRun alloc] init];
    [first setReleasedWhenClosed:YES];
    [NSApp beginSheet:[first window]
       modalForWindow:[self mainWindow]
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:nil];
  }
}

@end

@implementation SEFirstRun

+ (NSString *)frameAutoSaveName {
  return nil;
}

- (void)awakeFromNib {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"Read First" ofType:@"rtf"];
  NSURL *url = [NSURL fileURLWithPath:path];
  NSTextStorage *storage = [[NSTextStorage alloc] initWithURL:url documentAttributes:nil];
  [[ibText layoutManager] replaceTextStorage:storage];
}

- (IBAction)close:(id)sender {
  if ([ibStartNow state] == NSOnState && kSparkDaemonStarted != [NSApp serverStatus]) {
    SELaunchSparkDaemon();
  }
  //if (autorun) {
//    [Preferences setAutoStart:YES];
//  }
//  [[NSUserDefaults standardUserDefaults] setBool:autorun forKey:kSparkPrefAutoStart];
  [[NSUserDefaults standardUserDefaults] setInteger:kSparkVersion forKey:@"SparkVersion"];
  [super close:sender];  
}

@end
