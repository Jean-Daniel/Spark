//
//  SparkLibraryPrivate.h
//  SparkKit
//
//  Created by Grayfox on 01/12/07.
//  Copyright 2007 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkLibrary.h>

enum {
  kSparkListSet = 0,
  kSparkActionSet = 1,
  kSparkTriggerSet = 2,
  kSparkApplicationSet = 3,
  /* MUST be last */
  kSparkSetCount = 4,
};

@class SparkEntry;
@interface SparkLibrary (SparkLibraryInternal)

- (SparkList *)listWithUID:(SparkUID)uid;
- (SparkEntry *)entryWithUID:(SparkUID)uid;

- (SparkAction *)actionWithUID:(SparkUID)uid;
- (SparkTrigger *)triggerWithUID:(SparkUID)uid;
- (SparkApplication *)applicationWithUID:(SparkUID)uid;

@end

/* I/O */
@interface SparkLibraryArchiver : NSKeyedArchiver {
  @private
}

@end

@interface SparkLibraryUnarchiver : NSKeyedUnarchiver {
  @private
  SparkLibrary *sp_library;
}

- (id)initForReadingWithData:(NSData *)data library:(SparkLibrary *)aLibrary;

- (SparkLibrary *)library;

@end
