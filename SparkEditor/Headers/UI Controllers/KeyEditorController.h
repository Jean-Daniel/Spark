//
//  KeyEditorController.h
//  Spark
//
//  Created by Fox on Sat Dec 13 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
#import <SparkKit/SparkKit.h>
#import "ObjectEditorController.h"

@class ActionEditor, CustomTableDataSource;
@interface KeyEditorController : ObjectEditorController {
  IBOutlet id toolbar, tabView; /* The CutomsToolbar & TabView contening the differents panels */
  IBOutlet id advancedButton;
  IBOutlet NSButton *helpButton;
  
  IBOutlet NSView *actionView;
  IBOutlet ActionEditor *actionEditor;
  
  IBOutlet NSTableView *mapTable;
  IBOutlet CustomTableDataSource *mapArray;
  IBOutlet NSObjectController *objectController;

  NSString *_keyName;
  NSString *_keyComment;
  
  SparkHotKey *_hotKey;
    
  BOOL _advanced;
  id editedObject;
  
  /* Use to store size when changing view */
  struct {
    NSSize minSize;
    NSSize currentSize;
    NSSize maxSize;
  } windowState[3];
  NSMutableDictionary *_actionsSizes;
}

- (IBAction)changeTab:(id)sender;

- (IBAction)create:(id)sender;
- (IBAction)update:(id)sender;
- (IBAction)toggleAdvancedModeView:(id)sender;

- (IBAction)deleteApplications:(id)sender;

- (BOOL)checkHotKey;
- (BOOL)configureHotKey;

- (id)object;
- (void)setObject:(id)anObject;

- (SparkPlugIn *)selectedPlugin;
- (void)selectActionPlugin:(SparkPlugIn *)plugin;

- (NSString *)keyName;
- (void)setKeyName:(NSString *)keyName;

- (NSString *)keyComment;
- (void)setKeyComment:(NSString *)keyComment;

- (NSString *)shortCut;

@end
