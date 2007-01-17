/*
 *  SparkShadow.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKApplication.h>
#import <ShadowKit/SKAliasedApplication.h>

#pragma mark -
@interface SKApplication (SparkSerialization)
- (BOOL)serialize:(NSMutableDictionary *)plist;
- (id)initWithSerializedValues:(NSDictionary *)plist;
@end

@interface SKAliasedApplication (SparkSerialization)
- (BOOL)serialize:(NSMutableDictionary *)plist;
- (id)initWithSerializedValues:(NSDictionary *)plist;
@end
