/*
 *  ApplicationPlugin.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPlugInAPI.h>

#import "ApplicationAction.h"

@class WBImageView;
@interface ApplicationPlugin : SparkActionPlugIn {
  IBOutlet NSTextField *ibApplication;

  IBOutlet NSTabView *ibTab;
  IBOutlet NSTextField *ibName;
  IBOutlet WBImageView *ibIcon;
}

- (IBAction)back:(id)sender;
- (IBAction)options:(id)sender;
- (IBAction)chooseApplication:(id)sender;

@property(nonatomic) ApplicationActionType action;

@property(nonatomic, readonly) BOOL showOptions;
@property(nonatomic, readonly) BOOL showChooser;

@property(nonatomic) NSInteger visual;

@property(nonatomic, readonly) BOOL notifyLaunch;
@property(nonatomic, readonly) BOOL notifyActivation;

@property(nonatomic, copy) NSString * path;

@property(nonatomic) LSLaunchFlags flags;

@property(nonatomic) BOOL dontSwitch;

@property(nonatomic) BOOL newInstance;

@property(nonatomic) BOOL hide;

@property(nonatomic) BOOL hideOthers;

@end
