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
  IBOutlet id applicationMenu;
  IBOutlet id nameField;
  NSString *keystroke;
  int keyModifier;
}
- (IBAction)selectApplication:(id)sender;

- (id)keystroke;
- (void)setKeystroke:(id)newKeystroke;
- (int)keyModifier;
- (void)setKeyModifier:(int)newModifier;

@end
