/*
 *  ApplicationActionPlugin.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) Shadow Lab. 2004 - 2006. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

#import "ApplicationAction.h"

@interface ApplicationActionPlugin : SparkActionPlugIn {
  IBOutlet NSButton *ibOptions;
  IBOutlet NSTabView *ibTab;
  IBOutlet NSImageView *ibIcon;
  @private
    NSImage *aa_icon;
  NSString *aa_name;
  LSLaunchFlags aa_flags;
}

- (IBAction)back:(id)sender;
- (IBAction)options:(id)sender;
- (IBAction)chooseApplication:(id)sender;

- (ApplicationActionType)action;
- (void)setAction:(ApplicationActionType)anAction;

- (int)visual;
- (void)setVisual:(int)visual;

- (void)setPath:(NSString *)path;
- (void)setFlags:(LSLaunchFlags)value;

- (BOOL)dontSwitch;
- (void)setDontSwitch:(BOOL)dontSwitch;
- (BOOL)newInstance;
- (void)setNewInstance:(BOOL)newInstance;
- (BOOL)hide;
- (void)setHide:(BOOL)hide;
- (BOOL)hideOthers;
- (void)setHideOthers:(BOOL)hideOthers;

@end
