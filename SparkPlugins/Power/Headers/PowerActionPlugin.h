//
//  PowerActionPlugin.h
//  Spark
//
//  Created by Fox on Wed Feb 18 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>

enum {
  kPowerLogOut,
  kPowerSleep,
  kPowerRestart,
  kPowerShutDown,
  kPowerFastLogOut,
  kPowerScreenSaver
};

extern NSString * const kPowerActionBundleIdentifier;

#define kPowerActionBundle		[NSBundle bundleWithIdentifier:kPowerActionBundleIdentifier]

@interface PowerActionPlugin : SparkActionPlugIn {
  IBOutlet id nameField;
}

- (int)powerAction;
- (void)setPowerAction:(int)newAction;

- (NSString *)shortDescription;

@end
