/*
 *  SparkIconManager.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkLibrary, SparkObject;

SPARK_OBJC_EXPORT
@interface SparkIconManager : NSObject

- (instancetype)initWithLibrary:(SparkLibrary *)aLibrary URL:(NSURL *)url;

@property(nonatomic, retain) NSURL *URL;

- (NSImage *)iconForObject:(SparkObject *)anObject;

- (void)setIcon:(NSImage *)icon forObject:(SparkObject *)anObject;

- (BOOL)synchronize;

@end

