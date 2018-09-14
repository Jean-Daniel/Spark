/*
 *  SELibraryDocument.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

@class SELibraryWindow;
@class SparkPlugIn, SparkEntry;
@class SparkLibrary, SparkApplication;

@interface SELibraryDocument : NSDocument

@property(nonatomic, retain) SparkLibrary *library;

@property(nonatomic, retain) SparkApplication *application;

@property(nonatomic, readonly) SELibraryWindow *mainWindowController;

/* Entry editor */
- (void)makeEntryOfType:(SparkPlugIn *)type;
- (void)editEntry:(SparkEntry *)anEntry;

- (void)revertToBackup:(NSURL *)archive;

- (NSUInteger)removeEntriesInArray:(NSArray *)entries;

@end

SPARK_PRIVATE
NSString * const SEPreviousApplicationKey;
SPARK_PRIVATE
NSString * const SEApplicationDidChangeNotification;
SPARK_PRIVATE
NSString * const SEDocumentDidSetLibraryNotification;
SPARK_PRIVATE
NSString * const SELibraryDocumentDidReloadNotification;

SPARK_PRIVATE
SELibraryDocument *SEGetDocumentForLibrary(SparkLibrary *library);

@interface SELibraryDocument (SEFirstRun)
- (void)displayFirstRunIfNeeded;
@end
