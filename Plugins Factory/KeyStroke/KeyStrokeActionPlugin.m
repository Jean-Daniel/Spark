//
//  KeyStrokeActionPlugin.m
//  Spark
//
//  Created by Fox on Sun Feb 15 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#if defined (DEBUG)
#warning Debug defined in KeyStrokeAction!
#endif

#import "KeyStrokeActionPlugin.h"
#import "KeyStrokeAction.h"

NSString * const kKeyStrokeActionBundleIdentifier = @"org.shadowlab.spark.keystroke";

@implementation KeyStrokeActionPlugin

- (void)awakeFromNib {
}

- (void)dealloc {
  [ks_hotkey release];
  [super dealloc];
}

/* This function is called when the user open the iTunes Key Editor Panel */
- (void)loadSparkAction:(id)anAction toEdit:(BOOL)isEditing {
  [super loadSparkAction:anAction toEdit:isEditing];
  if (isEditing) {
    [self willChangeValueForKey:@"shortcut"];
    ks_hotkey = [anAction hotkey];
    [self didChangeValueForKey:@"shortcut"];
  } else {
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
  [action setHotkey:ks_hotkey];
}


#pragma mark -
#pragma mark KeyStrokeActionPlugin & configView Specific methods
/********************************************************************************************************
*                         KeyStrokeActionPlugin & configView Specific methods							*
********************************************************************************************************/

- (NSString *)shortcut {
  return [ks_hotkey shortCut];
}

- (BOOL)trapWindow:(HKTrapWindow *)window needPerformKeyEquivalent:(NSEvent *)theEvent {
  return [theEvent timestamp] == 0;
}

- (BOOL)trapWindow:(HKTrapWindow *)window needProceedKeyEvent:(NSEvent *)theEvent {
  int code = [theEvent keyCode];
  int mask = [theEvent modifierFlags] & 0x00ff0000;
  return mask ? NO : (code == kVirtualEnterKey)
    || (code == kVirtualReturnKey)
    || (code == kVirtualEscapeKey)
    || (code == kVirtualTabKey);
}

- (void)trapWindowCatchHotKey:(NSNotification *)aNotification {
  id info = [aNotification userInfo];
  [self willChangeValueForKey:@"shortcut"];
  [ks_hotkey setModifier:[[info objectForKey:kHKEventModifierKey] unsignedIntValue]];
  [ks_hotkey setKeycode:[[info objectForKey:kHKEventKeyCodeKey] unsignedShortValue]
           andCharacter:[[info objectForKey:kHKEventCharacterKey] unsignedShortValue]];
  [self didChangeValueForKey:@"shortcut"];
}

@end
