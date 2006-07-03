//
//  KeyEditorController.m
//  Spark
//
//  Created by Fox on Sat Dec 13 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "KeyEditorController.h"

#import "Spark.h"
#import <SparkKit/SparkKit.h>
#import <HotKeyToolKit/HotKeyToolKit.h>

#import "Extensions.h"
#import "ChoosePanel.h"
#import "Preferences.h"
#import "ActionEditor.h"
#import "AppActionEditor.h"
#import "CustomTableView.h"
#import "CustomTableDataSource.h"

static NSComparisonResult CompareMapEntries(id obj1, id obj2, void *controller);

@implementation KeyEditorController

- (id)init {
  if (self = [super initWithWindowNibName:@"KeyEditor"]) {
    _hotKey = [[SparkHotKey alloc] init];
    _actionsSizes = [[NSMutableDictionary alloc] init];
    [self setKeyName:nil];
    [self setKeyComment:nil];
    [self window];
  }
  return self;
}

- (void)dealloc {
  [_hotKey release];
  [_keyName release];
  [_keyComment release];
  [_actionsSizes release];
  [super dealloc];
}

- (void)windowDidLoad {
  [super windowDidLoad];
  HKTrapWindow *window = (id)[self window];
  [window setVerifyHotKey:YES];
}

- (void)awakeFromNib {
  [mapTable setTarget:self];
  [mapTable setDoubleAction:@selector(mapTableDoubleAction:)];
  [[tabView tabViewItemAtIndex:2] setView:actionView];
  [mapArray setCompareFunction:CompareMapEntries];
  [mapArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
    [SparkApplicationLibrary systemApplication], @"application",
    [SparkActionLibrary ignoreAction], @"action",
    nil]];
  id menu = [actionEditor pluginMenu];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItemWithTitle:NSLocalizedStringFromTable(@"CHOOSE_EXISTING_ACTION_MENU",
                                                    @"Editors", @"Key Editor Plugin-Menu")
                  action:@selector(chooseExistingAction:)
           keyEquivalent:@""];
}

- (IBAction)chooseExistingAction:(id)sender {
  id panel = [[ChoosePanel alloc] initWithObjectType:kSparkAction];
  [NSApp beginSheet:[panel window]
     modalForWindow:[self window]
      modalDelegate:self
     didEndSelector:@selector(chooserDidEnd:returnCode:context:)
        contextInfo:nil];
}

- (void)chooserDidEnd:(NSWindow *)window returnCode:(int)returnCode context:(id)ctxt {
  id panel = [window windowController];
  id object = [panel object];
  if (object && object != SparkIgnoreAction()) {
    [actionEditor setSparkAction:object];
  } else {
    [actionEditor selectActionPlugin:[actionEditor selectedPlugin]];
  }
  [panel autorelease];
}

- (BOOL)isStandardKeyEditor {
  return !_advanced;
}

- (void)loadApplicationsMapForKey:(SparkHotKey *)hotkey {
  [mapArray removeAllObjects];
  
  if (![_hotKey defaultAction]) {
    [_hotKey setDefaultAction:SparkIgnoreAction()];
  }  
  
  id map = [hotkey map];
  id items = [[NSMutableSet alloc] initWithSet:[map applications]];
  [items addObjectsFromArray:[[map lists] allObjects]];
  id appli = [items objectEnumerator];
  id app;
  while (app = [appli nextObject]) {
    id action = [map actionForEntry:app];
    [mapArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
      app, @"application",
      action, @"action",
      nil]];
  }
  [items release];
  [mapArray rearrangeObjects];
  [mapArray setSelectionIndex:0];
}

