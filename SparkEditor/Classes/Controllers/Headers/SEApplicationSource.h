/*
 *  SEApplicationSource.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKTableDataSource.h>

@interface SEApplicationSource : SKTableDataSource {
  IBOutlet NSWindow *libraryWindow;
  @private
  NSMutableSet *se_path;
  NSMutableSet *se_cache;
}

- (IBAction)deleteSelection:(id)sender;

@end
