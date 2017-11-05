/*
 *  SparkLibraryArchive.h
 *  SparkKit
 *
 *  Created by Grayfox on 24/02/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkLibrary.h>

SPARK_EXPORT
const OSType kSparkLibraryArchiveHFSType;
SPARK_EXPORT
NSString * const kSparkLibraryArchiveExtension;

@interface SparkLibrary (SparkArchiveExtension)

- (instancetype)initFromArchiveAtURL:(NSURL *)url;
- (instancetype)initFromArchiveAtURL:(NSURL *)url loadPreferences:(BOOL)flag;

- (BOOL)archiveToURL:(NSURL *)url;

@end
