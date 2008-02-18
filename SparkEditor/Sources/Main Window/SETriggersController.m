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
#import <SparkKit/SparkEntryManager.h>

#import WBHEADER(WBFunctions.h)
#import WBHEADER(WBExtensions.h)
#import WBHEADER(WBImageAndTextCell.h)
#import WBHEADER(WBAppKitExtensions.h)

static
BOOL _SEEntryFilter(NSString *search, SparkEntry *entry, void *ctxt) {
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

static 
NSString * sSEHiddenPluggedObserverKey = nil;

@interface SparkEntry (SETriggerSort)
- (void)setActive:(BOOL)active;
@end

@implementation SETriggersController

+ (void)initialize {
  if ([SETriggersController class] == self) {
    /* Standard (global) */
    styles[0] = (SETriggerStyle){NO, YES,
      [[NSColor controlTextColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Global overrided */
    styles[1] = (SETriggerStyle){YES, YES,
      [[NSColor controlTextColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Inherits */
    styles[2] = (SETriggerStyle){NO, YES,
      [[NSColor darkGrayColor] retain],
      [[NSColor selectedTextColor] retain]};
    /* Override */
    styles[3] = (SETriggerStyle){YES, YES,
      [[NSColor colorWithCalibratedRed:.067 green:.357 blue:.420 alpha:1] retain],
      [[NSColor colorWithCalibratedRed:.886 green:.914 blue:.996 alpha:1] retain]};
    /* Specifics */
    styles[4] = (SETriggerStyle){YES, YES,
      [[NSColor orangeColor] retain],
      [[NSColor colorWithCalibratedRed:.992 green:.875 blue:.749 alpha:1] retain]};
    /* Weak Override */
    styles[5] = (SETriggerStyle){NO, YES,
      [[NSColor colorWithCalibratedRed:.463 green:.016 blue:.314 alpha:1] retain],
      [[NSColor colorWithCalibratedRed:.984 green:.890 blue:1.00 alpha:1] retain]};
    
    sSEHiddenPluggedObserverKey = [[@"values." stringByAppendingString:kSEPreferencesHideDisabled] retain];
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
  [self setFilterFunction:_SEEntryFilter context:nil];
  
  [uiTable setTarget:self];
  [uiTable setDoubleAction:@selector(doubleAction:)];
  
  [uiTable setSortDescriptors:gSortByNameDescriptors];
  
  [uiTable setAutosaveName:@"SparkTriggerTable"];
  [uiTable setAutosaveTableColumns:YES];
  
  [uiTable setVerticalMotionCanBeginDrag:YES];
  [uiTable setContinueEditing:NO];
}

- (NSView *)tableView {
  return uiTable;
}

- (void)setListEnabled:(BOOL)flag {
	NSUInteger count = [self count];
  SparkUID app = [[self application] uid];
	SparkEntryManager *manager = [[self library] entryManager];
	for (NSUInteger idx = 0; idx < count; idx++) {
    SparkEntry *entry = [self objectAtIndex:idx];
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
  NSUInteger idx = 0;
  WBIndexEnumerator *idexes = [[self selectionIndexes] indexEnumerator];
  while ((idx = [idexes nextIndex]) != NSNotFound) {
    SparkEntry *entry = [self objectAtIndex:idx];
    if ([entry isPlugged]) {
      [entry setActive:![entry isEnabled]];
    }
  }
}

- (BOOL)tableView:(SETriggerTable *)aTable shouldHandleOptionClick:(NSEvent *)anEvent {
  NSPoint point = [aTable convertPoint:[anEvent locationInWindow] fromView:nil];
  NSInteger row = [aTable rowAtPoint:point];
  NSInteger column = [aTable columnAtPoint:point];
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
  SparkEntry *entry = [self objectAtIndex:rowIndex];
  
  /* Text field cell */
  if ([aCell respondsToSelector:@selector(setTextColor:)]) {  
    SparkApplication *application = [self application];
    
    SInt32 idx = -1;
    /* if we are displaying the defaults entries */
    if (kSparkApplicationSystemUID == [application uid]) {
      /* Global key */
      if ([entry hasVariant]) {
        idx = 1; /* bold */
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
      
      CGFloat size = [NSFont smallSystemFontSize];
      [aCell setFont:styles[idx].bold ? [NSFont boldSystemFontOfSize:size] : [NSFont systemFontOfSize:size]];
    }
  }
}

#pragma mark Drag & Drop
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
  if (![rowIndexes count])
    return NO;
  
  NSMutableDictionary *plist = [[NSMutableDictionary alloc] init];
  CFUUIDBytes bytes = CFUUIDGetUUIDBytes([[self library] uuid]);
  [plist setObject:[NSData dataWithBytes:&bytes length:sizeof(bytes)] forKey:@"uuid"];
  [pboard declareTypes:[NSArray arrayWithObject:SparkEntriesPboardType] owner:self];
  
  NSUInteger idx = 0;
  NSMutableArray *entries = [[NSMutableArray alloc] init];
  WBIndexEnumerator *indexes = [rowIndexes indexEnumerator];
  while ((idx = [indexes nextIndex]) != NSNotFound) {
    SparkEntry *entry = [self objectAtIndex:idx];
    [entries addObject:WBUInteger([entry uid])];
  }
  [plist setObject:entries forKey:@"entries"];
  [entries release];
  
  [pboard setPropertyList:plist forType:SparkEntriesPboardType];
  [plist release];
  return YES;
}

#pragma mark Context Menu
- (NSMenu *)tableView:(NSTableView *)aTableView menuForRow:(NSInteger)row {
  if (row >= 0) {
    SparkEntry *entry = [self objectAtIndex:row];
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
					[icon release];
					
					[submenu addItem:appItem];
					[appItem release];					
				}
      }
      [item setSubmenu:submenu];
      [submenu release];
      
      return [ctxt autorelease];
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
@implementation SparkEntry (SETriggerSort)

+ (void)load {
  if ([SparkEntry class] == self) {
		WBRuntimeExchangeInstanceMethods(self, @selector(setEnabled:), @selector(se_setEnabled:));
  }
}

- (NSUInteger)triggerValue {
  SparkTrigger *trigger = [self trigger];
  if ([trigger isKindOfClass:[SparkHotKey class]])
    return [(SparkHotKey *)trigger character] << 16 | [(SparkHotKey *)trigger modifier] & 0xff;
  else return 0;
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

- (void)setActiveConflictDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(SparkEntry *)previous {
	if (NSAlertDefaultReturn == returnCode) {
		[previous setEnabled:NO];
		[self performSetActive:YES document:SEGetDocumentForLibrary([[self action] library])];
	}
}

- (void)setActive:(BOOL)active {
  SELibraryDocument *document = SEGetDocumentForLibrary([[self action] library]);
  if (document) {
		/* check conflict */
		if (active) {
			SparkEntry *previous = [[[document library] entryManager] activeEntryForTrigger:[self trigger]
																																					application:[self application]];
			if (previous) {
				NSBeginAlertSheet(@"Entry conflict", 
													@"Disable previous",
													NSLocalizedString(@"Cancel", @"Cancel"),
													nil, [document windowForSheet], 
													self, @selector(setActiveConflictDidEnd:returnCode:contextInfo:), NULL, previous,
													@"'%@' already use the same shortcut.", [previous name]);
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
