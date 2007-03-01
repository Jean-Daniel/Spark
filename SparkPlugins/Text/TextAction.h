/*
 *  TextAction.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

@interface TextAction : SparkAction {
  NSString *ta_str;
}

- (NSString *)string;
- (void)setString:(NSString *)aString;


@end
