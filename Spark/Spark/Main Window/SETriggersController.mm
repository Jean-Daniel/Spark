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
#import "SETriggerTable.h"
#import "SEPreferences.h"
#import "SEEntryEditor.h"
#import "SEEntryList.h"
#import "Spark.h"

#import <SparkKit/SparkLibrary.h>

#import <SparkKit/SparkEntry.h>
#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkPrivate.h>
#import <SparkKit/SparkApplication.h>
#import <SparkKit/SparkEntryManager.h>

#import <WonderBox/WonderBox.h>

typedef struct _SETriggerStyle {
  BOOL bold;
  BOOL strike;
  NSColor *standard, *selected;
} SETriggerStyle;

static 
NSString * sSEHiddenPluggedObserverKey = nil;

@interface SparkEntry (SETriggerObserver)
- (void)setActive:(BOOL)active;
@end

static inline
SETriggerStyle TriggerStyle(SparkEntry *entry, bool isDefault) {
  if (isDefault) {
    /* Global key */
    return {
      .bold = entry.hasVariant, .strike = YES,
      .standard = [NSColor controlTextColor],
      .selected = [NSColor selectedTextColor]
    };
  } else {
    switch (entry.type) {
      case kSparkEntryTypeDefault:
        /* Inherits */
        return {
          .bold = NO, .strike = YES,
          .standard = [NSColor darkGrayColor],
          .selected = [NSColor selectedTextColor]
        };
        break;
      case kSparkEntryTypeOverWrite:
        return {
          .bold = YES, .strike = YES,
          .standard = [NSColor colorWithCalibratedRed:.067 green:.357 blue:.420 alpha:1],
          .selected = [NSColor colorWithCalibratedRed:.886 green:.914 blue:.996 alpha:1]
        };
        break;
      case kSparkEntryTypeSpecific:
        /* Is only defined for a specific application */
        return {
          .bold = YES, .strike = YES,
          .standard = [NSColor orangeColor],
          .selected = [NSColor colorWithCalibratedRed:.992 green:.875 blue:.749 alpha:1]
        };
        break;
      case kSparkEntryTypeWeakOverWrite:
        return {
          .bold = NO, .strike = YES,
          .standard = [NSColor colorWithCalibratedRed:.463 green:.016 blue:.314 alpha:1],
          .selected = [NSColor colorWithCalibratedRed:.984 green:.890 blue:1.00 alpha:1]
        };
        break;
    }
  }
}

@implementation SETriggersController

+ (void)initialize {
  if ([SETriggersController class] == self) {
    sSEHiddenPluggedObserverKey = [@"values." stringByAppendingString:kSEPreferencesHideDisabled];
  }
}

- (id)initWithCoder:(NSCoder *)aCoder {
  if (self = [super initWithCoder:aCoder]) {
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:sSEHiddenPluggedObserverKey
                                                                 options:NSKeyValueObservingOptionNew
                                                                 context:nil];
  }
  return self;
}

- (void)dealloc {
	//[self setSelectedList:nil];
  [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self
                                                               forKeyPath:sSEHiddenPluggedObserverKey];
}

#pragma mark -
- (SparkLibrary *)library {
  return [ibWindow library];
}
- (SparkApplication *)application {
  return [ibWindow application];
}

