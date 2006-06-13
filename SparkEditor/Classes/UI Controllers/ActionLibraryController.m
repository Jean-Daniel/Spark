//
//  ActionLibraryController.m
//  Spark Editor
//
//  Created by Grayfox on 17/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "ActionLibraryController.h"

#import "ActionEditorController.h"
#import "TableAlertController.h"
#import "ActionLibraryList.h"
#import "ActionPlugInList.h"
#import "Preferences.h"

NSString * const kSparkActionPBoardType = @"SparkActionPBoardType";
static NSComparisonResult CompareActionList(id object1, id object2, void *context);

@implementation ActionLibraryController

- (id)init {
  if (self = [super initWithLibraryNibNamed:@"ActionLibrary"]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sparkDidAddPlugin:)
                                                 name:SKPluginLoaderDidLoadPluginNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_actionsLists release];
  [super dealloc];
}

#pragma mark -
#pragma mark Configuration

- (id)objectsLibrary {
  return SparkDefaultActionLibrary();
}

- (Class)objectEditorClass {
  return [ActionEditorController class];
}

- (NSString *)dragAndDropDataType {
  return kSparkActionPBoardType;
}

- (Class)listClass {
  return [SparkActionList class];
}

- (NSString *)confirmDeleteObjectKey {
  return kSparkPrefConfirmDeleteAction;
}

#pragma mark -

- (void)reloadLibrary {
  unsigned idx = [lists selectionIndex];
  [lists removeAllObjects];
  [lists addObject:[ActionLibraryList list]];
  [lists addObjects:[self actionsLists]];
  [lists addObjects:[SparkDefaultListLibrary() listsWithContentType:[SparkAction class]]];
  if ([[lists arrangedObjects] count] > idx) [lists setSelectionIndex:idx];
  [self refresh];
}

- (void)awakeFromNib {
  [super awakeFromNib];
  [lists setCompareFunction:CompareActionList];
  [self reloadLibrary];
  [lists setSelectionIndex:0];
}

- (NSArray *)actionsLists {
  if (nil == _actionsLists) {
    _actionsLists = [[NSMutableArray alloc] init];
    id plugins = [[[SparkActionLoader sharedLoader] plugins] objectEnumerator];
    id plugin;
    while (plugin = [plugins nextObject]) {
      id list = [[ActionPlugInList alloc] initWithPlugIn:plugin];
      [_actionsLists addObject:list];
      [list release];
    }
  }
  return _actionsLists;
}

- (IBAction)listsTableDoubleAction:(id)sender {
  if ([self isEditable]) {
    if ([[[self window] currentEvent] type] != NSKeyDown) {
      if ([sender clickedRow] < 0) { /* Double clic on invalid line (header ...) */
        return;
      }
    }
    id list = [[sender dataSource] selectedObject];
    if (list && [[self actionsLists] containsObject:list]) {
      [self newObject:sender];
    } else {
      [super listsTableDoubleAction:sender];
    }
  } else {
    [super listsTableDoubleAction:sender];
  }
}

- (IBAction)newObject:(id)sender {
  id editor = [self objectEditor];
  id list = [self selectedList];
  if ([[self actionsLists] containsObject:list]) {
    [editor selectActionPlugin:[list plugIn]];
  } else {
    [editor selectActionPlugin:nil];
  }
  [super newObject:sender];
}

- (void)updateObject:(SparkAction *)action {
  [super updateObject:action];
}

- (void)removeObjects:(NSArray *)objectsArray {
  NSMutableArray *actionsToDelete = nil;
  NSMutableArray *usedActions = [[NSMutableArray alloc] init];
  NSMutableSet *usedKeys = [[NSMutableSet alloc] init];
  
  id items = [objectsArray objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    if ([[item uid] unsignedIntValue]) { 
      NSSet *keys = [SparkDefaultKeyLibrary() keysUsingAction:item];
      if ([keys count]) {
        [usedActions addObject:item];
        [usedKeys addObjectsFromArray:[keys allObjects]];
      }
    }
  }
  if ([usedKeys count]) {
    id alert = [[TableAlertController alloc] init];
    [alert setValues:[usedKeys allObjects]];
    [alert setTitle:NSLocalizedStringFromTable(@"CONFIRM_DELETE_USED_ACTIONS",
                                               @"Libraries", @"Delete Action Affect keys warning")];
    int result = [NSApp runModalForWindow:[alert window]];
    [alert release];
    if (result == NSAlertAlternateReturn) { /* Cancel */
      actionsToDelete = nil;
    } else if (result == NSAlertDefaultReturn) { /* Delete Unsued */
      actionsToDelete = [objectsArray mutableCopy];
      [actionsToDelete removeObjectsInArray:usedActions];
    } else { /* Delete All */
      actionsToDelete = [objectsArray retain];
    }
  } else {
    actionsToDelete = [objectsArray retain];
  }
  if (actionsToDelete) {
    [super removeObjects:actionsToDelete];
    [actionsToDelete release];
  }
  [usedActions release];
  [usedKeys release];
}

- (void)createObject:(id)object {
  [object setCustom:YES];
  [super createObject:object];
}

/*****************************************************/
#pragma mark -
#pragma mark Dynamic Plugin Loading.
- (void)sparkDidAddPlugin:(NSNotification *)notification {
  SparkPlugIn *plugin = [notification object];
  Class newClass = [plugin principalClass];
  id items = [[self actionsLists] objectEnumerator];
  id list;
  while (list = [items nextObject]) {
    if ([list respondsToSelector:@selector(plugIn)] && [[list plugIn] principalClass] == newClass)
      return;
  }
  list = [ActionPlugInList listWithPlugIn:plugin];
  if (list) {
    [_actionsLists addObject:list];
    [self reloadLibrary];
  }
}

@end

#pragma mark -
static NSComparisonResult CompareActionList(id object1, id object2, void *context) {
  if ([object1 class] == [object2 class]) {
    return [[object1 name] caseInsensitiveCompare:[object2 name]];
  }
  
  //La Bibliothèque passe en premier 
  if ([object1 isMemberOfClass:[ActionLibraryList class]]) {
    return NSOrderedAscending;
  } else if ([object2 isMemberOfClass:[ActionLibraryList class]]) {
    return NSOrderedDescending;
  }
  if ([object1 isMemberOfClass:[ActionPlugInList class]]) {
    return NSOrderedAscending;
  } else if ([object2 isMemberOfClass:[ActionPlugInList class]]) {
    return NSOrderedDescending;
  }
  return NSOrderedSame;
}