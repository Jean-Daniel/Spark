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

}

@end

@interface SparkBuiltInAction : SparkAction {
  @private
  OSType sp_action;
  NSString *sp_list;
}

- (OSType)action;
- (void)setAction:(OSType)anAction;

@end
