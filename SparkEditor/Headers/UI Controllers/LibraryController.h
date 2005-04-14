//
//  LibraryController.h
//  Spark Editor
//
//  Created by Grayfox on 17/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>
#import "CustomTableDataSource.h"

extern BOOL SearchByName(NSString *searchString, id object, void *ctxt);

@class CustomTableView, ObjectEditorController;

@interface LibraryController : NSObject {
  IBOutlet NSView *libraryView;
  IBOutlet NSSplitView *splitView;
  IBOutlet CustomTableView *listsTable;  
  IBOutlet CustomTableView *objectsTable;
  
  IBOutlet CustomTableDataSource *lists;
  IBOutlet CustomTableDataSource *objects;
  
@protected  
  SparkObjectsLibrary *_lists;
  SparkObjectsLibrary *_objects;

@private
  ObjectEditorController *_listEditor;
  ObjectEditorController *_objectEditor;

  NSArray *_nibTopLevelObjects;
  id _delegate;
  BOOL _enabled;
  BOOL _editable;
}

- (id)initWithLibraryNibNamed:(NSString *)name;

#pragma mark -
#pragma mark Configuration
- (id)listsLibrary;
- (id)objectsLibrary;
- (NSString *)dragAndDropDataType;

- (Class)listClass;
- (Class)listEditorClass;

- (Class)objectEditorClass;

- (NSString *)confirmDeleteObjectKey;

#pragma mark -
- (NSWindow *)window;
- (NSView *)libraryView;
- (void)setSearchActive:(BOOL)flag;

#pragma mark Accessors
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;
- (BOOL)isEditable;
- (void)setEditable:(BOOL)flag;
- (CustomTableView *)listsTable;
- (CustomTableView *)objectsTable;

#pragma mark Objects Manipulation
- (CustomTableDataSource *)lists;
- (SparkObjectList *)selectedList;
- (void)selectList:(SparkObjectList *)list;

- (CustomTableDataSource *)objects;
- (NSArray *)selectedObjects;
- (void)selectObjects:(NSArray *)objects;

#pragma mark Misc
- (void)refresh;

#pragma mark Workspace Save & Restore
- (void)saveWorkspaceWithKey:(NSString *)key;
- (void)restoreWorkspaceWithKey:(NSString *)key;

#pragma mark Private
- (void)displayAlert:(NSAlert *)alert confirmSelector:(SEL)aSelector argument:(id)arg;

@end

#pragma mark -
@interface LibraryController (ListsController)

- (ObjectEditorController *)listEditor;

- (IBAction)newList:(id)sender;
- (IBAction)editList:(id)sender;
- (void)removeList:(SparkObjectList *)list;
- (void)removeLists:(NSArray *)lists;

#pragma mark Table DoubleAction And Delete
- (void)deleteList:(SparkObjectList *)list;
- (IBAction)deleteSelectedList:(id)sender;
- (IBAction)listsTableDoubleAction:(id)sender;

#pragma mark Editor Delegate
- (void)createList:(SparkObjectList *)newList;
- (void)updateList:(SparkObjectList *)newList;
- (void)listEditorWillClose;

@end

#pragma mark -
@interface LibraryController (ObjectsController)

- (ObjectEditorController *)objectEditor;

- (IBAction)newObject:(id)sender;
- (IBAction)editObject:(id)sender;
- (void)removeObject:(id)object;
- (void)removeObjects:(NSArray *)objects;

#pragma mark Table DoubleAction And Delete
- (void)deleteObjects:(NSArray *)objects;
- (IBAction)deleteSelectedObjects:(id)sender;
- (IBAction)objectsTableDoubleAction:(id)sender;

#pragma mark Editor Delegate
- (void)createObject:(id)newList;
- (void)updateObject:(id)newList;
- (void)objectEditorWillClose;

@end

@interface NSObject (LibraryControllerDelegate) 
- (BOOL)libraryController:(LibraryController *)controller shouldDeleteList:(SparkObjectList *)list;
- (BOOL)libraryController:(LibraryController *)controller shouldDeleteObjects:(NSArray *)objects;

- (BOOL)libraryController:(LibraryController *)controller shouldPerformListsTableDoubleAction:(id)sender;
- (BOOL)libraryController:(LibraryController *)controller shouldPerformObjectsTableDoubleAction:(id)sender;

- (void)libraryControllerSelectedListDidChange:(NSNotification *)aNotification;
- (void)libraryControllerSelectedObjectsDidChange:(NSNotification *)aNotification;
@end