//
//  SparkImporter.h
//  Spark Editor
//
//  Created by Grayfox on 8/11/2004.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CustomTableDataSource, SparkLibrary;
@interface SparkImporter : NSWindowController {
  IBOutlet id searchMenu;
  IBOutlet NSSearchField *searchField;
  IBOutlet NSObjectController *controller;
  IBOutlet CustomTableDataSource *tableController;
  
  unsigned importType;
  int _categorie;
  SparkLibrary *_library;
}

- (id)init;
- (void)setSerializedList:(id)plist;
- (void)setLibrary:(SparkLibrary *)library;

- (int)searchCategorie;
- (void)setSearchCategorie:(int)aCategorie;
@end
