/*
 *  SEApplicationSource.h
 *  Spark Editor
 *
 *  Created by Grayfox on 29/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
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
