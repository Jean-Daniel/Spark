/*
 *  SparkLibraryArchive.h
 *  SparkKit
 *
 *  Created by Grayfox on 24/02/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkLibrary.h>

SK_EXPORT 
const OSType kSparkLibraryArchiveHFSType;
SK_EXPORT
NSString * const kSparkLibraryArchiveExtension;

@interface SparkLibrary (SparkArchiveExtension)

- (id)initFromArchiveAtPath:(NSString *)file;
- (id)initFromArchiveAtPath:(NSString *)file loadPreferences:(BOOL)flag;

- (BOOL)archiveToFile:(NSString *)file;

@end
