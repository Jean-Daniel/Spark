//
//  Extension.m
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "Extension.h"
#import "ShadowMacros.h"
#import "SparkConstantes.h"
#import "SparkMultipleAlerts.h"

void SparkDisplayAlerts(NSArray *items) {
  if ([items count] == 1) {
    SparkAlert *alert = [items objectAtIndex:0];
    id other = [alert hideSparkButton] ? nil : NSLocalizedStringFromTableInBundle(@"LAUNCH_SPARK_BUTTON", nil,
                                                                                  [NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier],
                                                                                  @"Open Spark Alert Button");
    [NSApp activateIgnoringOtherApps:YES];
    if (NSRunAlertPanel([alert messageText],[alert informativeText], @"OK", nil, other) == NSAlertOtherReturn) {
      SparkLaunchEditor();
    }
  }
  else if ([items count] > 1) {
    id alerts = [[SparkMultipleAlerts alloc] initWithAlerts:items];
    [alerts showAlerts];
    [alerts autorelease];
  }  
}

void SparkLaunchEditor() {
  NSBundle *bundle = [NSBundle mainBundle];
  if ([[bundle bundleIdentifier] isEqualToString:kSparkBundleIdentifier]) {
    [NSApp activateIgnoringOtherApps:NO];
  } else if ([[bundle bundleIdentifier] isEqualToString:kSparkDaemonBundleIdentifier]) {
    NSString *sparkPath = [[bundle bundlePath] stringByAppendingPathComponent:@"../../../"];
    DLog(@"%@", [[NSFileManager defaultManager] displayNameAtPath:sparkPath]);
    [[NSWorkspace sharedWorkspace] launchApplication:sparkPath];
  }
}

/* String Extension */
@implementation NSString (Spark_Extension)

- (NSString *)stringByTrimmingWhitespaceAndNewline {
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
