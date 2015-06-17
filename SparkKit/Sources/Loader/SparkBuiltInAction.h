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

@interface SparkBuiltInActionPlugIn : SparkActionPlugIn {
  IBOutlet NSTextField *uiName;
  IBOutlet NSTextField *uiLabel;
  IBOutlet NSPopUpButton *uiLists;
  IBOutlet NSPopUpButton *uiLists2;
}

@property(nonatomic) OSType action;

- (IBAction)selectGroup:(NSPopUpButton *)sender;
- (IBAction)selectAlternateGroup:(NSPopUpButton *)sender;

@end

@interface SparkBuiltInAction : SparkAction

@property(nonatomic) OSType action;
@property(nonatomic, retain) SparkList *list;
@property(nonatomic, retain) SparkList *alternateList;

@end
