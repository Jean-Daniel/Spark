/*
 *  MyActionPlugin.h
 *  MySparkAction
 *
 *  Created by Black Moon Team.
 *  Copyright (c) ShadowLab. 2004 - 2006.
 */

#import <SparkKit/SparkPluginAPI.h>

@interface MyActionPlugin : SparkActionPlugIn {
  @private
  NSString *my_message;
}

- (NSString *)message;
- (void)setMessage:(NSString *)aMessage;

@end
