/*
 *  SELibraryDocument.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkPlugIn, SparkEntry;
@class SEEntryCache, SEEntryEditor;
@class SparkLibrary, SparkApplication;
@interface SELibraryDocument : NSDocument {
  @private
  SEEntryCache *se_cache;
  SEEntryEditor *se_editor;
  
  SparkLibrary *se_library;
  SparkApplication *se_application;
}

- (SparkLibrary *)library;
- (void)setLibrary:(SparkLibrary *)aLibrary;

- (SEEntryCache *)cache;
- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

/* Entry editor */
- (void)makeEntryOfType:(SparkPlugIn *)type;
- (void)editEntry:(SparkEntry *)anEntry;

@end

SK_PRIVATE
NSString * const SEPreviousApplicationKey;
SK_PRIVATE
NSString * const SEApplicationDidChangeNotification;

SK_PRIVATE
SELibraryDocument *SEGetDocumentForLibrary(SparkLibrary *library);

@interface SELibraryDocument (SEFirstRun)
- (void)displayFirstRunIfNeeded;
@end
