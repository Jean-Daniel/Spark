//
//  ApplicationLibraryController.m
//  Spark Editor
//
//  Created by Grayfox on 17/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "ApplicationLibraryController.h"

#import <SparkKit/SparkKit.h>

#import "Preferences.h"
#import "ServerController.h"
#import "CustomTableView.h"
#import "TableAlertController.h"
#import "ApplicationLibraryList.h"

NSString * const kSparkApplicationPBoardType = @"SparkApplicationPBoardType";

static NSComparisonResult CompareApplicationList(id object1, id object2, void *context);

@implementation ApplicationLibraryController

- (id)init {
  if (self = [super initWithLibraryNibNamed:@"ApplicationLibrary"]) {
    
  }
  return self;
}

#pragma mark -
#pragma mark Configuration

- (id)objectsLibrary {
  return SparkDefaultApplicationLibrary();
}

- (NSString *)dragAndDropDataType {
  return kSparkApplicationPBoardType;
}

- (Class)listClass {
  return [SparkApplicationList class];
}

- (NSString *)confirmDeleteObjectKey {
  return kSparkPrefConfirmDeleteApplication;
}

#pragma mark -

- (void)awakeFromNib {
  [super awakeFromNib];
  [objectsTable registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
  [lists setCompareFunction:CompareApplicationList];
  [lists addObject:[ApplicationLibraryList list]];
  [lists addObjects:[SparkDefaultListLibrary() listsWithContentType:[SparkApplication class]]];
  [lists rearrangeObjects];
  [lists setSelectionIndex:0];
}

- (NSOpenPanel *)openPanel {
  id openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles:YES];
  [openPanel setResolvesAliases:YES];
  [openPanel setCanCreateDirectories:NO];
  [openPanel setCanChooseDirectories:NO];
  [openPanel setAllowsMultipleSelection:YES];
  [openPanel setTreatsFilePackagesAsDirectories:NO];
  [openPanel setDelegate:self];
  return openPanel;
}

- (IBAction)newObject:(id)sender {
  id openPanel = [self openPanel];
  [openPanel beginSheetForDirectory:nil
                               file:nil
                              types:[NSArray arrayWithObjects:@"app", @"APPL", nil]
                     modalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(addApplicationDidEnd:returnCode:object:)
                        contextInfo:nil];
}

- (void)editObject:(SparkApplication *)object {
  if ([[object uid] unsignedIntValue] == 0) {
    NSBeep();
    return;
  }
  id openPanel = [self openPanel];
  id path = [object path];
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel beginSheetForDirectory:(path) ? [path stringByDeletingLastPathComponent] : nil
                               file:(path) ? [path lastPathComponent] : nil
                              types:[NSArray arrayWithObjects:@"app", @"APPL", nil]
                     modalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(addApplicationDidEnd:returnCode:object:)
                        contextInfo:object];
}

- (void)addApplicationDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode object:(SparkApplication *)object {
  if (NSOKButton == returnCode) {
    id files = [[sheet filenames] objectEnumerator];
    id file;
    while (file = [files nextObject]) {
      if (object) {
        [object setPath:file];
        [self updateObject:object];
      } else {
        id app = [[SparkApplication alloc] initWithPath:file];
        if (app) {
          [self createObject:app];
          [app release];
        }
      }
    }
  }
}

- (void)updateObject:(SparkApplication *)object {
  [super updateObject:object];
  [[NSNotificationCenter defaultCenter] postNotificationName:kSparkApplicationDidChangeNotification object:object];
}

- (void)removeList:(SparkObjectList *)list {
  NSSet *keys = [SparkDefaultKeyLibrary() keysUsingApplicationList:(id)list];
  if ([keys count]) {
    id alert = [[TableAlertController alloc] initForSingleDelete];
    [alert setValues:[keys allObjects]];
    [alert setTitle:NSLocalizedStringFromTable(@"CONFIRM_DELETE_USED_LIST",
                                               @"Libraries", @"Delete List affect keys warning")];
    int result = [NSApp runModalForWindow:[alert window]];
    [alert release];
    if (result == NSAlertAlternateReturn) { /* Cancel */
      list = nil;
    }
  }
  if (list) {
    [super removeList:list];
  }
}

- (void)removeObjects:(NSArray *)objectsArray {
  NSMutableArray *actionsToDelete = nil;
  NSMutableArray *usedActions = [[NSMutableArray alloc] init];
  NSMutableSet *usedKeys = [[NSMutableSet alloc] init];
  
  id items = [objectsArray objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    if ([[item uid] unsignedIntValue]) { 
      NSSet *keys = [SparkDefaultKeyLibrary() keysUsingApplication:item];
      if ([keys count]) {
        [usedActions addObject:item];
        [usedKeys addObjectsFromArray:[keys allObjects]];
      }
    }
  }
  if ([usedKeys count]) {
    id alert = [[TableAlertController alloc] init];
    [alert setValues:[usedKeys allObjects]];
    [alert setTitle:NSLocalizedStringFromTable(@"CONFIRM_DELETE_USED_APPLICATIONS",
                                               @"Libraries", @"Delete Application affect keys warning")];
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

#pragma mark Open Dialog Filter 
//- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename {
//  id application = [[SKApplication alloc] initWithPath:filename];
//  if (application) {
//    BOOL result = YES;
//    id apps = [[SparkApplicationLibrary sharedLibrary] objectEnumerator];
//    id app;
//    while (app = [apps nextObject]) {
//      if ([[app identifier] isEqualToString:[application identifier]]) {
//        result = NO;
//        break;
//      }
//    }
//    [application release];
//    return result;
//  }
//  return YES;
//}

@end

#pragma mark -
static NSComparisonResult CompareApplicationList(id object1, id object2, void *context) {
  if ([object1 class] == [object2 class]) {
    return [[object1 name] caseInsensitiveCompare:[object2 name]];
  }
  
  //La Bibliothèque passe en premier 
  if ([object1 isMemberOfClass:[ApplicationLibraryList class]]) {
    return NSOrderedAscending;
  } else if ([object2 isMemberOfClass:[ApplicationLibraryList class]]) {
    return NSOrderedDescending;
  }
  return NSOrderedSame;
}
