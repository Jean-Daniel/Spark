/*
 *  MyActionPlugin.h
 *  MySparkAction
 *
 *  Created by Black Moon Team.
 *  Copyright (c) ShadowLab. 2004 - 2006.
 */

#import <SparkKit/SparkPluginAPI.h>

@interface MyActionPlugin : SparkActionPlugIn {

}

- (int)beepCount;
- (void)setBeepCount:(int)newBeepCount;

@end
