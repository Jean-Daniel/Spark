//
//  KeyStrokeActionPlugin.h
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SparkKit/SparkKit.h>

extern NSString * const kKeyStrokeActionBundleIdentifier;

#define kKeyStrokeActionBundle		[NSBundle bundleWithIdentifier:kKeyStrokeActionBundleIdentifier]

enum {
  kSShiftModifier = 'Ksft',
  kSOptionModifier = 'Kopt',
  kSControlModifier = 'Kctl',
  kSCommandModifier = 'Kcmd'
};

@interface KeyStrokeActionPlugin : SparkActionPlugIn {
  HKHotKey *ks_hotkey;
  IBOutlet id nameField;
}

@end
