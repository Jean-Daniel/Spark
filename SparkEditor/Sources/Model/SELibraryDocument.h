/*
 *  SELibraryDocument.h
 *  Spark Editor
 *
 *  Created by Grayfox on 14/01/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkLibrary, SEEntriesManager;
@interface SELibraryDocument : NSDocument {
  @private
  SparkLibrary *se_library;
  SEEntriesManager *se_manager;
}

- (SparkLibrary *)library;
- (void)setLibrary:(SparkLibrary *)aLibrary;

- (SEEntriesManager *)manager;

@end
