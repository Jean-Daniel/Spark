/*
 *  SparkLibrary.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkKit.h>

SPARK_EXPORT
NSPropertyListFormat SparkLibraryFileFormat;

SPARK_EXPORT
NSString * const kSparkLibraryFileExtension;

SPARK_EXPORT
NSString * const kSparkLibraryDefaultFileName;

SPARK_EXPORT
NSString *SparkLibraryFolder(void);

SK_INLINE 
NSString *SparkSharedLibraryPath(void) {
  return [SparkLibraryFolder() stringByAppendingPathComponent:kSparkLibraryDefaultFileName];
}

enum {
  kSparkLibraryReserved = 0xff
};

#pragma mark -
@class SparkLibrary, SparkObjectSet, SparkEntryManager;

SPARK_EXPORT
SparkLibrary *SparkSharedLibrary(void);
SPARK_EXPORT
SparkEntryManager *SparkSharedManager(void);

SPARK_EXPORT
SparkObjectSet *SparkSharedListSet(void);
SPARK_EXPORT
SparkObjectSet *SparkSharedActionSet(void);
SPARK_EXPORT
SparkObjectSet *SparkSharedTriggerSet(void);
SPARK_EXPORT
SparkObjectSet *SparkSharedApplicationSet(void);

#pragma mark -
@class SparkApplication, SparkEntryManager;
@interface SparkLibrary : NSObject {
  @private
  NSString *sp_file;
  
  SparkObjectSet *sp_objects[4];
  SparkEntryManager *sp_relations;
}

+ (SparkLibrary *)sharedLibrary;

- (id)initWithPath:(NSString *)path;

- (NSString *)path;
- (void)setPath:(NSString *)file;

- (NSUndoManager *)undoManager;

- (BOOL)readLibrary:(NSError **)error;

- (SparkObjectSet *)actionSet;
- (SparkObjectSet *)triggerSet;
- (SparkObjectSet *)applicationSet;

- (SparkEntryManager *)entryManager;
   
- (BOOL)synchronize;
- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag;

- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;

@end

#pragma mark Debugger
SPARK_EXPORT
void SparkDumpTriggers(SparkLibrary *aLibrary);
