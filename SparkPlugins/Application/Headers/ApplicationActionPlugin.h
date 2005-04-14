//
//  ApplicationActionPlugin.h
//  Short-Cut
//
//  Created by Fox on Mon Dec 08 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>

extern NSString * const kApplicationActionBundleIdentifier;

#define ApplicationActionBundle			[NSBundle bundleWithIdentifier:kApplicationActionBundleIdentifier]

enum {
  kOpenActionTag =      0,
  kRestartActionTag =   1,
  kQuitActionTag =      2,
  kKillActionTag =		3 
};

@interface ApplicationActionPlugin : SparkActionPlugIn {
  @private
  id _appName, _appIcon;
//  int action;
  int flags;
}

- (IBAction)chooseApplication:(id)sender;

- (NSString *)appPath;
- (void)setAppPath:(NSString *)appPath;

- (NSString *)appName;
- (void)setAppName:(NSString *)appName;

- (NSImage *)appIcon;
- (void)setAppIcon:(NSString *)appIcon;

- (NSString *)actionDescription:(id)key;

- (int)appAction;
- (void)setAppAction:(int)newAction;

- (void)setFlags:(int)value;
- (BOOL)dontSwitch;
- (void)setDontSwitch:(BOOL)dontSwitch;
- (BOOL)newInstance;
- (void)setNewInstance:(BOOL)newInstance;
- (BOOL)hide;
- (void)setHide:(BOOL)hide;
- (BOOL)hideOthers;
- (void)setHideOthers:(BOOL)hideOthers;
@end
