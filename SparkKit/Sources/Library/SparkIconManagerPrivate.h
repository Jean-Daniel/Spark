/*
 *  SparkIconManagerPrivate.h
 *  SparkKit
 *
 *  Created by Grayfox on 24/02/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkIconManager.h>

@interface _SparkIconEntry : NSObject {
  BOOL sp_clean;
  BOOL sp_loaded;
  
  @private
    NSImage *sp_icon;
  NSString *sp_path;
  NSImage *sp_ondisk;
}

- (BOOL)loaded;
- (BOOL)hasChanged;
- (void)applyChange;

- (id)initWithObject:(SparkObject *)object;
- (id)initWithObjectType:(NSUInteger)type uid:(SparkUID)anUID;

- (NSString *)path;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)anImage;

- (void)setCachedIcon:(NSImage *)anImage;

@end

@interface SparkIconManager (SparkPrivate)

- (_SparkIconEntry *)entryForObject:(SparkObject *)anObject;
- (_SparkIconEntry *)entryForObjectType:(UInt8)type uid:(SparkUID)anUID;

@end
