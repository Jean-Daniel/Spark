//
//  ShellKeySet.m
//  Spark PlugIns
//
//  Created by Fox on Sat Apr 03 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "ShellKeySet.h"
#import "ShellHotKey.h"

#if defined (DEBUG)
#warning Debug defined in ShellScript!
#endif

NSString * const kShellHotKeyBundleIdentifier = @"fr.shadowlab.shellHotKey";

@implementation ShellKeySet

- (void)dealloc {
  [super dealloc];
}

- (void)initMenuIcons {
  id workspace = [NSWorkspace sharedWorkspace];
  NSSize size = NSMakeSize(16, 16);
  id menu = [workingDirPopUp menu];
  
  id item = [menu itemWithTag:kShellRootFolder];
  id icon = [workspace iconForFile:@"/"];
  [icon setSize:size];
  [item setImage:icon];
  
  item = [menu itemWithTag:kShellHomeFolder];
  icon = [workspace iconForFile:NSHomeDirectory()];
  [icon setSize:size];
  [item setImage:icon];
  
  item = [menu itemWithTag:kShellFinderCurrentFolder];
  icon = [NSImage imageNamed:@"Finder_s" inBundle:kShellHotKeyBundle];
  [icon setSize:size];
  [item setImage:icon];
}

- (void)awakeFromNib {
  float height = [configView frame].size.height - [optionBox frame].size.height;
  float width = [configView frame].size.width;
  [configView setFrameSize:NSMakeSize(width, height)];
  [optionBox setHidden:YES];
  [self initMenuIcons];
}

- (void)setHotKey:(SparkHotKey *)key {
  [super setHotKey:key];
  ShellHotKey *hotkey = (ShellHotKey *)key;
  if ([key name] == nil) {
    [self setWorkingDir:kShellHomeFolder];
    [self setShell:kShellTypeSh];
    [self setDisplayDialog:YES];
  }
  else {
    [self setEnvironmentDictionary:[hotkey env]];
    [self setShell:[hotkey shell]];
    if ([hotkey workingDir] == kShellCustomFolder) {
      [self addCustomFolderItem:[hotkey workingDirPath]];
      [self setWorkingDir:kShellCustomFolder];
    }
    else {
      [self setWorkingDir:[hotkey workingDir]];
    }
    [self setCommandLine:[hotkey cmd]];
    [self setScriptFile:[hotkey scriptFile]];
    [self setArgs:[hotkey args]];
    if (scriptFile != nil) {
      [self setShellTab:kShellScriptFileTab];
    }
    [self setDisplayDialog:[hotkey displayDialog]];
    [self setExecuteInTerm:[hotkey executeInTerm]];
  }
  [configView setAutoresizingMask:[configView autoresizingMask] | NSViewHeightSizable];
}

- (NSAlert *)controllerShouldConfigKey {
  NSAlert *alert = nil;
  switch (shellTab) {
    case kShellCommandTab:
      if (!commandLine || [[commandLine stringByTrimmingWhitespaceAndNewline] length] == 0) {
        alert = [NSAlert alertWithMessageText:@"Peut pas faire un raccourci sans commande."
                                defaultButton:@"OK"
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:@"Faut taper une commande"];
      }
      break;
    case kShellScriptFileTab:
      if (scriptFile == nil) {
        alert = [NSAlert alertWithMessageText:@"Peut pas faire un raccourci sans fichier."
                                defaultButton:@"OK"
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:@"Faut choisir un fichier"];
      }
      break;
  }
  return alert;
}

- (void)configHotKey {
  ShellHotKey *hotkey = [self hotKey];
  [hotkey setName:[self name]];
  [hotkey setIcon:[NSImage imageNamed:@"ShellKeyIcon" inBundle:kShellHotKeyBundle]];
  if (shellTab == kShellCommandTab) {
    [hotkey setCmd:[self commandLine]];
    [hotkey setShortDescription:@"Execute Single Shell Command"];
  }
  else {
    [hotkey setCmd:nil];
  }
  if (shellTab == kShellScriptFileTab) {
    [hotkey setScriptFile:[self scriptFile]];
    [hotkey setArgs:([self args] != nil) ? [self args] : @""];
    [hotkey setShortDescription:@"Execute Shell Script"];
  }
  else {
    [hotkey setScriptFile:nil];
    [hotkey setArgs:nil];
  }
  [hotkey setShell:[self shell]];
  [hotkey setWorkingDir:[self workingDir]];
  if (workingDir == kShellCustomFolder) {
    [hotkey setWorkingDirPath:[[workingDirPopUp itemAtIndex:0] representedObject]];
  }
  else {
    [hotkey setWorkingDirPath:nil];
  }
  [hotkey setEnv:[self environmentDictionary]];
  [hotkey setDisplayDialog:displayDialog];
  [hotkey setExecuteInTerm:executeInTerm];
}

- (IBAction)chooseScriptFile:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  [panel setCanChooseDirectories:NO];
  [panel setCanChooseFiles:YES];
  [panel setAllowsMultipleSelection:NO];
  [panel setCanCreateDirectories:NO];
  [panel beginSheetForDirectory:[[self scriptFile] stringByDeletingLastPathComponent]
                           file:[[self scriptFile] lastPathComponent]
                          types:nil
                 modalForWindow:[configView window]
                  modalDelegate:self
                 didEndSelector:@selector(chooseScriptFilePanelDidEnd:returnCode:context:)
                    contextInfo:nil];
}

