/*
 *  SETriggerBrowser.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SKTableDataSource;
@class SKTableView, SparkLibrary;
@interface SETriggerBrowser : NSWindowController {
  IBOutlet SKTableView *uiTriggers;
  IBOutlet SKTableDataSource *ibTriggers;
  @private
    SparkLibrary *se_library;
}

- (void)setLibrary:(SparkLibrary *)aLibrary;

@end
