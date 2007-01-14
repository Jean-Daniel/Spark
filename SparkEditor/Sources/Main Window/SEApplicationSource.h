/*
 *  SEApplicationSource.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKTableDataSource.h>

@class SELibraryWindow, SparkLibrary;
@interface SEApplicationSource : SKTableDataSource {
  IBOutlet SELibraryWindow *ibWindow;
  @private
  NSMutableSet *se_path;
  SparkLibrary *se_library;
}

- (IBAction)deleteSelection:(id)sender;

@end
