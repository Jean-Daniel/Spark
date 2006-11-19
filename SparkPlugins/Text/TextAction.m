/*
 *  TextAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "TextAction.h"

@implementation TextAction

- (void)dealloc {
  [ta_str release];
  [super dealloc];
}

- (NSString *)string {
  return ta_str;
}

- (void)setString:(NSString *)aString {
  SKSetterRetain(ta_str, aString);
}

@end
