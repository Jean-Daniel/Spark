//
//  LibraryController.m
//  Spark Editor
//
//  Created by Grayfox on 17/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "LibraryController.h"

#import "CustomTableView.h"
#import "CustomTableDataSource.h"
#import "Preferences.h"
#import "ServerController.h"
#import "ListEditorController.h"


NSString * const kLibraryControllerSelectedListDidChange = @"LibraryControllerSelectedListDidChange";
NSString * const kLibraryControllerSelectedObjectsDidChange = @"LibraryControllerSelectedObjectsDidChange";
                                
@implementation LibraryController

- (void)_init {
  _editable = YES;
  _enabled = YES;
  _lists = [self listsLibrary];
  _objects = [self objectsLibrary];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(libraryDidAddList:)
                                               name:kSparkLibraryDidAddListNotification
                                             object:SparkDefaultLibrary()];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(libraryDidRemoveList:)
                                               name:kSparkLibraryDidRemoveListNotification
                                             object:SparkDefaultLibrary()];
}

- (id)init {
  if (self= [super init]) {
    [self _init];
  }
  return self;
}

- (id)initWithLibraryNibNamed:(NSString *)name {
  if (self = [super init]) {
    id nib = [[NSNib alloc] initWithNibNamed:name bundle:nil];
    [nib instantiateNibWithOwner:self topLevelObjects:&_nibTopLevelObjects];
    [_nibTopLevelObjects retain];
    [_nibTopLevelObjects makeObjectsPerformSelector:@selector(release)];
    [nib release];
    [self _init];
  }
  return self;
}

- (void)awakeFromNib {
  static BOOL loaded = NO;
  if (!loaded) {
    [listsTable setTarget:self];
    [listsTable setDoubleAction:@selector(listsTableDoubleAction:)];
    [listsTable setDelegate:self];
    [listsTable sizeLastColumnToFit];
    [listsTable setDataSource:lists];
    
    [objectsTable setTarget:self];
    [objectsTable setDoubleAction:@selector(objectsTableDoubleAction:)];
    [objectsTable setDelegate:self];
    [objectsTable sizeLastColumnToFit];
    [objectsTable setDataSource:objects];
    
    [lists setSelectsInsertedObjects:NO];
    
    id type = [self dragAndDropDataType];
    if (type) {
      [lists setPasteboardType:type];
      [objects setPasteboardType:type];
      [listsTable registerForDraggedTypes:[NSArray arrayWithObject:type]];
    }
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self setDelegate:nil];
  [_listEditor release];
  [_objectEditor release];
  [_nibTopLevelObjects release];
  [super dealloc];
}

#pragma mark -
#pragma mark Configuration
- (id)listsLibrary {
  return SparkDefaultListLibrary();
}

- (id)objectsLibrary {
  return nil;
}

- (NSString *)dragAndDropDataType {
  return nil;
}

- (Class)listEditorClass {
  return [ListEditorController class];
}

- (Class)objectEditorClass {
  return Nil;
}

- (Class)listClass {
  return Nil;
}

- (NSString *)confirmDeleteObjectKey {
  return nil;
}

#pragma mark -

- (NSWindow *)window {
  return [libraryView window];
}

- (NSView *)libraryView {
  return libraryView;
}

- (void)setSearchActive:(BOOL)flag {
  if (flag) {
    [lists setFilterFunction:SearchByName context:self];
    [objects setFilterFunction:SearchByName context:self];
  } else {
    [lists setFilterFunction:nil context:self];
    [objects setFilterFunction:nil context:self];
  }
}

#pragma mark Accessors
- (id)delegate {
  return _delegate;
}

- (void)setDelegate:(id)delegate {
  if (delegate != _delegate) {
    if (_delegate) {
      [[NSNotificationCenter defaultCenter] removeObserver:_delegate
                                                      name:nil
                                                    object:self];
    }
    _delegate = delegate;
    if (_delegate) {
      RegisterDelegateForNotification(_delegate, @selector(libraryControllerSelectedListDidChange:), kLibraryControllerSelectedListDidChange);
      RegisterDelegateForNotification(_delegate, @selector(libraryControllerSelectedObjectsDidChange:), kLibraryControllerSelectedObjectsDidChange);
    }
  }
}

