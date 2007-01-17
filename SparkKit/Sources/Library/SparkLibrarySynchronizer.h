/*
 *  SparkLibrarySynchronizer.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkLibrary.h>

@protocol SparkLibrary;
@interface SparkLibrarySynchronizer : NSObject {
  @private
  SparkLibrary *sp_library;
  NSDistantObject<SparkLibrary> *sp_remote;
}

- (id)initWithLibrary:(SparkLibrary *)aLibrary;

- (void)setDistantLibrary:(NSDistantObject<SparkLibrary> *)remoteLibrary;

@end

#pragma mark -
@interface SparkDistantLibrary : NSObject {
  @private
  id sp_delegate;
  SparkLibrary *sp_library;
}

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (SparkLibrary *)library;
- (id<SparkLibrary>)distantLibrary;

@end

@class SparkEntry;
@interface NSObject (SparkDistantLibraryDelegate)
- (void)distantLibrary:(SparkDistantLibrary *)library didAddEntry:(SparkEntry *)anEntry;
- (void)distantLibrary:(SparkDistantLibrary *)library didRemoveEntry:(SparkEntry *)anEntry;
- (void)distantLibrary:(SparkDistantLibrary *)library didChangeEntryStatus:(SparkEntry *)anEntry;
- (void)distantLibrary:(SparkDistantLibrary *)library didReplaceEntry:(SparkEntry *)anEntry withEntry:(SparkEntry *)otherEntry;
@end

@interface SparkLibrary (SparkDistantLibrary)

- (SparkDistantLibrary *)distantLibrary;

@end
