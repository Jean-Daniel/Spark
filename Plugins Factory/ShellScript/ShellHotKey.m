//
//  ShellHotKey.m
//  Spark PlugIns
//
//  Created by Fox on Sat Apr 03 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "ShellHotKey.h"
#import "ShellKeySet.h"

NSString * const kShellHotKeyCommandKey = @"Command";

NSString * const kShellHotKeyScriptFileKey = @"Script Alias";
NSString * const kShellHotKeyArgsKey = @"Arguments";

NSString * const kShellHotKeyShellKey = @"Shell";
NSString * const kShellHotKeyWorkingDirKey = @"Dir";
NSString * const kShellHotKeyWorkignDirPathKey = @"DirPath";
NSString * const kShellHotKeyEnvironmentKey = @"Environment";
NSString * const kShellHotKeyDisplayDialogKey = @"Dialog";
NSString * const kShellHotKeyTerminalKey = @"Terminal";

@implementation ShellHotKey

- (id)initFromPropertyList:(NSDictionary *)plist {
  if (self = [super initFromPropertyList:plist]) {
    [self setCmd:[plist objectForKey:kShellHotKeyCommandKey]];
    if (cmd == nil) {
      [self setScriptAlias:[SKAlias aliasWithData:[plist objectForKey:kShellHotKeyScriptFileKey]]];
      [self setArgs:[plist objectForKey:kShellHotKeyArgsKey]];
    }
    [self setShell:[[plist objectForKey:kShellHotKeyShellKey] intValue]];
    [self setWorkingDir:[[plist objectForKey:kShellHotKeyWorkingDirKey] intValue]];
    [self setWorkingDirPath:[plist objectForKey:kShellHotKeyWorkignDirPathKey]];
    [self setEnv:[plist objectForKey:kShellHotKeyEnvironmentKey]];
    [self setDisplayDialog:[[plist objectForKey:kShellHotKeyDisplayDialogKey] boolValue]];
    [self setExecuteInTerm:[[plist objectForKey:kShellHotKeyTerminalKey] boolValue]];
  }
  return self;
}

- (void)dealloc {
  [cmd release];
  [env release];
  [workingDirPath release];
  [scriptFile release];
  [args release];
  [super dealloc];
}

- (NSMutableDictionary *)propertyList {
  NSMutableDictionary *plist = [super propertyList];
  if (cmd != nil) {
    [plist setObject:cmd forKey:kShellHotKeyCommandKey];
  }
  if (scriptFile != nil) {
    id data;
    if (data = [scriptFile data])
      [plist setObject:data forKey:kShellHotKeyScriptFileKey];
    if (args != nil)
      [plist setObject:args forKey:kShellHotKeyArgsKey];
  }
  [plist setObject:SKInt(shell) forKey:kShellHotKeyShellKey];
  [plist setObject:SKInt(workingDir) forKey:kShellHotKeyWorkingDirKey];
  if (workingDirPath != nil) {
    [plist setObject:workingDirPath forKey:kShellHotKeyWorkignDirPathKey];
  }
  [plist setObject:env forKey:kShellHotKeyEnvironmentKey];
  [plist setObject:SKBool(displayDialog) forKey:kShellHotKeyDisplayDialogKey];
  [plist setObject:SKBool(executeInTerm) forKey:kShellHotKeyTerminalKey];
  return plist;
}

- (SparkAlert *)check {
  SparkAlert *alert = nil;
  if (scriptFile == nil && cmd == nil) {
    alert = [SparkAlert alertWithMessageText:@"The ShellScript HotKey is not valid."
                   informativeTextWithFormat:@"Neither command nor script file are set. You can edit this HotKey by launching Spark."];
  }
  else if (scriptFile && ![[NSFileManager defaultManager] fileExistsAtPath:[scriptFile path]]) {
    alert = [SparkAlert alertWithMessageText:@"The ShellScript HotKey is not valid."
                   informativeTextWithFormat:@"The Script file cannot be found. You can edit this HotKey by launching Spark."];
  }
  else if (workingDirPath && ![[NSFileManager defaultManager] fileExistsAtPath:workingDirPath]) {
    alert = [SparkAlert alertWithMessageText:@"The ShellScript HotKey is not valid."
                   informativeTextWithFormat:@"The Working Directory Ç%@È cannot be found. You can edit this HotKey by launching Spark.", [workingDirPath lastPathComponent]];
  }
  return alert;
}