- (BOOL)isEnabled {
  return _enabled;
}

- (void)setEnabled:(BOOL)flag {
  _enabled = flag;
}

- (BOOL)isEditable {
  return _editable;
}

- (void)setEditable:(BOOL)flag {
  if (_editable != flag) {
    _editable = flag;
    [libraryView setAutoresizesSubviews:NO];
    id views = [[libraryView subviews] objectEnumerator];
    id view;
    while (view = [views nextObject]) {
      NSPoint origin = [view frame].origin;
      origin.y += (_editable) ? 17 : -17;
      [view setFrameOrigin:origin];
    }
    NSRect frame = [libraryView frame];
    frame.size.height += (_editable) ? 17 : -17;
    [libraryView setFrame:frame];
    [libraryView setAutoresizesSubviews:YES];
    
    id type = (_editable) ? [self dragAndDropDataType] : nil;
    [lists setPasteboardType:type];
    [objects setPasteboardType:type];
  }
}

- (CustomTableView *)listsTable {
  return listsTable;
}
- (CustomTableView *)objectsTable {
  return objectsTable;
}

#pragma mark Objects Manipulation
- (CustomTableDataSource *)lists {
  return lists;
}
- (SparkObjectList *)selectedList {
  return [lists selectedObject];
}

- (void)selectList:(SparkObjectList *)list {
  [lists setSelectedObject:list];
}

- (CustomTableDataSource *)objects {
  return objects;
}

- (NSArray *)selectedObjects {
  return [objects selectedObjects];
}

- (void)selectObjects:(NSArray *)objectsArray {
  [lists setSelectionIndex:0];
  [objects setSelectedObjects:objectsArray];
}

#pragma mark -
#pragma mark Misc
- (void)refresh {
  [lists willChangeValueForKey:@"selection"];
  [lists didChangeValueForKey:@"selection"];
}

#pragma mark -
#pragma mark Dispatch Actions.

- (void)objectEditor:(ObjectEditorController *)editor createObject:(id)object {
  if (editor == [self listEditor]) {
    [self createList:object];
  } else if (editor == [self objectEditor]) {
    [self createObject:object];
  }
}

- (void)objectEditor:(ObjectEditorController *)editor updateObject:(id)object {
  if (editor == _listEditor) {
    [self updateList:object];
  } else if (editor == _objectEditor) {
    [self updateObject:object];
  }
}

- (void)objectEditorWillClose:(NSNotification *)aNotification {
  id editor = [aNotification object];
  if (editor == _listEditor) {
    [self listEditorWillClose];
  } else if (editor == _objectEditor) {
    [self objectEditorWillClose];
  }
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView {
  return _enabled;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  id table = [aNotification object];
  id notification = nil;
  if (table == listsTable) {
    notification = kLibraryControllerSelectedListDidChange;
  } else if (table == objectsTable) {
    notification = kLibraryControllerSelectedObjectsDidChange;
  }
  if (notification)
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:self];
}

- (void)deleteSelectionInTableView:(NSTableView *)table {
  if (_editable) {
    if (table == listsTable) {
      [self deleteSelectedList:table];
    } else if (table == objectsTable) {
      [self deleteSelectedObjects:table];
    }
  }
}
- (IBAction)search:(id)sender {
  [objects search:sender];
}

#pragma mark -
#pragma mark Dialogs
/********************************************************************
*                             Dialogs                             	*
********************************************************************/