- (id)object {
  return _hotKey;
}
- (void)setObject:(id)newKey {
  if (_hotKey != newKey) {
    [self willChangeValueForKey:@"shortCut"];
    [super setObject:newKey];
    [_hotKey release];
    _hotKey = [newKey retain];
    [self didChangeValueForKey:@"shortCut"];
    id undo = [self undoManager];
    [[undo prepareWithInvocationTarget:_hotKey] setRawkey:[_hotKey rawkey]];
    //[[undo prepareWithInvocationTarget:_hotKey] setModifier:[_hotKey modifier]];
    
    [self setKeyName:[_hotKey name]];
    [self setKeyComment:[_hotKey comment]];
    /* Extracting actions */
    [mapArray removeAllObjects];
    if ([_hotKey isInvalid]) {
      [actionEditor selectActionPlugin:nil];
      [self toggleAdvancedModeView:nil];
      [self loadApplicationsMapForKey:_hotKey];
    } else if ([_hotKey hasManyActions]) {
      id action = [_hotKey defaultAction];
      if ([[action uid] unsignedIntValue]) /* if not IgnoreAction  */
        [actionEditor setSparkAction:action];
      [self toggleAdvancedModeView:nil];
      [self loadApplicationsMapForKey:_hotKey];
    } else if ([_hotKey defaultAction]) {
      [actionEditor setSparkAction:[_hotKey defaultAction]];
      [mapArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
        SparkSystemApplication(), @"application",
            ([[_hotKey defaultAction] isCustom]) ? [_hotKey defaultAction] : SparkIgnoreAction(), @"action",
        nil]];
    }
  }
}

/* Check if user choose a name and a keystroke */
- (BOOL)checkHotKey {
  id alert = nil;
  if (![_hotKey isValid]) {
    alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"CREATE_KEY_WITHOUT_SHORTCUT_ALERT",
                                                                     @"Editors", @"HotKey Editor - No Shortcut")
                            defaultButton:NSLocalizedStringFromTable(@"OK",
                                                                     @"Editors", @"Alert default button")
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:NSLocalizedStringFromTable(@"CREATE_KEY_WITHOUT_SHORTCUT_ALERT_MSG",
                                                                     @"Editors", @"HotKey Editor - No Shortcut")];
  } else if ([[_keyName stringByTrimmingWhitespaceAndNewline] length] == 0) {
    alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"CREATE_KEY_WITHOUT_NAME_ALERT",
                                                                     @"Editors", @"HotKey Editor - No Name")
                            defaultButton:NSLocalizedStringFromTable(@"OK",
                                                                     @"Editors", @"Alert default button")
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:NSLocalizedStringFromTable(@"CREATE_KEY_WITHOUT_NAME_ALERT_MSG",
                                                                     @"Editors", @"HotKey Editor - No Name")];
  } else if (![self isStandardKeyEditor]) { /* If Custom Editor Only */
    BOOL ok = NO;
    id actions = [mapArray objectEnumerator];
    id entry;
    while ((entry = [actions nextObject]) && !ok) {
      id action = [entry objectForKey:@"action"];
      ok = (action != nil) && (action != SparkIgnoreAction());
    }
    if (!ok) {
      alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"CREATE_KEY_WITH_IGNORE_ACTION_ALERT",
                                                                       @"Editors", @"HotKey Editor - No Action")
                              defaultButton:NSLocalizedStringFromTable(@"OK",
                                                                       @"Editors", @"Alert default button")
                            alternateButton:nil
                                otherButton:nil
                  informativeTextWithFormat:NSLocalizedStringFromTable(@"CREATE_KEY_WITH_IGNORE_ACTION_ALERT_MSG",
                                                                       @"Editors", @"HotKey Editor - No Action")];
    }
  }
  if (alert) {
    [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
    return NO;
  }
  return YES;
}

