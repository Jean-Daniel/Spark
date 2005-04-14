//
//  SparkLibrary.h
//  SparkKit
//
//  Created by Grayfox on 18/11/2004.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SparkKit/SparkKitBase.h>

SPARK_EXPORT
NSString * const kSparkLibraryFileExtension;

SPARK_EXPORT
const unsigned int kSparkLibraryCurrentVersion;

SPARK_EXPORT
NSPropertyListFormat SparkLibraryFileFormat;

@class SparkObjectsLibrary, SparkKeyLibrary, SparkListLibrary, SparkActionLibrary, SparkApplicationLibrary;
@interface SparkLibrary : NSObject {
@private
  NSString *_filename;
  unsigned int	_version;
  NSMutableDictionary *_libraries;
}

+ (SparkLibrary *)defaultLibrary;
+ (void)setDefaultLibrary:(SparkLibrary *)aLibrary;

- (id)initWithPath:(NSString *)path;

- (BOOL)load;
- (BOOL)reload;

- (void)importsObjectsFromLibrary:(SparkLibrary *)aLibrary;

- (NSString *)file;
- (void)setFile:(NSString *)file;

- (SparkKeyLibrary *)keyLibrary;
- (SparkListLibrary *)listLibrary;
- (SparkActionLibrary *)actionLibrary;
- (SparkApplicationLibrary *)applicationLibrary;

- (void)flush; /* WARNING: Delete Library Contents */
- (BOOL)synchronize;
- (NSFileWrapper *)fileWrapper;
- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)flag;

@end

#pragma mark -
SPARK_EXPORT
NSString *SparkLibraryFolder();

SPARK_EXTERN_INLINE
SparkLibrary *SparkDefaultLibrary();

SPARK_EXTERN_INLINE
SparkKeyLibrary *SparkDefaultKeyLibrary();

SPARK_EXTERN_INLINE
SparkListLibrary *SparkDefaultListLibrary();

SPARK_EXTERN_INLINE
SparkActionLibrary *SparkDefaultActionLibrary();

SPARK_EXTERN_INLINE
SparkApplicationLibrary *SparkDefaultApplicationLibrary();
