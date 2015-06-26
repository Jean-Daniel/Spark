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

@interface _SparkIconEntry : NSObject

- (instancetype)initWithObject:(SparkObject *)object;
- (instancetype)initWithObjectType:(NSUInteger)type uid:(SparkUID)anUID;

- (BOOL)loaded;
- (BOOL)hasChanged;
- (void)applyChange;

@property(nonatomic, readonly) NSString *path;

@property(nonatomic, retain) NSImage *icon;

- (void)setCachedIcon:(NSImage *)anImage;

@end

@interface SparkIconManager ()

- (_SparkIconEntry *)entryForObject:(SparkObject *)anObject;
- (_SparkIconEntry *)entryForObjectType:(UInt8)type uid:(SparkUID)anUID;

- (void)enumerateEntries:(uint8_t)type usingBlock:(void (^)(SparkUID uid, _SparkIconEntry *icon, BOOL *stop))block;

@end