- (void)executeInTerminal {
  [self launchTerminal];
  NSMutableString *script = [NSMutableString string];
  [script appendString:@"cd \""];
  [script appendString:[self workingDirectoryPath]];
  [script appendString:@"\";"];
  [script appendString:[self shellPath]];
  if (cmd != nil) {
    [script appendString:@" -c \""];
    NSString *argStr = [self argsStringForString:cmd];
    [script appendString:argStr];
    NSRange strRange = NSMakeRange([script length] - [argStr length], [argStr length]);
    [script replaceOccurrencesOfString:@"'" withString:@"\'" options:0 range:strRange];
    [script appendString:@"\""];
  }
  else {
    [script appendString:@" "];
    [script appendString:[scriptFile path]];
    [script appendString:@" \""];
    [script appendString:[self argsStringForString:args]];
    [script appendString:@"\""];
  }
  AppleEvent theEvent = {typeNull, nil};
  OSStatus err = ShadowAECreateEvent('trmx', 'core', 'dosc', &theEvent);
  if (noErr == err) {
    const char *scriptStr = [script UTF8String];
    err = AEPutParamPtr(&theEvent,
                        keyDirectObject,
                        typeUTF8Text,
                        scriptStr,
                        strlen(scriptStr));
  }
  if (noErr == err) {
    AEDesc result;
    ShadowAESendEventReturnAEDesc(&theEvent, '****', &result);
    NSLog(@"sended");
    ShadowAEDisposeDesc(&result);
  }
  ShadowAEDisposeDesc(&theEvent);
}

- (void)launchTerminal {
  ProcessSerialNumber p = SKGetProcessWithSignature('trmx');
  if ( (p.highLongOfPSN == kNoProcess) && (p.lowLongOfPSN == kNoProcess)) {
    id term = SKFindApplicationWithSignature(SKFileTypeFromHFSTypeCode('trmx'));
    [[NSWorkspace sharedWorkspace] launchApplication:term showIcon:YES autolaunch:NO];
  }
}

- (void)executeInBackground {
  NSTask *task = [[NSTask alloc] init];
  
  [task setCurrentDirectoryPath:[self workingDirectoryPath]];
  
  NSMutableDictionary *infos = [[[NSProcessInfo processInfo] environment] mutableCopy];
  [infos addEntriesFromDictionary:env];
  [task setEnvironment:infos];
  [infos release];
  
  [task setLaunchPath:[self shellPath]];
  
  id arguments = nil;
  if (cmd != nil) {
    arguments = [NSArray arrayWithObjects:@"-c", [self argsStringForString:cmd], nil];
  }
  else {
    arguments = [NSArray arrayWithObjects: [scriptFile path], [self argsStringForString:args]];
  }
#if defined(DEBUG)
  NSLog(@"Arguments: %@", arguments);
#endif
  [task setArguments:arguments];
  [NSApplication detachDrawingThread:@selector(executeTask:) toTarget:self withObject:task]; 
}

- (SparkAlert *)execute {
  id alert = [self check];
  if (alert != nil) {
    return alert;
  }
  if (executeInTerm) {
    [self executeInTerminal];
  }
  else {
    [self executeInBackground];
  }
  return nil;
}

- (NSString *)workingDirectoryPath {
  NSString *path = nil;
  switch (workingDir) {
    case kShellRootFolder:
      path = @"/";
      break;
    case kShellCustomFolder:
      path = workingDirPath;
      break;
    case kShellFinderCurrentFolder:
      path = [(id)ShadowAEGetFinderCurrentFolderPath() autorelease];
      break;
    case kShellHomeFolder:
    default:
      path = NSHomeDirectory();
  }
#if defined(DEBUG)
  NSLog(@"Current Dir: %@", path);
#endif
  return path;
}

