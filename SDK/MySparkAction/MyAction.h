//
//  MyAction.h
//  MySparkAction
//
//  Created by Fox on Sat Mar 20 2004.
//  Copyright (c) 2004 ShadowLab. All rights reserved.
//

#import <SparkKit/SparkPluginAPI.h>

@interface MyAction : SparkAction {
  @private
  unsigned my_count;
}

- (int)beepCount;
- (void)setBeepCount:(int)aBeepCount;

@end
