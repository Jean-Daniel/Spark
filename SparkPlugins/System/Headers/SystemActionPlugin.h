/*
 *  SystemActionPlugin.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>
#import "SystemAction.h"

@interface SystemActionPlugin : SparkActionPlugIn {
  IBOutlet NSTabView *uiOptions;
  IBOutlet NSTextField *ibName;

  IBOutlet NSButton *ibFeedback;
  IBOutlet NSPopUpButton *ibUsers;
  IBOutlet NSPopUpButton *ibActions;
}

@property(nonatomic) SystemActionType action;

- (IBAction)changeUser:(id)sender;

@end
