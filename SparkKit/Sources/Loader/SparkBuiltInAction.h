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
	kSparkSDActionExchangeListStatus = 'ExLi', /* 1165511785 */
};

@class SparkList;
@interface SparkBuiltInActionPlugin : SparkActionPlugIn {
  OSType sb_action;
  //SparkList *sp_gpr, *sp_gpr2;

  IBOutlet NSTextField *uiName;
  IBOutlet NSTextField *uiLabel;
  IBOutlet NSPopUpButton *uiLists;
  IBOutlet NSPopUpButton *uiLists2;
}

- (OSType)action;
- (void)setAction:(OSType)action;

- (IBAction)selectGroup:(NSPopUpButton *)sender;
- (IBAction)selectAlternateGroup:(NSPopUpButton *)sender;

@end

@class SparkList;
@interface SparkBuiltInAction : SparkAction {
  @private
  OSType sp_action;
  SparkList *sp_list, *sp_altList;
  SparkUID sp_listUID, sp_altListUID;
}

- (OSType)action;
- (void)setAction:(OSType)anAction;

- (SparkList *)list;
- (void)setList:(SparkList *)aList;

- (SparkList *)alternateList;
- (void)setAlternateList:(SparkList *)aList;

@end
