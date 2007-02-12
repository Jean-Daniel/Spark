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
#import "SETriggerTable.h"
#import "SEPreferences.h"
#import "SEEntryEditor.h"
#import "Spark.h"

#import <SparkKit/SparkLibrary.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkEntryManager.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKImageAndTextCell.h>
#import <ShadowKit/SKAppKitExtensions.h>

static
BOOL _SEFilterEntry(NSString *search, SparkEntry *entry, void *ctxt) {
  /* Hide unplugged if needed */
  if ([[NSUserDefaults standardUserDefaults] boolForKey:kSEPreferencesHideDisabled] && ![entry isPlugged]) return NO;
  
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

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:[@"values." stringByAppendingString:kSEPreferencesHideDisabled]
                                                                 options:NSKeyValueObservingOptionNew
                                                                 context:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];
  [super dealloc];
}

#pragma mark -
- (SparkLibrary *)library {
  return [ibWindow library];
}
- (SparkApplication *)application {
  return [ibWindow application];
}

- (void)awakeFromNib {
  [self setFilterFunction:_SEFilterEntry context:nil];
  
  [uiTable setTarget:self];
  [uiTable setDoubleAction:@selector(doubleAction:)];
  
  [uiTable setSortDescriptors:gSortByNameDescriptors];
  
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

}

- (IBAction)selectAll:(id)sender {
  ShadowTrace();
}

#pragma mark Delegate
- (void)spaceDownInTableView:(SETriggerTable *)aTable {
  NSUInteger idx = 0;
  SparkEntryManager *manager = [[self library] entryManager];
  SKIndexEnumerator *idexes = [[self selectionIndexes] indexEnumerator];
  while ((idx = [idexes nextIndex]) != NSNotFound) {
    SparkEntry *entry = [self objectAtIndex:idx];
    if ([entry isPlugged]) {
      if ([entry isEnabled])
        [manager disableEntry:entry];
      else
        [manager enableEntry:entry];
    }
  }
}

- (BOOL)tableView:(SETriggerTable *)aTable shouldHandleOptionClick:(NSEvent *)anEvent {
  NSPoint point = [aTable convertPoint:[anEvent locationInWindow] fromView:nil];
  int row = [aTable rowAtPoint:point];
  int column = [aTable columnAtPoint:point];
  if (row != -1 && column != -1) {
    if ([[[[aTable tableColumns] objectAtIndex:column] identifier] isEqualToString:@"active"]) {
      SparkEntry *entry = [self objectAtIndex:row];
      [self setListEnabled:![entry isEnabled]];
      return NO;
    }
  }
  return YES;
}

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

#pragma mark Notifications
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  [self rearrangeObjects];
}

@end

#pragma mark -
@implementation SparkEntry (SETriggerSort)

+ (void)load {
  if ([SparkEntry class] == self) {
    SKExchangeInstanceMethods(self, @selector(setEnabled:), @selector(se_setEnabled:));
  }
}

- (UInt32)triggerValue {
  return [[self trigger] character] << 16 | [[self trigger] modifier] & 0xff;
}

- (void)setActive:(BOOL)active {
  SELibraryDocument *document = SEGetDocumentForLibrary([[self action] library]);
  if (document) {
    SparkEntry *entry = self;
    SparkApplication *application = [document application];
    if ([application uid] != 0 && kSparkEntryTypeDefault == [self type]) {
      /* Inherits: should create an new entry */
      entry = [[self copy] autorelease];
      [entry setApplication:application];
      [[[document library] entryManager] addEntry:entry];
      [[document mainWindowController] revealEntry:entry];
    }
    if (active) {
      [[[document library] entryManager] enableEntry:entry];
    } else {
      [[[document library] entryManager] disableEntry:entry];
    }
  }
}

- (void)se_setEnabled:(BOOL)enabled {
  if ([self type] == kSparkEntryTypeWeakOverWrite) [self willChangeValueForKey:@"representation"];
  [self willChangeValueForKey:@"active"];
  [self se_setEnabled:enabled];
  if ([self type] == kSparkEntryTypeWeakOverWrite) [self didChangeValueForKey:@"representation"];
  [self didChangeValueForKey:@"active"];
}

- (id)representation {
  return self;
}
- (void)setRepresentation:(NSString *)name {
  if (name && [name length]) {
    SparkAction *act = [self action];
    if (act) {
      [[[act library] undoManager] registerUndoWithTarget:self
                                                 selector:@selector(setRepresentation:)
                                                   object:[act name]];
      [act setName:name];
    }
  } else {
    NSBeep();
  }
}

@end