- (void)awakeFromNib {
  self.filterBlock = ^BOOL(NSString *search, SparkEntry *entry) {
    /* Hide unplugged if needed */
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kSEPreferencesHideDisabled] && ![entry isPlugged])
      return NO;

    if (!search)
      return YES;

    if ([[entry name] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
      return YES;

    if ([[entry actionDescription] rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
      return YES;

    if ([entry.category rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound)
      return YES;
    
    return NO;
  };
  
  uiTable.target = self;
  uiTable.doubleAction = @selector(doubleAction:);
  
  [uiTable setSortDescriptors:gSortByNameDescriptors];
  
  [uiTable setAutosaveName:@"SparkTriggerTable"];
  [uiTable setAutosaveTableColumns:YES];
  
  [uiTable setVerticalMotionCanBeginDrag:YES];
}

- (NSView *)tableView {
  return uiTable;
}

- (void)setListEnabled:(BOOL)flag {
  SparkUID app = [[self application] uid];
	SparkEntryManager *manager = [[self library] entryManager];
	for (NSUInteger idx = 0, count = [self.arrangedObjects count]; idx < count; idx++) {
    SparkEntry *entry = [self objectAtArrangedObjectIndex:idx];
    if ([[entry application] uid] == app) {
			if (flag) {
				/* avoid conflict */
				if (![manager activeEntryForTrigger:[entry trigger] application:[entry application]])
					[entry setEnabled:flag];
			} else {
				[entry setEnabled:flag];
			}
    }
  }
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
  
  NSUInteger idx = [self selectionIndex];
  if (idx != NSNotFound) {
    SparkEntry *entry = [self objectAtArrangedObjectIndex:idx];
    if ([entry isPlugged]) {
      [[ibWindow document] editEntry:entry];
    } else {
      NSBeep();
    }
  }
}

#pragma mark -
#pragma mark Data Source
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
  /* Should not allow all columns */
  return [[tableColumn identifier] isEqualToString:@"__item__"] || [[tableColumn identifier] isEqualToString:@"active"];
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {

}

//- (IBAction)selectAll:(id)sender {
//  WBTrace();
//}

#pragma mark Delegate
- (void)spaceDownInTableView:(SETriggerTable *)aTable {
  [self.selectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    SparkEntry *entry = [self objectAtArrangedObjectIndex:idx];
    if ([entry isPlugged]) {
      [entry setActive:![entry isEnabled]];
    }
  }];
}

- (BOOL)tableView:(SETriggerTable *)aTable shouldHandleOptionClick:(NSEvent *)anEvent {
  NSPoint point = [aTable convertPoint:[anEvent locationInWindow] fromView:nil];
  NSInteger row = [aTable rowAtPoint:point];
  NSInteger column = [aTable columnAtPoint:point];
  if (row != -1 && column != -1) {
    if ([[[[aTable tableColumns] objectAtIndex:column] identifier] isEqualToString:@"active"]) {
      SparkEntry *entry = [self objectAtArrangedObjectIndex:row];
      [self setListEnabled:![entry isEnabled]];
      return NO;
    }
  }
  return YES;
}

- (void)deleteSelectionInTableView:(NSTableView *)aTableView {
  NSArray *items = [self selectedObjects];
  if (items && [items count]) {
		SEEntryList *list = [ibWindow selectedList];
    if ([list isEditable]) {
      // User list
      [[list sparkList] removeEntriesInArray:items];
    } else {
      [(SELibraryDocument *)[ibWindow document] removeEntriesInArray:items];
    }
  }
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  SparkEntry *entry = [self objectAtArrangedObjectIndex:rowIndex];
  
  /* Text field cell */
  if ([aCell respondsToSelector:@selector(setTextColor:)]) {  
    SparkApplication *application = [self application];
    
    NSWindow *window = [aTableView window];
    BOOL selected = ([window isKeyWindow] && [window firstResponder] == aTableView) && [aTableView isRowSelected:rowIndex];
    SETriggerStyle style = TriggerStyle(entry, kSparkApplicationSystemUID == application.uid);
    if ([entry isPlugged]) {
      [aCell setTextColor:selected ? style.selected : style.standard];
    } else {
      /* handle case where plugin is disabled */
      [aCell setTextColor:selected ? [NSColor selectedControlTextColor] : [NSColor disabledControlTextColor]];
    }
    /* Set Line status */
    if ([aCell respondsToSelector:@selector(setDrawsLineOver:)]) 
      [aCell setDrawsLineOver:style.strike && ![entry isEnabled]];
    
    CGFloat size = [NSFont smallSystemFontSize];
    [aCell setFont:style.bold ? [NSFont boldSystemFontOfSize:size] : [NSFont systemFontOfSize:size]];
  }
}

#pragma mark Drag & Drop
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
  if (![rowIndexes count])
    return NO;
  
  NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
  uuid_t bytes;
  [self.library.uuid getUUIDBytes:bytes];
  [plist setObject:[NSData dataWithBytes:bytes length:sizeof(bytes)] forKey:@"uuid"];
  [pboard declareTypes:@[SparkEntriesPboardType] owner:self];
  
  NSMutableArray *entries = [[NSMutableArray alloc] init];
  [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    SparkEntry *entry = [self objectAtArrangedObjectIndex:idx];
    [entries addObject:@([entry uid])];
  }];
  [plist setObject:entries forKey:@"entries"];
  
  [pboard setPropertyList:plist forType:SparkEntriesPboardType];
  return YES;
}