- (void)displayAlert:(NSAlert *)alert confirmSelector:(SEL)aSelector argument:(id)arg {
  id invocaction = nil;
  if (nil != aSelector) {
    invocaction = [[NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]] retain];
    [invocaction setTarget:self];
    [invocaction setSelector:aSelector];
    if (nil != arg) {
      [invocaction setArgument:&arg atIndex:2];
      [invocaction retainArguments];
    }
  }
  [alert beginSheetModalForWindow:[self window]
                    modalDelegate:self
                   didEndSelector:@selector(alertDidEnd:returnCode:invocation:)
                      contextInfo:invocaction];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode invocation:(NSInvocation *)invocation {
  switch (returnCode) {
    case NSAlertDefaultReturn:
      [invocation invoke];
      break;
  }
  [invocation release];
}

#pragma mark -
#pragma mark Workspace Save & Restore
- (void)saveWorkspaceWithKey:(NSString *)key {
  id dico = [[NSMutableDictionary alloc] init];
  id state = [NSArray arrayWithObjects:SKUInt([lists selectionIndex]), SKUInt([objects selectionIndex]), nil];
  id sort = [NSArray arrayWithObjects:[lists sortDescriptors], [objects sortDescriptors], nil];
  id data = [[NSMutableData alloc] init];
  id archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
  [archiver encodeObject:sort forKey:@"SortOrders"];
  [archiver finishEncoding];
  [dico setObject:[NSDictionary dictionaryWithObjectsAndKeys:state, @"Selection", data, @"Descriptors", nil] forKey:@"TableViews"];
  [archiver release];
  [data release];
  [dico setObject:SKFloat([[[splitView subviews] objectAtIndex:0] frame].size.width) forKey:@"ListWidth"];
  [[NSUserDefaults standardUserDefaults] setObject:dico forKey:key];
  [dico release];
}

- (void)restoreWorkspaceWithKey:(NSString *)key {
  id workspace = [[NSUserDefaults standardUserDefaults] objectForKey:key];
  @try {
    id tablesView = [workspace objectForKey:@"TableViews"];
    id data = [tablesView objectForKey:@"Descriptors"];
    if (data) {
      id unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
      id sort = [unarchiver decodeObjectForKey:@"SortOrders"];
      [lists setSortDescriptors:[sort objectAtIndex:0]];
      [objects setSortDescriptors:[sort objectAtIndex:1]];
      [unarchiver finishDecoding];
      [unarchiver release];
    }
    NSNumber *listsWidth = [workspace objectForKey:@"ListWidth"];
    if (listsWidth) {
      NSView *listView = [[splitView subviews] objectAtIndex:0];
      NSSize size = [listView frame].size;
      size.width = MAX(80, [listsWidth floatValue]);
      [listView setFrameSize:size];
      [splitView adjustSubviews];
    }
    id state = [tablesView objectForKey:@"Selection"];
    if (state && [state count] == 2) {
      [lists setSelectionIndex:[[state objectAtIndex:0] unsignedIntValue]];
      [objects setSelectionIndex:[[state objectAtIndex:1] unsignedIntValue]];
    } else {
      [lists setSelectionIndex:0];
    }
  }
  @catch (id exception) {
    SKLogException(exception);
  }
}