- (BOOL)configureHotKey {
  id alert;
  if ([self isStandardKeyEditor]) {
    if (alert = ([self isUpdating]) ? [actionEditor update] : [actionEditor create]) { /* Si pb avec l'action */
      [toolbar selectCellAtRow:0 column:0];
      [self changeTab:toolbar];
      [alert beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
      return NO;
    }
    id action = [actionEditor sparkAction];
    [self setKeyName:[action name]];
    if ([self checkHotKey]) {
      if (![action uid])
        [SparkDefaultActionLibrary() addObject:action];
      [_hotKey setName:_keyName];
      [_hotKey setIcon:[action icon]];
      [_hotKey setComment:_keyComment];
      if ([_hotKey hasManyActions])
        [_hotKey removeAllActions];
      [_hotKey setDefaultAction:action];
      return YES;
    }
  } else {
    /* Configure Multiple Actions */
    if ([self checkHotKey]) {
      [_hotKey setName:_keyName];
      [_hotKey setIcon:nil];
      [_hotKey setComment:_keyComment];
      if ([_hotKey hasManyActions])
        [_hotKey removeAllActions];
      /* Else removing all action will remove our default action from Library (if not custom), and we wouldn't that 
         append if we are just updating the default action and not replacing it */ 
      if ([[mapArray arrangedObjects] count] == 1) {
        id action = [[[mapArray arrangedObjects] objectAtIndex:0] objectForKey:@"action"];
        [_hotKey setIcon:[action icon]];
        [_hotKey setDefaultAction:action];
      } else {
        id actions = [mapArray objectEnumerator];
        id object;
        while (object = [actions nextObject]) {
          id app = [object objectForKey:@"application"];
          id action = [object objectForKey:@"action"];
          if ([app isKindOfClass:[SparkObjectList class]]) {
            [_hotKey setAction:action forApplicationList:app];
          } else if ([app isKindOfClass:[SparkApplication class]]) {
            [_hotKey setAction:action forApplication:app];
          }
        }
      }
      return YES;
    }
  }
  return NO;
}

- (IBAction)create:(id)sender {
  if ([self configureHotKey]) {
    [super create:sender];
  }
}

- (IBAction)update:(id)sender {
  if ([self configureHotKey]) {
    [super update:sender];
  }
}

- (IBAction)showPlugInHelp:(id)sender {
  [[NSApp delegate] showPlugInHelpPage:[[self window] title]];
}

- (IBAction)toggleAdvancedModeView:(id)sender {
  _advanced = !_advanced;
  /* Avant de passer en mode avancŽ, on charge un plugin (sinon pb de taille pour la suite) */
  if (_advanced) {
    [advancedButton setImage:[NSImage imageNamed:@"Simple"]];
    if ([actionEditor selectedPlugin] == nil) {
      [self selectActionPlugin:nil];
    }
    [helpButton setHidden:NO];
  } else {
    [advancedButton setImage:[NSImage imageNamed:@"Advanced"]];
    [helpButton setHidden:![actionEditor helpAvailable]];
  }
  [toolbar selectCellAtRow:0 column:0];
  [self changeTab:toolbar];
}

#pragma mark Accessors
- (NSString *)keyName {
  return _keyName;
}
- (void)setKeyName:(NSString *)newKeyName {
  if (_keyName != newKeyName) {
    [_keyName release];
    _keyName = [newKeyName copy];
  }
}

- (NSString *)keyComment {
  return _keyComment;
}
- (void)setKeyComment:(NSString *)newKeyComment {
  if (_keyComment != newKeyComment) {
    [_keyComment release];
    _keyComment = [newKeyComment copy];
  }
}

- (NSString *)shortCut {
  return [_hotKey shortCut];
}
- (void)setShortCut:(NSString *)shortcut {
}

#pragma mark -
- (void)windowWillClose:(NSNotification *)aNotification {
  [objectController setContent:nil];
}

#pragma mark -
#pragma mark Action Editor

- (IBAction)openHelp:(id)sender {
  if (!_advanced)
    [actionEditor showPluginHelp:sender];
  else {
    [[NSHelpManager sharedHelpManager] openHelpAnchor:@"SparkMultipleActionsKey"
                                               inBook:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"]];
  }
}

- (SparkPlugIn *)selectedPlugin {
  return [actionEditor selectedPlugin];
}

- (void)selectActionPlugin:(SparkPlugIn *)plugin {
  [actionEditor selectActionPlugin:plugin];
}

- (void)actionEditorDidChangePlugin:(NSNotification *)aNotification {
  [helpButton setHidden:![actionEditor helpAvailable]];
}

- (NSSize)actionEditor:(ActionEditor *)sender willResize:(NSSize)proposedFrameSize forView:(NSView *)aView {
  id key = [NSValue valueWithPointer:aView];
  id min = [_actionsSizes objectForKey:key];
  if (!min) {
    min = [NSValue valueWithSize:[[self window] minSize]];
    [_actionsSizes setObject:min forKey:key];
  }
  if ([tabView indexOfSelectedTabViewItem] == 0) {
    windowState[0].minSize = [min sizeValue];
    windowState[0].currentSize = [[self window] frame].size;
    windowState[0].maxSize = [[self window] maxSize];
  }
  return proposedFrameSize;
}

#pragma mark -
#pragma mark Toolbar

- (IBAction)changeTab:(id)sender {
  int newIndex = [toolbar selectedColumn];
  if (newIndex == 0 && _advanced) {
    newIndex = 2;
  }
  int oldIndex = [tabView indexOfSelectedTabViewItem];
  if (oldIndex != newIndex) {
    /* Save Window state */
    windowState[oldIndex].minSize = [[self window] minSize];
    windowState[oldIndex].currentSize = [[self window] frame].size;
    windowState[oldIndex].maxSize = [[self window] maxSize];
    
    NSSize oldSize, newSize;
    /* If new index was already saved */
    if (windowState[newIndex].currentSize.width != 0) {
      oldSize = windowState[oldIndex].currentSize;
      newSize = windowState[newIndex].currentSize;
    } else {
      oldSize = [[[tabView tabViewItemAtIndex:oldIndex] view] frame].size;
      newSize = [[[tabView tabViewItemAtIndex:newIndex] view] frame].size;
    }
    /* delta between new and old */
    float deltaW = newSize.width - oldSize.width;
    float deltaH = newSize.height - oldSize.height;
    /* New window frame & position */
    NSRect win = [[self window] frame];
    win.size.width += deltaW;
    win.origin.x -= deltaW / 2;
    win.size.height += deltaH;
    win.origin.y -= deltaH;
    /* Select blank item */
    [tabView selectTabViewItemAtIndex:3];
    /* Resize window */
    [[self window] setFrame:win display:YES animate:YES];
    /* Select target tab */
    [tabView selectTabViewItemAtIndex:newIndex];
    /* if size not already saved */
    if (0 == windowState[newIndex].minSize.width) {
      /* Set min size to window size */
      windowState[newIndex].minSize = [[self window] frame].size; 
      /* Set max to max float */
      windowState[newIndex].maxSize = NSMakeSize(MAXFLOAT, MAXFLOAT);
    }
    NSSize minWinSize = windowState[newIndex].minSize;
    NSSize maxWinSize = windowState[newIndex].maxSize;
    /* Set min and max size */
    [[self window] setMinSize:minWinSize];
    [[self window] setMaxSize:maxWinSize];
    /* Set resizable */
    BOOL resizable = (minWinSize.width != maxWinSize.width) || (minWinSize.height != maxWinSize.height);
    [[self window] setShowsResizeIndicator:resizable];
  }
}

#pragma mark -
#pragma mark HKTrapWindow Delegate

- (NSUndoManager *)undoManagerForActionEditor:(ActionEditor *)editor {
  return [self undoManager];
}

- (BOOL)trapWindow:(HKTrapWindow *)window needPerformKeyEquivalent:(NSEvent *)theEvent {
  return [theEvent timestamp] == 0;
}

- (BOOL)trapWindow:(HKTrapWindow *)window needProceedKeyEvent:(NSEvent *)theEvent {
  if (kSparkEnableAllSingleKey == SparkKeyStrokeFilterMode) {
    /* Anti trap hack. If pressed tab two time, second tab is proceed */
    if ([_hotKey keycode] == kVirtualTabKey && ([_hotKey modifier] & 0x00ff0000) == 0) {
      unsigned int modifier = [theEvent modifierFlags] & 0x00ff0000;
      return ([theEvent keyCode] == kVirtualTabKey) && (modifier == 0);
    }
    /* Single Key enable for all */
    return NO;
  }
  int code = [theEvent keyCode];
  int mask = [theEvent modifierFlags] & 0x00ff0000;
  return mask ? NO : (code == kVirtualEnterKey)
    || (code == kVirtualReturnKey)
    || (code == kVirtualEscapeKey)
    || (code == kVirtualTabKey);
}

- (void)trapWindowCatchHotKey:(NSNotification *)aNotification {
  id info = [aNotification userInfo];
  [self willChangeValueForKey:@"shortCut"];
  [_hotKey setModifier:[[info objectForKey:kHKEventModifierKey] unsignedIntValue]];
  [_hotKey setKeycode:[[info objectForKey:kHKEventKeyCodeKey] unsignedShortValue]];
//         andCharacter:[[info objectForKey:kHKEventCharacterKey] unsignedShortValue]];
  [self didChangeValueForKey:@"shortCut"];
}

#pragma mark -
#pragma mark Application Table Data Source

- (IBAction)newMapEntry:(id)sender {
  id editor = [[AppActionEditor alloc] init];
  [editor setDelegate:self];
  [NSApp beginSheet:[editor window]
     modalForWindow:[self window]
      modalDelegate:nil
     didEndSelector:nil
        contextInfo:nil];
}

- (IBAction)mapTableDoubleAction:(id)sender {
  int row = [sender clickedRow];
  if (row > -1) {
    editedObject = [[mapArray arrangedObjects] objectAtIndex:row];
    id editor = [[AppActionEditor alloc] init];
    [editor setObject:editedObject];
    [editor setDelegate:self];
    [NSApp beginSheet:[editor window]
       modalForWindow:[self window]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
  }
}

- (IBAction)deleteApplications:(id)sender {
  [mapArray removeSelectionIndexes:[NSIndexSet indexSetWithIndex:0]];
  [mapArray remove:sender];
  if ([mapArray selectionIndex] == NSNotFound) {
    [mapArray setSelectionIndex:0];
  }
}

- (void)deleteSelectionInTableView:(CustomTableView *)view {
  [self deleteApplications:view];
}

- (BOOL)appActionEditor:(AppActionEditor *)editor willValidateObject:(id)object {
  id old = [editedObject objectForKey:@"application"];
  id new = [object objectForKey:@"application"];
  BOOL hasChange = NO;
  if (old) { /* check if class change or identifier/uid change */
    hasChange = [old class] != [new class];
    if (!hasChange) {
      if ([old respondsToSelector:@selector(identifier:)])
        hasChange = ![[old identifier] isEqualToString:[new identifier]];
      else 
        hasChange = ![[old uid] isEqualToNumber:[new uid]];
    }
  }
  if (old == nil || hasChange) {
    Class class = [new class];
    id key = ([new isKindOfClass:[SparkObjectList class]]) ? @"uid" : @"identifier";
    id value =  [new valueForKey:key];
    
    id items = [mapArray objectEnumerator];
    id entry;
    while (entry = [items nextObject]) {
      id item = [entry objectForKey:@"application"];
      if ([item isKindOfClass:class] && [[item valueForKey:key] isEqualTo:value]) {
        id alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:
          NSLocalizedStringFromTable(@"CONFIRM_REPLACE_MAP_ENTRY",
                                     @"Editors", @"Map Entry Exists"), [item name]]
                                   defaultButton:NSLocalizedStringFromTable(@"CONFIRM_REPLACE_MAP_ENTRY_REPLACE",
                                                                            @"Editors", @"Map Entry Exists")
                                 alternateButton:NSLocalizedStringFromTable(@"CONFIRM_REPLACE_MAP_ENTRY_CANCEL",
                                                                            @"Editors", @"Map Entry Exists")
                                     otherButton:nil
                       informativeTextWithFormat:NSLocalizedStringFromTable(@"CONFIRM_REPLACE_MAP_ENTRY_MSG",
                                                                            @"Editors", @"Map Entry Exists")];
        int result = [alert runSheetModalForWindow:[editor window]];
        if (result == NSOKButton) {
          [mapArray removeObject:entry];
          return YES;
        } else {
          return NO;
        }
      }
    }
  }
  return YES;
}

- (void)objectEditor:(ObjectEditorController *)editor createObject:(id)object {
  [mapArray addObject:object];
}

- (void)objectEditor:(ObjectEditorController *)editor updateObject:(id)object {
  if ([editedObject objectForKey:@"application"] == SparkSystemApplication()) {
    if (!([object objectForKey:@"application"] == SparkSystemApplication())) {
      [editedObject setValue:[SparkActionLibrary ignoreAction] forKey:@"action"];
      [mapArray addObject:object];
      return;
    }
  }
  [editedObject addEntriesFromDictionary:object];
  editedObject = nil;
}

- (void)objectEditorWillClose:(NSNotification *)aNotification {
  id editor = [aNotification object];
  [editor autorelease];
  editedObject = nil;
}

@end

static NSComparisonResult CompareMapEntries(id obj1, id obj2, void *controller) {
  id sorts = [(id)controller sortDescriptors];
  if ([[[obj1 objectForKey:@"application"] uid] unsignedIntValue] == 0) {
    return NSOrderedAscending;
  } else if ([[[obj2 objectForKey:@"application"] uid] unsignedIntValue] == 0) {
    return NSOrderedDescending;
  }
  NSComparisonResult result = NSOrderedSame;
  unsigned i;
  for (i=0; i<[sorts count] && NSOrderedSame == result; i++) {
    id sort = [sorts objectAtIndex:i];
    id path = [sort key];
    result = (NSComparisonResult)[[obj1 valueForKeyPath:path] performSelector:[sort selector] withObject:[obj2 valueForKeyPath:path]];
    if (![sort ascending]) result = -result;
  }
  return result;
}
