/*
 *  SparkShadow.h
 *  SparkKit
 *
 *  Created by Grayfox on 16/09/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
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