#pragma mark SplitView Delegate
/************************************************************************************
*									SplitView Delegate								*
************************************************************************************/
- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset {
  return [sender frame].size.width - 150;
}
- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset {
  return 80;
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview {
  return NO;
}

@end

#pragma mark -
@implementation LibraryController (ListsController)

- (ObjectEditorController *)listEditor {
  if (nil == _listEditor) {
    _listEditor = [[[self listEditorClass] alloc] init];
    NSAssert1(_listEditor != nil, @"Invalid ListEditor Class: %@. Cannot instanciate Editor", [self listEditorClass]);
    [_listEditor setDelegate:self];
  }
  return _listEditor;
}

- (IBAction)newList:(id)sender {
  id editor = [self listEditor];
  [editor setListClass:[self listClass]];
  NSAssert(editor != nil, @"Editor cannot be nil");
  [NSApp beginSheet:[editor window]
     modalForWindow:[self window]
      modalDelegate:nil
     didEndSelector:nil
        contextInfo:nil];
}

- (IBAction)editList:(id)list {
  NSParameterAssert(list != nil);
  id editor = [self listEditor];
  NSAssert(editor != nil, @"Editor cannot be nil");
  [editor setObject:list];
  [NSApp beginSheet:[editor window]
     modalForWindow:[self window]
      modalDelegate:nil
     didEndSelector:nil
        contextInfo:nil];
}

#pragma mark -
#pragma mark Delete Methods
/*****************************************************/
- (void)removeList:(SparkObjectList *)list {
  [_lists removeObject:list];
}

- (void)removeLists:(NSArray *)listsArray {
  [_lists removeObjects:listsArray];
  [lists removeObjects:listsArray];
}

- (void)deleteList:(SparkObjectList *)list {
  BOOL delete = YES;
  if ([_delegate respondsToSelector:@selector(libraryController:shouldDeleteList:)]) {
    delete = [_delegate libraryController:self shouldDeleteList:list];
  }
  if (delete) {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kSparkPrefConfirmDeleteList]) {
      id alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"CONFIRM_DELETE_LIST",
                                                                          @"Libraries", @"LibraryController delete List")
                                 defaultButton:NSLocalizedStringFromTable(@"CONFIRM_DELETE_LIST_DELETE",
                                                                          @"Libraries", @"LibraryController delete List")
                               alternateButton:NSLocalizedStringFromTable(@"CONFIRM_DELETE_LIST_CANCEL",
                                                                          @"Libraries", @"LibraryController delete List")
                                   otherButton:nil
                     informativeTextWithFormat:NSLocalizedStringFromTable(@"CONFIRM_DELETE_LIST_MSG",
                                                                          @"Libraries", @"LibraryController delete Lists")];
      
      [alert addUserDefaultCheckBoxWithTitle:NSLocalizedStringFromTable(@"CONFIRM_DELETE_LIST_DO_NOT_SHOW_AGAIN",
                                                                        @"Libraries", @"LibraryController delete Lists")
                                      andKey:kSparkPrefConfirmDeleteList];
      [self displayAlert:alert confirmSelector:@selector(removeList:) argument:list];
    } else {
      [self removeList:list];
    }
  }
}

- (IBAction)deleteSelectedList:(id)sender {
  id list = [[sender dataSource] selectedObject];
  if ([list isCustomizable]) {
    [self deleteList:list];
  } else {
    NSBeep();
  }
}

- (IBAction)listsTableDoubleAction:(id)sender {
  if ([_delegate respondsToSelector:@selector(libraryController:shouldPerformListsTableDoubleAction:)]) {
    if (![_delegate libraryController:self shouldPerformListsTableDoubleAction:sender])
      return;
  }
  if (_editable) {
    if ([[[self window] currentEvent] type] != NSKeyDown) {
      if ([sender clickedRow] < 0) { /* Double clic on invalid line (header ...) */
        return;
      }
    }
    id list = [[sender dataSource] selectedObject];
    if (list) {
      if ([list isCustomizable]) {
        [self editList:list];
      } else {
        NSBeep();
      }
    }
  }
}

#pragma mark Editor Delegate
- (void)createList:(SparkObjectList *)newList {
  [_lists addObject:newList];
  [[self window] makeKeyAndOrderFront:nil];
  [lists setSelectedObject:newList];
}

- (void)updateList:(SparkObjectList *)list {
  [[NSNotificationCenter defaultCenter] postNotificationName:kSparkListDidChangeNotification object:list];
}

- (void)listEditorWillClose {
  [_listEditor autorelease];
  _listEditor = nil;
}

#pragma mark SparkListLibrary Notifications
- (void)libraryDidAddList:(NSNotification *)aNotification {
  id list = SparkNotificationObject(aNotification);
  if ([list class] == [self listClass]) {
    [lists addObject:list];
    [lists rearrangeObjects];
  }
}

- (void)libraryDidRemoveList:(NSNotification *)aNotification {
  id list = SparkNotificationObject(aNotification);
  [lists removeObject:list];
}

@end

