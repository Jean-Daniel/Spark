//
//  KeyStrokeActionPlugin.m
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "KeyStrokeActionPlugin.h"
#import "KeyStrokeAction.h"

#import <ShadowKit/SKAppKitExtensions.h>

NSString * const kKeyStrokeActionBundleIdentifier = @"org.shadowlab.spark.keystroke";

@implementation KeyStrokeActionPlugin

- (void)awakeFromNib {
  [tableView setTarget:self];
  [tableView setDoubleAction:@selector(editKey:)];
}

- (void)dealloc {
  /* Release nib root objects */
  [keys release];
  [choosePanel setDelegate:nil];
  [choosePanel release];
  [super dealloc];
}

/* This function is called when the user open the iTunes Key Editor Panel */
- (void)loadSparkAction:(id)anAction toEdit:(BOOL)isEditing {
  [super loadSparkAction:anAction toEdit:isEditing];
  if (isEditing) {
    [keys addObjects:[anAction hotkeys]];
  } else {
    // nothing
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  NSAlert *alert = nil;
  return alert;
}

/* You need configure the new Action or modifie the existing HotKey here */
- (void)configureAction {
  [super configureAction];
  /* Get the current Key */
  KeyStrokeAction *action = [self sparkAction];
  [action setHotkeys:[keys arrangedObjects]];
}


#pragma mark -
#pragma mark IBActions
- (IBAction)up:(id)sender {
  unsigned count = [[keys arrangedObjects] count];
  unsigned idx = [keys selectionIndex];
  if (count > 0 && idx != NSNotFound && idx > 0) {
    id object = [keys selectedObject];
    [keys removeObject:object];
    [keys insertObject:object atArrangedObjectIndex:idx - 1];
  }
}

- (IBAction)down:(id)sender {
  unsigned count = [[keys arrangedObjects] count];
  unsigned idx = [keys selectionIndex];
  if (count > 0 && idx != NSNotFound && idx < (count - 1)) {
    id object = [keys selectedObject];
    [keys removeObject:object];
    [keys insertObject:object atArrangedObjectIndex:idx + 1];
  }
}

- (IBAction)editKey:(id)sender {
  ks_key = [keys selectedObject];
  if (ks_key) {
    ks_rawkey = [ks_key rawkey];
    NSString *shortcut = [ks_key shortcut];
    [shortcutField setStringValue:shortcut ? : @""];
    [choosePanel makeKeyAndOrderFront:sender];
    [NSApp runModalForWindow:choosePanel];
  } else {
    NSBeep();
  }
}

- (IBAction)insert:(id)sender {
  HKHotKey *key = [HKHotKey hotkey];
  [keys addObject:key];
  [keys setSelectedObjects:[NSArray arrayWithObject:key]];
  [self editKey:sender];
}

- (IBAction)cancelChoose:(id)sender {
  [ks_key setRawkey:ks_rawkey];
  ks_key = nil;
  [choosePanel performClose:sender];
}

#pragma mark KeyStrokeAction Specific methods
/********************************************************************************************************
*                         KeyStrokeActionPlugin & configView Specific methods							*
********************************************************************************************************/

- (void)windowWillClose:(NSNotification *)aNotification {
  ks_key = nil;
  ks_rawkey = 0;
  [NSApp stopModal];
}

- (BOOL)trapWindow:(HKTrapWindow *)window needPerformKeyEquivalent:(NSEvent *)theEvent {
  return SKFloatEquals([theEvent timestamp], 0);
}

- (BOOL)trapWindow:(HKTrapWindow *)window needProceedKeyEvent:(NSEvent *)theEvent {
  if ([ks_key keycode] == kVirtualTabKey && ([ks_key modifier] & 0x00ff0000) == 0) {
    unsigned int modifier = [theEvent modifierFlags] & 0x00ff0000;
    return ([theEvent keyCode] == kVirtualTabKey) && (modifier == 0);
  }
  return NO;
}

- (void)trapWindowCatchHotKey:(NSNotification *)aNotification {
  id info = [aNotification userInfo];
  [ks_key willChangeValueForKey:@"shortcut"];
  [ks_key setKeycode:[[info objectForKey:kHKEventKeyCodeKey] unsignedShortValue]];
  [ks_key setModifier:[[info objectForKey:kHKEventModifierKey] unsignedIntValue]];
  [ks_key setCharacter:[[info objectForKey:kHKEventCharacterKey] unsignedShortValue]];
  [ks_key didChangeValueForKey:@"shortcut"];
  NSString *shortcut = [ks_key shortcut];
  [shortcutField setStringValue:shortcut ? : @""];
}

@end
