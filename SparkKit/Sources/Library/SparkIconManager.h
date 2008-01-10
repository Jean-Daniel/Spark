/*
 *  SparkIconManager.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkLibrary, SparkObject;
SPARK_CLASS_EXPORT
@interface SparkIconManager : NSObject {
  @private
  SparkLibrary *sp_library;
	/* archive support */
	@protected
	NSString *sp_path;
	NSMapTable *sp_cache[4];
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary path:(NSString *)path;

- (NSString *)path;
- (void)setPath:(NSString *)path;

- (NSImage *)iconForObject:(SparkObject *)anObject;

- (void)setIcon:(NSImage *)icon forObject:(SparkObject *)anObject;

- (BOOL)synchronize;

@end

