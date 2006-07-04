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

SPARK_EXPORT
const UInt32 kSparkLibraryCurrentVersion;

//@class SparkObjectsLibrary, SparkKeyLibrary, SparkListLibrary, SparkActionLibrary, SparkApplicationLibrary;
@interface SparkLibrary : NSObject {
@private
  UInt32 sp_version;
  NSString *sp_file;
  SKCArrayRef sp_relations;
  NSMutableDictionary *sp_libraries;
}

+ (SparkLibrary *)sharedLibrary;

- (id)initWithPath:(NSString *)path;

//- (BOOL)load;
//- (BOOL)reload;
//
//- (void)importsObjectsFromLibrary:(SparkLibrary *)aLibrary;

- (NSString *)path;
- (void)setPath:(NSString *)file;

//- (SparkKeyLibrary *)keyLibrary;
//- (SparkListLibrary *)listLibrary;
//- (SparkActionLibrary *)actionLibrary;
//- (SparkApplicationLibrary *)applicationLibrary;

//- (void)flush; /* WARNING: Delete Library Contents */
//- (BOOL)synchronize;
//- (NSFileWrapper *)fileWrapper;
//- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag;

@end

#pragma mark -
SPARK_EXPORT
NSString *SparkLibraryFolder();

SPARK_EXPORT
SparkLibrary *SparkSharedLibrary();

SPARK_EXPORT
SparkActionLibrary *SparkSharedActionLibrary();

SPARK_EXPORT
SparkTriggerLibrary *SparkSharedTriggerLibrary();

SPARK_EXPORT
SparkApplicationLibrary *SparkSharedApplicationLibrary();
