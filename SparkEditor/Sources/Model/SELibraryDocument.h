/*
 *  SELibraryDocument.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SEEntryCache;
@class SparkLibrary, SparkApplication;
@interface SELibraryDocument : NSDocument {
  @private
  SEEntryCache *se_cache;
  SparkLibrary *se_library;
  SparkApplication *se_application;
}

- (SparkLibrary *)library;
- (void)setLibrary:(SparkLibrary *)aLibrary;

- (SEEntryCache *)cache;
- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

@end

SK_PRIVATE
NSString * const SEApplicationDidChangeNotification;


@interface SELibraryDocument (SEFirstRun)
- (void)displayFirstRunIfNeeded;
@end
