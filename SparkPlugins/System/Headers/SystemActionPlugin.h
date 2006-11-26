/*
 *  SystemActionPlugin.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>
#import "SystemAction.h"

@interface SystemActionPlugin : SparkActionPlugIn {
  IBOutlet NSButton *displayBox;
  IBOutlet NSTextField *ibName;
  
  IBOutlet NSPopUpButton *ibUsers;
  IBOutlet NSPopUpButton *ibActions;
}

- (SystemActionType)action;
- (void)setAction:(SystemActionType)anAction;

- (BOOL)shouldConfirm;
- (void)setShouldConfirm:(BOOL)flag;

@end
