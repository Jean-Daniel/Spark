//
//  KeyLibraryController.h
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "LibraryController.h"
#import <SparkKit/SparkKit.h>

extern NSString * const kSparkHotKeyPBoardType;

@class KeyWarningList;
#pragma mark -
@interface KeyLibraryController : LibraryController {
  IBOutlet id menu;
  KeyWarningList *_warningList;
  NSMutableArray *_pluginsLists;
}

- (NSArray *)pluginsLists;

- (void)loadLibrary;
- (void)reloadLibrary;
- (void)selectObject:(id)object;
- (void)newObjectOfKind:(SparkPlugIn *)kind;

@end

@interface CheckActiveSparkHotKey : SparkHotKey {
}

@end