#pragma mark Context Menu
- (NSMenu *)tableView:(NSTableView *)aTableView menuForRow:(NSInteger)row {
  if (row >= 0) {
    SparkEntry *entry = [self objectAtArrangedObjectIndex:row];
		NSArray *variants = [entry variants];
    if ([variants count] > 1) {
      NSMenu *ctxt = [[NSMenu alloc] initWithTitle:@"Action Menu"];
      NSMenuItem *item = [ctxt addItemWithTitle:NSLocalizedString(@"Show in Application...", @"Reveal item in the list...") action:nil keyEquivalent:@""];
      NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"Submenu"];
      for (NSUInteger idx = 0; idx < [variants count]; idx++) {
        SparkEntry *variant = [variants objectAtIndex:idx];
				if (variant != entry) {
					SparkApplication *application = [variant application];
					NSMenuItem *appItem = [[NSMenuItem alloc] initWithTitle:[application name] 
																													 action:@selector(revealInApplication:) keyEquivalent:@""];
					[appItem setRepresentedObject:variant];
					/* set icon */
					NSImage *icon = [[application icon] copy];
					[icon setSize:NSMakeSize(16, 16)];
					[appItem setImage:icon];
					
					[submenu addItem:appItem];
				}
      }
      [item setSubmenu:submenu];
      
      return ctxt;
    }
  }
  return nil;
}

#pragma mark Notifications
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:sSEHiddenPluggedObserverKey]) {
		[self rearrangeObjects];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end

#pragma mark -
@implementation SparkEntry (SETriggerObserver)

+ (void)load {
  if ([SparkEntry class] == self) {
		WBRuntimeExchangeInstanceMethods(self, @selector(setEnabled:), @selector(se_setEnabled:));
  }
}

- (void)performSetActive:(BOOL)value document:(SELibraryDocument *)document {
	SparkEntry *entry = self;
	SparkApplication *application = [document application];
	if ([application uid] != kSparkApplicationSystemUID && kSparkEntryTypeDefault == [self type]) {
		/* Inherits: should create an new entry */
		entry = [entry createWeakVariantWithApplication:application];
		[[document mainWindowController] revealEntry:entry];
	}
	[entry setEnabled:value];
}

- (void)setActive:(BOOL)active {
  SELibraryDocument *document = SEGetDocumentForLibrary([[self action] library]);
  if (document) {
		/* check conflict */
		if (active) {
			SparkEntry *previous = [[[document library] entryManager] activeEntryForTrigger:[self trigger]
																																					application:[self application]];
			if (previous) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Entry conflict";
        alert.informativeText = [NSString stringWithFormat:@"'%@' already use the same shortcut.", [previous name]];
        [alert addButtonWithTitle:@"Disable previous"];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
        [alert beginSheetModalForWindow:document.windowForSheet completionHandler:^(NSModalResponse returnCode) {
          if (NSAlertFirstButtonReturn == returnCode) {
            previous.enabled = NO;
            [self performSetActive:YES document:SEGetDocumentForLibrary(self.action.library)];
          }
        }];
				return;
			}
		}
		[self performSetActive:active document:document];
  }
}

- (void)se_setEnabled:(BOOL)enabled {
	[self willChangeValueForKey:@"representation"];
  [self willChangeValueForKey:@"active"];
  [self se_setEnabled:enabled];
  [self didChangeValueForKey:@"active"];
  [self didChangeValueForKey:@"representation"];
}

@end

@implementation SparkEntry (SEEntrySortByTrigger)

- (NSUInteger)triggerValue {
  return SETriggerSortValue([self trigger]);
}

@end

NSUInteger SETriggerSortValue(SparkTrigger *aTrigger) {
  if ([aTrigger isKindOfClass:[SparkHotKey class]])
    return (NSUInteger)[(SparkHotKey *)aTrigger character] << 16 | ([(SparkHotKey *)aTrigger modifier] & 0xff);
  else return 0;  
}

