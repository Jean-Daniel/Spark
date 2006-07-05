//
//  SparkLibrary.h
//  SparkKit
//
//  Created by Grayfox on 18/11/2004.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>
#import <ShadowKit/SKCArray.h>

SPARK_EXPORT
NSPropertyListFormat SparkLibraryFileFormat;

SPARK_EXPORT
NSString * const kSparkLibraryFileExtension;

#pragma mark -
@class SparkLibrary, SparkObjectsLibrary;

SPARK_EXPORT
NSString *SparkLibraryFolder();

SPARK_EXPORT
SparkLibrary *SparkSharedLibrary();

SPARK_EXPORT
SparkObjectsLibrary *SparkSharedActionLibrary();

SPARK_EXPORT
SparkObjectsLibrary *SparkSharedTriggerLibrary();

SPARK_EXPORT
SparkObjectsLibrary *SparkSharedApplicationLibrary();

#pragma mark -
@interface SparkLibrary : NSObject {
@private
  UInt32 sp_version;
  NSString *sp_file;
  SKCArrayRef sp_relations;
  NSMutableDictionary *sp_libraries;
}

+ (SparkLibrary *)sharedLibrary;

- (id)initWithPath:(NSString *)path;

- (NSString *)path;
- (void)setPath:(NSString *)file;

- (SparkObjectsLibrary *)actionLibrary;
- (SparkObjectsLibrary *)triggerLibrary;
- (SparkObjectsLibrary *)applicationLibrary;

- (BOOL)synchronize;
- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag;

- (NSFileWrapper *)fileWrapper:(NSError **)outError;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)outError;

@end
