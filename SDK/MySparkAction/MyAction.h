/*
 *  MyAction.h
 *  MySparkAction
 *
 *  Created by Black Moon Team.
 *  Copyright (c) ShadowLab. 2004 - 2006.
 */

#import <SparkKit/SparkPluginAPI.h>

@interface MyAction : SparkAction <NSCopying> {
@private
  NSString *my_message;
}

- (NSString *)message;
- (void)setMessage:(NSString *)aMessage;

@end
