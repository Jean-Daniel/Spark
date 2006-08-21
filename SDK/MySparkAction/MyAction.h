/*
 *  MyAction.h
 *  MySparkAction
 *
 *  Created by Black Moon Team.
 *  Copyright (c) ShadowLab. 2004 - 2006.
 */

#import <SparkKit/SparkPluginAPI.h>

@interface MyAction : SparkAction {
  @private
  unsigned my_count;
}

- (int)beepCount;
- (void)setBeepCount:(int)aBeepCount;

@end
