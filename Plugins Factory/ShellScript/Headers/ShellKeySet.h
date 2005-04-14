//
//  ShellKeySet.h
//  Spark PlugIns
//
//  Created by Fox on Sat Apr 03 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SparkKit/SparkKit.h>

extern NSString * const kShellHotKeyBundleIdentifier;

#define kShellHotKeyBundle		[NSBundle bundleWithIdentifier:kShellHotKeyBundleIdentifier]

typedef enum {
  kShellTypeSh			= 0,
  kShellTypeCsh		    = 1,
  kShellTypeZsh			= 2,
  kShellTypeTcsh		= 3,
  kShellTypeBash		= 4
}ShellType;

typedef enum {
  kShellOtherFolder			= 4,
  kShellRootFolder			= 1,
  kShellHomeFolder			= 0,
  kShellFinderCurrentFolder	= 2,
  kShellCustomFolder        = 3
}WorkingFolder;

@interface ShellKeySet : SparkActionPlugIn {
  IBOutlet id optionBox;
  IBOutlet NSArrayController *environment;
  IBOutlet id workingDirPopUp;
@private
  NSString *commandLine;
  NSString *args;
  NSString *scriptName;
  NSString *scriptFile;
  ShellType shell;
  WorkingFolder workingDir;
  enum {
    kShellCommandTab,
    kShellScriptFileTab
  }shellTab;
  BOOL displayDialog;
  BOOL executeInTerm;
}

- (IBAction)toggleOptions:(id)sender;
- (IBAction)chooseScriptFile:(id)sender;
- (IBAction)chooseCurrentDirectory:(id)sender;

- (void)addCustomFolderItem:(NSString *)folder;

- (NSDictionary *)environmentDictionary;
- (void)setEnvironmentDictionary:(NSDictionary *)newEnvironment;

- (NSString *)commandLine;
- (void)setCommandLine:(NSString *)newCommandLine;
- (NSString *)args;
- (void)setArgs:(NSString *)newArgs;
- (NSString *)scriptName;
- (void)setScriptName:(NSString *)newScriptName;
- (NSString *)scriptFile;
- (void)setScriptFile:(NSString *)newScriptFile;

- (ShellType)shell;
- (void)setShell:(ShellType)newShell;
- (WorkingFolder)workingDir;
- (void)setWorkingDir:(WorkingFolder)newWorkingDir;
- (int)shellTab;
- (void)setShellTab:(int)newShellTab;
- (BOOL)displayDialog;
- (void)setDisplayDialog:(BOOL)newDisplayDialog;
- (BOOL)executeInTerm;
- (void)setExecuteInTerm:(BOOL)newExecuteInTerm;

@end
