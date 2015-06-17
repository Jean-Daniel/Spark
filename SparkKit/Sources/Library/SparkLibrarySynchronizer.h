/*
 *  SparkLibrarySynchronizer.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkLibrary.h>

SPARK_EXPORT
bool SparkLogSynchronization;

@protocol SparkLibrary;

SPARK_OBJC_EXPORT
@interface SparkLibrarySynchronizer : NSObject

- (instancetype)initWithLibrary:(SparkLibrary *)aLibrary;

- (void)setDistantLibrary:(NSDistantObject<SparkLibrary> *)remoteLibrary;

@end

#pragma mark -
SPARK_OBJC_EXPORT
@interface SparkDistantLibrary : NSObject

@property(nonatomic, readonly) SparkLibrary *library;
@property(nonatomic, readonly) id<SparkLibrary> distantLibrary;

@end

@interface SparkLibrary (SparkDistantLibrary)

@property(nonatomic, readonly) SparkDistantLibrary *distantLibrary;

@end
