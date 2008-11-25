/*
 *  SparkLibrarySynchronizer.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkLibrary.h>

WB_EXPORT
BOOL SparkLogSynchronization;

@protocol SparkLibrary;
WB_CLASS_EXPORT
@interface SparkLibrarySynchronizer : NSObject {
  @private
  SparkLibrary *sp_library;
  NSDistantObject<SparkLibrary> *sp_remote;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary;

- (void)setDistantLibrary:(NSDistantObject<SparkLibrary> *)remoteLibrary;

@end

#pragma mark -
WB_CLASS_EXPORT
@interface SparkDistantLibrary : NSObject {
  @private
  SparkLibrary *sp_library;
}

- (SparkLibrary *)library;
- (id<SparkLibrary>)distantLibrary;

@end

@interface SparkLibrary (SparkDistantLibrary)

- (SparkDistantLibrary *)distantLibrary;

@end