#pragma mark -
@implementation LibraryController (ObjectsController)

- (ObjectEditorController *)objectEditor {
  if (nil == _objectEditor) {
    _objectEditor = [[[self objectEditorClass] alloc] init];
    NSAssert1(_objectEditor != nil, @"Invalid ObjectEditor Class: %@. Cannot instanciate Editor", [self objectEditorClass]);
    [_objectEditor setDelegate:self];
  }
  return _objectEditor;
}

#pragma mark Actions Manipulation
- (IBAction)newObject:(id)sender {
  id editor = [self objectEditor];
  NSAssert(editor != nil, @"Editor cannot be nil.");
  [NSApp beginSheet:[editor window]
     modalForWindow:[self window]
      modalDelegate:nil
     didEndSelector:nil
        contextInfo:nil];
}

- (void)editObject:(id<SparkLibraryObject>)object {
  if ([[object uid] unsignedIntValue] == 0) {
    NSBeep();
    return;
  }
  id editor = [self objectEditor];
  NSAssert(editor != nil, @"Editor cannot be nil.");
  [editor setObject:object];
  [NSApp beginSheet:[editor window]
     modalForWindow:[self window]
      modalDelegate:nil
     didEndSelector:nil
        contextInfo:nil];
}

- (void)removeObject:(id)object {
  if ([[object uid] unsignedIntValue] == 0) {
    NSBeep();
  } else {
    [lists willChangeValueForKey:@"selection"];
    [_objects removeObject:object];
    [lists didChangeValueForKey:@"selection"];
  }
}

- (void)removeObjects:(NSArray *)objectsArray {
  id selection = [objectsArray mutableCopy];
  id systemObject = [[self objectsLibrary] objectWithId:SKUInt(0)];
  if (systemObject) {
    [selection removeObject:systemObject];
  }
  if ([selection count]) {
    [lists willChangeValueForKey:@"selection"];
    [_objects removeObjects:selection];
    [lists didChangeValueForKey:@"selection"];
  }
  [selection release];
}

#pragma mark Table DoubleAction And Delete
- (IBAction)objectsTableDoubleAction:(id)sender {
  if ([_delegate respondsToSelector:@selector(libraryController:shouldPerformObjectsTableDoubleAction:)]) {
    if (![_delegate libraryController:self shouldPerformObjectsTableDoubleAction:sender])
      return;
  }
  if (_editable) {
    if ([[[self window] currentEvent] type] != NSKeyDown) {
      if ([sender clickedRow] < 0) { /* Double clic on invalid line (header ...) */
        return;
      }
    }
    int index;
    switch ([sender numberOfSelectedRows]) {
      case 0:
        index = -1;
        break;
      case 1:
        index = [[sender dataSource] selectionIndex];
        break;
      default:
        index = [sender clickedRow];
    }
    if (index < 0) {
      NSBeep();
    } else {
      id object = [[[sender dataSource] arrangedObjects] objectAtIndex:index];
      [self editObject:object];
    }
  }
}

- (IBAction)deleteSelectedObjects:(id)sender {
  id objectsArray = [[sender dataSource] selectedObjects];
  id systemObject = [[self objectsLibrary] objectWithId:SKUInt(0)];
  if (systemObject && ![[self selectedList] isEditable]) {
    [objectsArray removeObject:systemObject];
  }
  if ([objectsArray count] > 0) {
    [self deleteObjects:objectsArray];
  } else {
    NSBeep();
  }
}

