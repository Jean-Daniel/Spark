/*
 *  SparkBuiltInAction.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionPlugIn.h>

enum {
  kSparkSDActionLaunchEditor     = 'OpSe', /* 1332761445 */
  kSparkSDActionSwitchStatus     = 'SwSt', /* 1400329076 */
  kSparkSDActionSwitchListStatus = 'SwLi', /* 1400327273 */
};

@interface SparkBuiltInActionPlugin : SparkActionPlugIn {
  IBOutlet NSTextField *uiName;
  IBOutlet NSTextField *uiLabel;
  IBOutlet NSPopUpButton *uiLists;
  
}

- (OSType)action;
- (void)setAction:(OSType)action;

@end

@class SparkList;
@interface SparkBuiltInAction : SparkAction {
  @private
  SparkUID sp_list;
  OSType sp_action;
}

- (OSType)action;
- (void)setAction:(OSType)anAction;

- (SparkList *)list;

@end
