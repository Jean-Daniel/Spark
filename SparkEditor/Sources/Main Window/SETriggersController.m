/*
 *  SETriggersController.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SETriggersController.h"
#import "SELibraryDocument.h"
#import "SELibraryWindow.h"
#import "SESparkEntrySet.h"
#import "SEPreferences.h"
#import "SEEntryEditor.h"
#import "Spark.h"

#import <SparkKit/SparkLibrary.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkEntryManager.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKTableView.h>
#import <ShadowKit/SKImageAndTextCell.h>
#import <ShadowKit/SKAppKitExtensions.h>

static
BOOL _SEFilterEntry(NSString *search, SparkEntry *entry, void *ctxt) {
  if (!search) return YES;

  if ([[entry name] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
    return YES;
  
  if ([[entry actionDescription] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
    return YES;
  
  if ([[entry categorie] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
    return YES;
  
  return NO;
}

typedef struct _SETriggerStyle {
  BOOL bold;
  BOOL strike;
  NSColor *standard, *selected;
} SETriggerStyle;

static
SETriggerStyle styles[6];

@implementation SETriggersController

+ (void)initialize {
  if ([SETriggersController class] == self) {
    /* Standard (global) */
    styles[0] = (SETriggerStyle){NO, NO,
      [[NSColor controlTextColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Global overrided */
    styles[1] = (SETriggerStyle){YES, NO,
      [[NSColor controlTextColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Inherits */
    styles[2] = (SETriggerStyle){NO, NO,
      [[NSColor darkGrayColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Override */
    styles[3] = (SETriggerStyle){YES, NO,
      [[NSColor colorWithCalibratedRed:.067f green:.357f blue:.420f alpha:1] retain],
      [[NSColor colorWithCalibratedRed:.886f green:.914f blue:.996f alpha:1] retain]};
    /* Specifics */
    styles[4] = (SETriggerStyle){NO, NO,
      [[NSColor orangeColor] retain],
      [[NSColor colorWithCalibratedRed:.992f green:.875f blue:.749f alpha:1] retain]};
    /* Weak Override */
    styles[5] = (SETriggerStyle){NO, YES,
      [[NSColor colorWithCalibratedRed:.463f green:.016f blue:.314f alpha:1] retain],
      [[NSColor colorWithCalibratedRed:.984f green:.890f blue:1.00f alpha:1] retain]};
  }
}

- (id)init {
  if (self = [super init]) {

  }
  return self;
}

- (void)dealloc {
  [se_list release];
  [[se_library notificationCenter] removeObserver:self];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [se_library release];
  [super dealloc];
}

#pragma mark -
- (SparkLibrary *)library {
  return se_library;
}
- (SparkApplication *)application {
  return [ibWindow application];
}

- (void)awakeFromNib {
  se_library = [[ibWindow library] retain];
  [self setFilterFunction:_SEFilterEntry context:nil];
  
  [uiTable setTarget:self];
  [uiTable setDoubleAction:@selector(doubleAction:)];
  
//  [uiTable setAutosaveName:@"SparkMainEntryTable"];
//  [uiTable setAutosaveTableColumns:YES];
  
  [uiTable setVerticalMotionCanBeginDrag:YES];
  [uiTable setContinueEditing:NO];
}

- (NSView *)tableView {
  return uiTable;
}

- (void)setListEnabled:(BOOL)flag {
  UInt32 app = [[self application] uid];
  int idx = [self count];
  SparkEntryManager *manager = [[self library] entryManager];
  SEL method = flag ? @selector(enableEntry:) : @selector(disableEntry:);
  while (idx-- > 0) {
    SparkEntry *entry = [self objectAtIndex:idx];
    if ([[entry application] uid] == app) {
      if (XOR([entry isEnabled], flag)) {
        [manager performSelector:method withObject:entry];
      }
    }
  }
  [uiTable reloadData];
}

//- (void)filterEntries:(NSString *)search {
//  [se_entries removeAllObjects];
//  if (!search || ![search length]) {
//    [se_entries addObjectsFromArray:se_snapshot];
//  } else {
//    unsigned count = [se_snapshot count];
//    while (count-- > 0) {
//      SparkEntry *entry = [se_snapshot objectAtIndex:count];
//      if (SEFilterEntry(search, entry))
//        [se_entries addObject:entry];
//    }
//  }
//  [self sortTriggers:[uiTable sortDescriptors]];
//}

- (IBAction)search:(id)sender {
  [self setSearchString:[sender stringValue]];
}

- (IBAction)doubleAction:(id)sender {
  /* Does not support multi-edition */
  if ([[self selectedObjects] count] != 1) {
    NSBeep();
    return;
  }
  
  int idx = [self selectionIndex];
  if (idx >= 0) {
    SparkEntry *entry = [self objectAtIndex:idx];
    if ([entry isPlugged]) {
      [[ibWindow document] editEntry:entry];
    } else {
      NSBeep();
    }
  }
}

#pragma mark -
#pragma mark Data Source
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex {
  /* Should not allow all columns */
  return [[tableColumn identifier] isEqualToString:@"__item__"] || [[tableColumn identifier] isEqualToString:@"active"];
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
//  SparkEntry *entry = [se_entries objectAtIndex:rowIndex];
//  if ([[aTableColumn identifier] isEqualToString:@"active"]) {
//    NSEvent *evnt = [NSApp currentEvent];
//    if (evnt && [evnt type] == NSLeftMouseUp && ([evnt modifierFlags] & NSAlternateKeyMask)) {
//      [self setListEnabled:[anObject boolValue]];
//    } else {
//      SparkApplication *application = [self application];
//      if ([application uid] != 0 && kSparkEntryTypeDefault == [entry type]) {
//        /* Inherits: should create an new entry */
//        entry = [[entry copy] autorelease];
//        [entry setApplication:application];
//        [[[self library] entryManager] addEntry:entry];
//      }
//      if ([anObject boolValue]) {
//        [[[self library] entryManager] enableEntry:entry];
//      } else {
//        [[[self library] entryManager] disableEntry:entry];
//      }
//      [aTableView setNeedsDisplayInRect:[aTableView rectOfRow:rowIndex]];
//    }
//  } else if ([[aTableColumn identifier] isEqualToString:@"__item__"]) {
//    if ([anObject length] > 0) {
//      [entry setName:anObject];
//    } else {
//      NSBeep();
//      // Be more verbose maybe?
//    }
//  }
}

#pragma mark Delegate
- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
//  NSIndexSet *indexes = [aTableView selectedRowIndexes];
//  NSArray *items = indexes ? [se_entries objectsAtIndexes:indexes] : nil;
//  if (items && [items count]) {
//    if ([se_list uid] < kSparkLibraryReserved) {
//      [[ibWindow document] removeEntries:items];
//    } else {
//      // User list
//      int count = [items count];
//      NSMutableArray *triggers = [[NSMutableArray alloc] init];
//      while (count-- > 0) {
//        SparkEntry *entry = [items objectAtIndex:count];
//        [triggers addObject:[entry trigger]];
//      }
//      [se_list removeObjectsInArray:triggers];
//      [triggers release];
//    }
//  }
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  SparkEntry *entry = [self objectAtIndex:rowIndex];
  
  /* Text field cell */
  if ([aCell respondsToSelector:@selector(setTextColor:)]) {  
    SparkApplication *application = [self application];
    
    SInt32 idx = -1;
    if (0 == [application uid]) {
      /* Global key */
      if ([[[self library] entryManager] containsOverwriteEntryForTrigger:[[entry trigger] uid]]) {
        idx = 1;
      } else {
        idx = 0;
      }
    } else {
      switch ([entry type]) {
        case kSparkEntryTypeDefault:
          /* Inherits */
          idx = 2;
          break;
        case kSparkEntryTypeOverWrite:
          idx = 3;
          break;
        case kSparkEntryTypeSpecific: 
          /* Is only defined for a specific application */
          idx = 4;
          break;
        case kSparkEntryTypeWeakOverWrite:
          idx = 5;
          break;
      }
    }
    if (idx >= 0) {
      NSWindow *window = [aTableView window];
      BOOL selected = ([window isKeyWindow] && [window firstResponder] == aTableView) && [aTableView isRowSelected:rowIndex];
      if ([entry isPlugged]) {
        [aCell setTextColor:selected ? styles[idx].selected : styles[idx].standard];
      } else {
        /* handle case where plugin is disabled */
        [aCell setTextColor:selected ? [NSColor selectedControlTextColor] : [NSColor disabledControlTextColor]];
      }
      /* Set Line status */
      if ([aCell respondsToSelector:@selector(setDrawsLineOver:)])
        [aCell setDrawsLineOver:styles[idx].strike && ![entry isEnabled]];
      
      float size = [NSFont smallSystemFontSize];
      [aCell setFont:styles[idx].bold ? [NSFont boldSystemFontOfSize:size] : [NSFont systemFontOfSize:size]];
    }
  }
}

#pragma mark Drag & Drop
- (BOOL)tableView:(NSTableView *)aTableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard {
  NSMutableIndexSet *idxes = [NSMutableIndexSet indexSet];
  unsigned count = [rows count];
  while (count-- > 0) {
    [idxes addIndex:[[rows objectAtIndex:count] unsignedIntValue]];
  }
  return [self tableView:aTableView writeRowsWithIndexes:idxes toPasteboard:pboard];
}
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
  if (![rowIndexes count])
    return NO;
  
//  int idx = 0;
//  NSMutableArray *triggers = [[NSMutableArray alloc] init];
//  SKIndexEnumerator *indexes = [rowIndexes indexEnumerator];
//  while ((idx = [indexes nextIndex]) != NSNotFound) {
//    SparkTrigger *trigger = [[se_entries objectAtIndex:idx] trigger];
//    [triggers addObject:[NSNumber numberWithUnsignedInt:[trigger uid]]];
//  }
//  [pboard declareTypes:[NSArray arrayWithObject:SparkTriggerListPboardType] owner:self];
//  [pboard setPropertyList:triggers forType:SparkTriggerListPboardType];
//  [triggers release];
  
  return YES;
}

#pragma mark -
#pragma mark Notifications
/* Plugins status change, etc... */
//- (void)cacheDidReload:(NSNotification *)aNotification {
//  [self refresh];
//  [uiTable reloadData];
//}
//
///* A list content has changed */
//- (void)listDidReload:(NSNotification *)aNotification {
//  /* If updated list is the current list */
//  if ([aNotification object] == se_list) {
//    [self refresh];
//    [uiTable reloadData];
//  }
//}
//- (void)listDidAddTriggers:(NSNotification *)aNotification {
//  if ([aNotification object] == se_list) {
//    [self refresh];  
//    [uiTable reloadData];
//  }
//}
//- (void)listDidUpdateTriggers:(NSNotification *)aNotification {
//  if ([aNotification object] == se_list) {
//    [self refresh];
//    [uiTable reloadData];
//  }
//}
//- (void)listDidRemoveTriggers:(NSNotification *)aNotification {
//  if ([aNotification object] == se_list) {
//    [self refresh];
//    [uiTable reloadData];
//  }
//}
//
//- (void)didAddEntry:(NSNotification *)aNotification {
//  SparkEntry *entry = SparkNotificationObject(aNotification);
//  /* If did not already contains the new entry and selected list contains entry trigger, refresh */
//  if (![se_snapshot containsObjectIdenticalTo:entry] && 
//      [se_list containsObject:[entry trigger]]) {
//    [self refresh];
//    /* Redraw only if displayed entries contains the new entry */
//    if ([se_entries containsObject:entry])
//      [uiTable reloadData];
//  }
//}
//- (void)didUpdateEntry:(NSNotification *)aNotification {
//  SparkEntry *entry = SparkNotificationObject(aNotification);
//  SparkEntry *updated = SparkNotificationUpdatedObject(aNotification);
//  /* If did not already contains the new entry and selected list contains entry trigger, or contains the old entry, refresh */
//  if ((![se_snapshot containsObjectIdenticalTo:entry] && [se_list containsObject:[entry trigger]]) ||
//      [se_snapshot containsObject:updated]) {
//    BOOL reload = [se_entries containsObject:entry];
//    [self refresh];
//    /* Redraw only if displayed entries contains the new/old entry  */
//    if (reload || [se_entries containsObject:entry])
//      [uiTable reloadData];
//  }
//}
//- (void)didRemoveEntry:(NSNotification *)aNotification {
//  /* If contains object */
//  SparkEntry *entry = SparkNotificationObject(aNotification);
//  if ([se_snapshot containsObject:entry]) {
//    BOOL reload = [se_entries containsObject:entry];
//    [self refresh];
//    /* Redraw only if displayed entries change */
//    if (reload)
//      [uiTable reloadData];
//  }
//}
//
//- (void)didUpdateEntryStatus:(NSNotification *)aNotification {
//  SparkEntry *entry = SparkNotificationObject(aNotification);
//  unsigned idx = [se_snapshot indexOfObject:entry];
//  if (idx != NSNotFound) {
//    [se_snapshot replaceObjectAtIndex:idx withObject:entry];
//    /* Update entries */
//    idx = [se_entries indexOfObject:entry];
//    if (idx != NSNotFound) {
//      [se_entries replaceObjectAtIndex:idx withObject:entry];
//      [uiTable setNeedsDisplayInRect:[uiTable rectOfRow:idx]];
//    }
//  }
//}

@end

#pragma mark -
@implementation SparkEntry (SETriggerSort)

+ (void)load {
  if ([SparkEntry class] == self) {
    SKExchangeInstanceMethods(self, @selector(dealloc), @selector(se_dealloc));
    SKExchangeInstanceMethods(self, @selector(setAction:), @selector(se_setAction:));
  }
}

- (UInt32)triggerValue {
  return [[self trigger] character] << 16 | [[self trigger] modifier] & 0xff;
}

- (id)representation {
  return self;
}

- (void)setRepresentation:(NSString *)name {
  [[self action] setName:name];
}

- (void)se_dealloc {
  ShadowTrace();
  [self se_dealloc];
}

- (void)se_setAction:(SparkAction *)anAction {
  ShadowTrace();
  [self se_setAction:anAction];
}

@end
