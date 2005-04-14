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

NSString * const kKeyStrokeActionBundleIdentifier = @"fr.shadowlab.keyStrokeAction";

@implementation KeyStrokeActionPlugin

static id MenuItemForApplication(NSString *path) {
  id item = [[NSMenuItem alloc] init];
  [item setRepresentedObject:path];
  id image = [[NSWorkspace sharedWorkspace] iconForFile:path];
  [image setSize:NSMakeSize(16, 16)];
  [item setImage:image];
  [item setTitle:[[[NSFileManager defaultManager] displayNameAtPath:path] stringByDeletingPathExtension]];
  return [item autorelease];
}

- (void)awakeFromNib {
  int index = [applicationMenu indexOfItem:[[applicationMenu menu] itemWithTag:1]] + 1;
  id apps = [[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
  id app;
  while (app = [apps nextObject]) {
    id item = MenuItemForApplication([app objectForKey:@"NSApplicationPath"]);
    [item setTitle:[app objectForKey:@"NSApplicationName"]];
    [[applicationMenu menu] insertItem:item atIndex:index];
  }
}

/* This function is called when the user open the iTunes Key Editor Panel */
- (void)loadSparkAction:(id)anAction toEdit:(BOOL)isEditing {
  [super loadSparkAction:anAction toEdit:isEditing];
  if (isEditing) {
    [self setKeystroke:[anAction keystroke]];
    [self setKeyModifier:[anAction keyModifier]];
  }
  else {
    [self setKeyModifier:1];
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  NSAlert *alert = nil;
  if ([keystroke length] != 1) {
    alert = [NSAlert alertWithMessageText:@"Spark ne peut pas creer le raccourci parce que keystroke n'a pas une valeur valide."
                            defaultButton:@"OK"
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:@"Keystroke doit etre un et un seul caractere. Attention, les majuscules sont prisent en compte."];
  }
  return alert;
}

/* You need configure the new Action or modifie the existing HotKey here */
- (void)configureAction {
  /* Get the current Key */
  KeyStrokeAction *action = [self sparkAction];
  /* Set Name */
  [action setName:[self name]];
  [action setKeystroke:[self keystroke]];
  [action setKeyModifier:[self keyModifier]];
}

- (IBAction)selectApplication:(id)sender {
  int tag = [[sender selectedItem] tag];
  if (tag == 3) {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanCreateDirectories:NO];
    
    [oPanel beginSheetForDirectory:nil
                              file:nil
                             types:[NSArray arrayWithObjects:@"app", @"APPL", nil]
                    modalForWindow:[sender window]
                     modalDelegate:self
                    didEndSelector:@selector(selectApplicationDidEnd:returnCode:contextInfo:)
                       contextInfo:nil];
  }
}

- (void)selectApplicationDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (NSOKButton == returnCode) {
    int index = [applicationMenu indexOfItem:[[applicationMenu menu] itemWithTag:1]] + 1;
    id path = [[sheet filenames] objectAtIndex:0];
    id items = [[applicationMenu itemArray] objectEnumerator];
    id item;
    while (item = [items nextObject]) {
      if ([[item representedObject] isEqual:path]) break;
    }
    if (nil == item) {
      item = MenuItemForApplication([[sheet filenames] objectAtIndex:0]);
      [[applicationMenu menu] insertItem:item atIndex:index];
    }
    [applicationMenu selectItem:item];
  }
}

#pragma mark -
#pragma mark KeyStrokeActionPlugin & configView Specific methods
/********************************************************************************************************
*                             KeyStrokeActionPlugin & configView Specific methods								*
********************************************************************************************************/

- (id)keystroke {
  return [[keystroke retain] autorelease];
}

- (void)setKeystroke:(id)newKeystroke {
  if (keystroke != newKeystroke) {
    [keystroke release];
    keystroke = [newKeystroke retain];
  }
}

- (int)keyModifier {
  return keyModifier;
}

- (void)setKeyModifier:(int)newKeyModifier {
  keyModifier = newKeyModifier;
}


@end
