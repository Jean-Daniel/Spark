//
//  SystemActionPlugin.h
//  Spark
//
//  Created by Fox on Wed Feb 18 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>
#import "SystemAction.h"

@interface SystemActionPlugin : SparkActionPlugIn {
  IBOutlet NSTextField *nameField;
  IBOutlet NSPopUpButton *actionMenu;
}

- (SystemActionType)action;
- (void)setAction:(SystemActionType)anAction;

- (NSString *)actionDescription;

@end
