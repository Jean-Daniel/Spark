/*
 *  SparkIconManager.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkLibrary, SparkObject;
@interface SparkIconManager : NSObject {
  @private
  NSString *sp_path;
  NSMapTable *sp_cache[4];
  SparkLibrary *sp_library;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary path:(NSString *)path;

- (NSImage *)iconForObject:(SparkObject *)anObject;

- (void)setIcon:(NSImage *)icon forObject:(SparkObject *)anObject;

- (BOOL)synchronize;

@end
