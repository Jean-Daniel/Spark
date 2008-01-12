/*
 *  SELibraryDocument.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

@class SparkPlugIn, SparkEntry;
@class SparkLibrary, SparkApplication;
@class SEEntryEditor, SELibraryWindow;
@interface SELibraryDocument : NSDocument {
  @private
  SEEntryEditor *se_editor;
  
  SparkLibrary *se_library;
  SparkApplication *se_application;
}

- (SparkLibrary *)library;
- (void)setLibrary:(SparkLibrary *)aLibrary;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

- (SELibraryWindow *)mainWindowController;

/* Entry editor */
- (void)makeEntryOfType:(SparkPlugIn *)type;
- (void)editEntry:(SparkEntry *)anEntry;

- (void)revertToBackup:(NSString *)file;

- (NSUInteger)removeEntriesInArray:(NSArray *)entries;

@end

WB_PRIVATE
NSString * const SEPreviousApplicationKey;
WB_PRIVATE
NSString * const SEApplicationDidChangeNotification;
WB_PRIVATE
NSString * const SEDocumentDidSetLibraryNotification;
WB_PRIVATE
NSString * const SELibraryDocumentDidReloadNotification;

WB_PRIVATE
SELibraryDocument *SEGetDocumentForLibrary(SparkLibrary *library);

@interface SELibraryDocument (SEFirstRun)
- (void)displayFirstRunIfNeeded;
@end
