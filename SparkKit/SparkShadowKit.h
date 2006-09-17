/*
 *  SparkShadow.h
 *  SparkKit
 *
 *  Created by Grayfox on 16/09/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKApplication.h>

#pragma mark -
@interface SKApplication (SparkSerialization)
- (BOOL)serialize:(NSMutableDictionary *)plist;
- (id)initWithSerializedValues:(NSDictionary *)plist;
@end

