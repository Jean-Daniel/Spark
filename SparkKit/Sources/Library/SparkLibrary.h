/*
 *  SparkLibrary.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkKit.h>
#import <ShadowKit/SKCArray.h>

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
@class SparkLibrary, SparkObjectsLibrary;

SPARK_EXPORT
SparkLibrary *SparkSharedLibrary(void);

SPARK_EXPORT
SparkObjectsLibrary *SparkSharedActionLibrary(void);

SPARK_EXPORT
SparkObjectsLibrary *SparkSharedTriggerLibrary(void);

SPARK_EXPORT
SparkObjectsLibrary *SparkSharedApplicationLibrary(void);

typedef struct _SparkEntry {
  UInt32 action;
  UInt32 trigger;
  UInt32 application;
} SparkEntry;

#pragma mark -
@class SparkApplication;
@interface SparkLibrary : NSObject {
@private
  NSString *sp_file;
  SKCArrayRef sp_relations;
  NSMutableDictionary *sp_libraries;
}

+ (SparkLibrary *)sharedLibrary;

- (id)initWithPath:(NSString *)path;

- (NSString *)path;
- (void)setPath:(NSString *)file;

- (BOOL)readLibrary:(NSError **)error;

- (SparkObjectsLibrary *)actionLibrary;
- (SparkObjectsLibrary *)triggerLibrary;
- (SparkObjectsLibrary *)applicationLibrary;

- (BOOL)synchronize;
- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag;

- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;

/* Library Queries */
- (NSDictionary *)triggersForApplication:(UInt32)application;

@end

