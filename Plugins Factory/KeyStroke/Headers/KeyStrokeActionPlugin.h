//
//  KeyStrokeActionPlugin.h
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>
#import <HotKeyToolKit/HotKeyToolKit.h>

extern NSString * const kKeyStrokeActionBundleIdentifier;

#define kKeyStrokeActionBundle		[NSBundle bundleWithIdentifier:kKeyStrokeActionBundleIdentifier]

enum {
  kSShiftModifier = 'Ksft',
  kSOptionModifier = 'Kopt',
  kSControlModifier = 'Kctl',
  kSCommandModifier = 'Kcmd'
};

@interface KeyStrokeActionPlugin : SparkActionPlugIn {
  HKHotKey *ks_key;
  UInt32 ks_rawkey;
  IBOutlet NSWindow *choosePanel;
  IBOutlet NSTableView *tableView;
  IBOutlet NSArrayController *keys;
  IBOutlet NSTextField *shortcutField;
}

@end