- (void)chooseScriptFilePanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode context:(id)context {
  if (returnCode == NSOKButton) {
    [self setScriptFile:[[panel filenames] objectAtIndex:0]];
  }
}

- (IBAction)chooseCurrentDirectory:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  [panel setCanChooseDirectories:YES];
  [panel setCanChooseFiles:NO];
  [panel setCanCreateDirectories:YES];
  [panel setAllowsMultipleSelection:NO];
  id oldDir = [[NSNumber alloc] initWithInt:workingDir];
  [self setWorkingDir:kShellOtherFolder];
  [panel beginSheetForDirectory:nil
                           file:nil
                          types:nil
                 modalForWindow:[configView window]
                  modalDelegate:self
                 didEndSelector:@selector(chooseCurrentFolderPanelDidEnd:returnCode:workingDir:)
                    contextInfo:oldDir];
}

- (void)addCustomFolderItem:(NSString *)folder {
  NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[folder lastPathComponent] action:nil keyEquivalent:@""];
  [item setTag:kShellCustomFolder];
  [item setRepresentedObject:folder];
  id icon = [[NSWorkspace sharedWorkspace] iconForFile:folder];
  [icon setSize:NSMakeSize(16, 16)];
  [item setImage:icon];
  id menu = [workingDirPopUp menu];
  if ([workingDirPopUp indexOfItemWithTag:kShellCustomFolder] == -1) {
    [menu insertItem:[NSMenuItem separatorItem] atIndex:0];
  }
  else {
    [menu removeItemAtIndex:0];
  }
  [menu insertItem:item atIndex:0];
  [item release];
}

- (void)chooseCurrentFolderPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode workingDir:(id)oldWorkingDir {
  if (returnCode == NSCancelButton) {
    [self setWorkingDir:[oldWorkingDir intValue]];
  }
  else {
    id dir = [[panel filenames] objectAtIndex:0];
    [self addCustomFolderItem:dir];
    [self setWorkingDir:kShellCustomFolder];
  }
  [oldWorkingDir release];
}

- (IBAction)toggleOptions:(id)sender {
  NSRect winFrame = [[sender window] frame];
  float delta = [optionBox frame].size.height;
  if ([sender state]) {
    winFrame.size.height += delta;
    winFrame.origin.y -= delta;
    [optionBox setHidden:NO];
  }
  else {
    winFrame.size.height -= delta;
    winFrame.origin.y += delta;
  }
  [[sender window] setFrame:winFrame display:YES animate:YES];
  [optionBox setHidden:![sender state]];
}

- (NSDictionary *)environmentDictionary {
  NSMutableDictionary *env = [NSMutableDictionary dictionary];
  id items = [[environment arrangedObjects] objectEnumerator];
  id item;
  while (item = [items nextObject]) {
    id value = [item objectForKey:@"value"];
    id key = [item objectForKey:@"name"];
    if (key)
      [env setObject:(value != nil) ? value : @"" forKey:key];
  }
  return env;
}

- (void)setEnvironmentDictionary:(NSDictionary *)newEnvironment {
  id keys = [newEnvironment keyEnumerator];
  id key;
  while (key = [keys nextObject]) {
    id dico = [[NSDictionary alloc] initWithObjectsAndKeys:key, @"name", [newEnvironment objectForKey:key], @"value", nil];
    [environment addObject:dico];
    [dico release];
  }
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
- (NSString *)commandLine {
  return commandLine;
}
- (void)setCommandLine:(NSString *)newCommandLine {
  if (commandLine != newCommandLine) {
    [commandLine release];
    commandLine = [newCommandLine retain];
  }
}

- (NSString *)args {
  return args;
}
- (void)setArgs:(NSString *)newArgs {
  if (args != newArgs) {
    [args release];
    args = [newArgs retain];
  }
}

- (NSString *)scriptName {
  return scriptName;
}
- (void)setScriptName:(NSString *)newScriptName {
  if (scriptName != newScriptName) {
    [scriptName release];
    scriptName = [newScriptName retain];
  }
}

- (NSString *)scriptFile {
  return scriptFile;
}
- (void)setScriptFile:(NSString *)newScriptFile {
  if (scriptFile != newScriptFile) {
    [scriptFile release];
    scriptFile = [newScriptFile retain];
    [self setScriptName:[scriptFile lastPathComponent]];
  }
}

- (ShellType)shell {
  return shell;
}
- (void)setShell:(ShellType)newShell {
  shell = newShell;
}

- (WorkingFolder)workingDir {
  return workingDir;
}
- (void)setWorkingDir:(WorkingFolder)newWorkingDir {
  workingDir = newWorkingDir;
}

- (int)shellTab {
  return shellTab;
}
- (void)setShellTab:(int)newShellTab {
  shellTab = newShellTab;
}
- (BOOL)displayDialog {
  return displayDialog;
}
- (void)setDisplayDialog:(BOOL)newDisplayDialog {
  displayDialog = newDisplayDialog;
}

- (BOOL)executeInTerm {
  return executeInTerm;
}
- (void)setExecuteInTerm:(BOOL)newExecuteInTerm {
  executeInTerm = newExecuteInTerm;
}


@end