- (void)deleteObjects:(NSArray *)objectsArray {
  BOOL delete = YES;
  if ([_delegate respondsToSelector:@selector(libraryController:shouldDeleteObjects:)]) {
    delete = [_delegate libraryController:self shouldDeleteObjects:objectsArray];
  }
  if (delete) {
    id list = [lists selectedObject];
    if ([list isEditable]) {
      id msg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"CONFIRM_REMOVE_OBJECT_FROM_LIST",
                                                                     @"Libraries", @"LibraryController - Delete Items From List"), [list name]];
      id alert = [NSAlert alertWithMessageText:msg
                                 defaultButton:NSLocalizedStringFromTable(@"CONFIRM_REMOVE_OBJECT_FROM_LIST_REMOVE",
                                                                          @"Libraries", @"LibraryController - Delete Items From List")
                               alternateButton:NSLocalizedStringFromTable(@"CONFIRM_REMOVE_OBJECT_FROM_LIST_CANCEL",
                                                                          @"Libraries", @"LibraryController - Delete Items From List")
                                   otherButton:NSLocalizedStringFromTable(@"CONFIRM_REMOVE_OBJECT_FROM_LIST_DELETE",
                                                                          @"Libraries", @"LibraryController - Delete Items From List")
                     informativeTextWithFormat:@""];
      [alert beginSheetModalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(deleteFromListDidEnd:returnCode:list:)
                          contextInfo:list];
    } else {
      id key = [self confirmDeleteObjectKey];
      if (key && ![[NSUserDefaults standardUserDefaults] boolForKey:key]) {
        id alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"CONFIRM_DELETE_SELECTED_OBJECTS",
                                                                            @"Libraries", @"LibraryController - Delete Items")
                                   defaultButton:NSLocalizedStringFromTable(@"CONFIRM_DELETE_SELECTED_OBJECTS_DELETE",
                                                                            @"Libraries", @"LibraryController - Delete Items")
                                 alternateButton:NSLocalizedStringFromTable(@"CONFIRM_DELETE_SELECTED_OBJECTS_CANCEL",
                                                                            @"Libraries", @"LibraryController - Delete Items")
                                     otherButton:nil
                       informativeTextWithFormat:NSLocalizedStringFromTable(@"CONFIRM_DELETE_SELECTED_OBJECTS_MSG",
                                                                            @"Libraries", @"LibraryController - Delete Items")];
        
        [alert addUserDefaultCheckBoxWithTitle:NSLocalizedStringFromTable(@"CONFIRM_DELETE_SELECTED_OBJECTS_DO_NOT_SHOW_AGAIN",
                                                                          @"Libraries", @"LibraryController - Delete Items")
                                        andKey:key];
        [self displayAlert:alert confirmSelector:@selector(removeObjects:) argument:objectsArray];
      } else {
        [self removeObjects:objectsArray];
      }
    }
  }
}

- (void)deleteFromListDidEnd:(NSWindow *)sheet returnCode:(int)returnCode list:(SparkObjectList *)list {
  id systemObject = nil;
  id selection;
  switch (returnCode) {
    case NSAlertDefaultReturn:
      [list removeObjects:[self selectedObjects]];
      break;
    case NSAlertOtherReturn:
      systemObject = [[self objectsLibrary] objectWithId:SKUInt(0)];
      selection = [[self selectedObjects] mutableCopy];
      if (systemObject && [selection containsObject:systemObject]) {
        [list removeObject:systemObject];
      }
      [self removeObjects:selection];
      [selection release];
      break;
  }
}

#pragma mark Editor Delegate
- (void)createObject:(id)object {
  [lists willChangeValueForKey:@"selection"];
  if ([_objects addObject:object]) {
    SparkObjectList *list = [self selectedList];
    if ([list isEditable] && [object isKindOfClass:[list contentType]]) {
      [list addObject:object];
    }
    [objects setSelectedObject:object];
  }
  [lists didChangeValueForKey:@"selection"];
}

- (void)updateObject:(id)object {
  if ([[objects arrangedObjects] containsObject:object])
    [objects rearrangeObjects];
}

- (void)objectEditorWillClose {
  [_objectEditor autorelease];
  _objectEditor = nil;
}

@end
/* Standard Filter Function (cf CustomTableDataSource) */
BOOL SearchByName(NSString *searchString, id object, void *context) {
  return (searchString) ? [[object name] rangeOfString:searchString options:NSCaseInsensitiveSearch/*  | NSAnchoredSearch*/].location != NSNotFound : YES;
}