- (NSString *)shellPath {
  NSString *shellPath = nil;
  switch (shell) {
    case kShellTypeCsh:
      shellPath = @"/bin/csh";
      break;
    case kShellTypeZsh:
      shellPath = @"/bin/zsh";
      break;
    case kShellTypeTcsh:
      shellPath = @"/bin/tcsh";
      break;
    case kShellTypeBash:
      shellPath = @"/bin/bash";
      break;
    case kShellTypeSh:
    default:
      shellPath = @"/bin/sh";
  }
#if defined(DEBUG)
  NSLog(@"Shell: %@", shellPath);
#endif
  return shellPath;
}

- (void)executeTask:(NSTask *)task {
  [self retain]; // Multi-thread so be carfull.
  [task launch];
  [task waitUntilExit];
  if (displayDialog) {
    id script = nil;
    if (cmd != nil) {
      script = [[task arguments] objectAtIndex:1];
    }
    else {
      script = [NSString stringWithFormat:@"%@ %@", [[[task arguments] objectAtIndex:0] lastPathComponent], [[task arguments] objectAtIndex:1]];
    }
    id dialog = [SparkAlert alertWithMessageText:[NSString stringWithFormat:@"HotKey Ç%@È was executed", [self name]]
                       informativeTextWithFormat:@"Script: %@\nWorking dir: %@\nReturn status: %i", script, [[task currentDirectoryPath] stringByAbbreviatingWithTildeInPath], [task terminationStatus]];
    [dialog setHideSparkButton:YES];
    SparkDisplayAlert(dialog);
  }
  [task autorelease];
  [self autorelease];
}

- (NSString *)argsStringForString:(NSString *)str {
  /* replace *selection* by Finder selection */
  NSRange selection = [str rangeOfString:@"*selection*"];
  if (selection.location == NSNotFound) {
    return str;
  }
  id files = [NSMutableString stringWithString:str];
  [files replaceCharactersInRange:selection withString:@""];
  id aliases = [ShadowAEObjCGetFinderSelection() reverseObjectEnumerator];
  id alias;
  while (alias = [aliases nextObject]) {
    [files insertString:[alias path] atIndex:selection.location];
    [files insertString:@" " atIndex:selection.location];
  }
  return files;
}

- (void)setScriptAlias:(SKAlias *)alias {
  if (alias != scriptFile) {
    [scriptFile release];
    scriptFile = [alias retain];
  }
}

- (int)shell {
  return shell;
}
- (void)setShell:(int)newShell {
  shell = newShell;
}

- (int)workingDir {
  return workingDir;
}
- (void)setWorkingDir:(int)newWorkingDir {
  workingDir = newWorkingDir;
}

- (NSString *)cmd {
  return cmd;
}
- (void)setCmd:(NSString *)newCmd {
  if (cmd != newCmd) {
    [cmd release];
    cmd = [newCmd retain];
  }
}

- (NSDictionary *)env {
  return env;
}
- (void)setEnv:(NSDictionary *)newEnv {
  if (env != newEnv) {
    [env release];
    env = [newEnv retain];
  }
}

- (NSString *)workingDirPath {
  return workingDirPath;
}
- (void)setWorkingDirPath:(NSString *)newWorkingDirPath {
  if (workingDirPath != newWorkingDirPath) {
    [workingDirPath release];
    workingDirPath = [newWorkingDirPath retain];
  }
}


- (NSString *)scriptFile {
  return [scriptFile path];
}
- (void)setScriptFile:(NSString *)newFile {
  if (![[scriptFile path] isEqualToString:newFile]) {
    [scriptFile release];
    scriptFile = nil;
    if (newFile)
      scriptFile = [[SKAlias alloc] initWithPath:newFile];
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
