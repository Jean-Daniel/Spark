/*
 *  SELibraryDocument.h
 *  Spark Editor
 *
 *  Created by Grayfox on 14/01/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkLibrary, SparkApplication;
@interface SELibraryDocument : NSDocument {
  @private
  id se_manager; /* deprecated */
  SparkLibrary *se_library;
  SparkApplication *se_application;
}

- (SparkLibrary *)library;
- (void)setLibrary:(SparkLibrary *)aLibrary;

- (id)manager;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

@end

SK_PRIVATE
NSString * const SEApplicationDidChangeNotification;
