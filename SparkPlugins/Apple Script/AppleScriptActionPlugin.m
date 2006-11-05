/*
 *  AppleScriptActionPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "AppleScriptActionPlugin.h"
#import "AppleScriptAction.h"

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKLSFunctions.h>
#import <ShadowKit/SKProcessFunctions.h>

#import <ShadowKit/SKClassCluster.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import <OSAKit/OSAKit.h>

enum {
  kAppleScriptFileTab   = 1,
  kAppleScriptSourceTab = 0,
};

@interface AppleScriptNSPlugin : AppleScriptActionPlugin {
  /* NSAppleScript */
}

- (NSAlert *)alertForScriptError:(NSDictionary *)errors;

@end

@interface AppleScriptOSAPlugin : AppleScriptActionPlugin {
  /* Contains script and script view */
  OSAScriptController *as_ctrl;
}

- (NSAlert *)alertForScriptError:(NSDictionary *)errors;

@end

SKClassCluster(AppleScriptActionPlugin);

@implementation SKClusterPlaceholder(AppleScriptActionPlugin) (ASClassCluster)

- (id)init {
  /* OSAKit require Mac OS 10.4 or later */
  if (SKSystemMajorVersion() >= 10 && SKSystemMinorVersion() >= 4)
    return [[AppleScriptOSAPlugin alloc] init];
  else
    return [[AppleScriptNSPlugin alloc] init];
}

@end

@implementation AppleScriptActionPlugin

- (Class)scriptClass {
  return nil;
}

- (void)dealloc {
  [as_file release];
  [super dealloc];
}

- (void)loadSparkAction:(id)sparkAction toEdit:(BOOL)edit {
  id value;
  [ibScript setSource:@""];
  if (value = [sparkAction scriptAlias]) {
    [self setScriptFile:[value path]];
    [self setValue:SKInt(kAppleScriptFileTab) forKey:@"selectedTab"];
  } else if (value = [sparkAction scriptSource]) {
    [ibScript setSource:value];
    [self compile:nil];
  }
}

- (NSAlert *)checkSyntax {
  NSAlert *alert = nil;
  if (![[ibScript source] length]) {
    alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_SOURCE_ALERT", nil, AppleScriptActionBundle,
                                                                             @"Empty Source Error * Title *")
                            defaultButton:NSLocalizedStringWithDefaultValue(@"OK", nil, AppleScriptActionBundle, @"OK",
                                                                            @"Alert default button")
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_SOURCE_ALERT_MSG", nil, AppleScriptActionBundle,
                                                                             @"Empty Source Error * Msg *")];
  } else {
    id script = [[[self scriptClass] alloc] initWithSource:[ibScript source]];
    if (!script) {
        alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"SCRIPT_CREATION_ERROR_ALERT", nil, AppleScriptActionBundle,
                                                                                 @"Unknow Error in -initWithSource * Title *")
                                defaultButton:NSLocalizedStringWithDefaultValue(@"OK", nil, AppleScriptActionBundle, @"OK",
                                                                                 @"Alert default button")
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"SCRIPT_CREATION_ERROR_ALERT_MSG", nil, AppleScriptActionBundle,
                                                                                 @"Unknow Error in -initWithSource * Msg *")];
    } else {
      alert = [self compileScript:script];
      [script release];
    }
  }
  return alert;
}

- (NSAlert *)compileScript:(NSAppleScript *)script {
  SKClusterException();
  return nil;
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  NSAlert *alert = nil;
  switch (as_tidx) {
    case kAppleScriptSourceTab:
      alert = [self checkSyntax];
      break;
    case kAppleScriptFileTab:
      if (![self scriptFile]) {
        alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_FILE", nil,
                                                                                 AppleScriptActionBundle,
                                                                                 @"Trying to create Script File Action without file * Title *")
                                defaultButton:NSLocalizedStringWithDefaultValue(@"OK", nil,
                                                                                 AppleScriptActionBundle, @"OK",
                                                                                 @"Alert default button")
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_FILE_MSG", nil,
                                                                                 AppleScriptActionBundle,
                                                                                 @"Trying to create Script File Action without file * Msg *")];
      }
      break;
  }
  return alert;
}

- (void)configureAction {
  AppleScriptAction *action = [self sparkAction];
  [action setIcon:[NSImage imageNamed:@"AppleScriptIcon" inBundle:AppleScriptActionBundle]];
  switch (as_tidx) {
    case kAppleScriptSourceTab:
      [action setScriptSource:[ibScript source]];
      [action setFile:nil];
      break;
    case kAppleScriptFileTab:
      [action setScriptSource:nil];
      [action setFile:[self scriptFile]];
      break;
  }
  [action setActionDescription:AppleScriptActionDescription(action)];
}

#pragma mark -
- (IBAction)compile:(id)sender {
//  id alert = nil;
//  [self setScript:nil];
//  if ([[textView textStorage] length]) {
//    if (alert = [self checkSyntax]) {
//      [alert beginSheetModalForWindow:[textView window]
//                        modalDelegate:nil
//                       didEndSelector:nil
//                          contextInfo:nil];
//    }
//  } 
}

- (IBAction)run:(id)sender {
//  [self checkSyntax:nil];
//  id script = [self script];
//  if (script) {
//    id error = nil;
//    if (![script executeAndReturnError:&error]) {
//      id alert = [self alertForScriptError:error];
//      [alert setMessageText:NSLocalizedStringFromTableInBundle(@"EXECUTION_ERROR_ALERT", nil, AppleScriptActionBundle,
//                                                               @"Execution Error * Title *")];
//      [alert beginSheetModalForWindow:[textView window]
//                        modalDelegate:nil
//                       didEndSelector:nil
//                          contextInfo:nil];
//    }
//  }
}

#pragma mark Open
- (IBAction)open:(id)sender {
  NSOpenPanel *oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection:NO];
  [oPanel setCanChooseDirectories:NO];
  [oPanel setResolvesAliases:YES];
  [oPanel beginSheetForDirectory:nil
                            file:nil
                           types:nil
                  modalForWindow:[[self actionView] window]
                   modalDelegate:self
                  didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                     contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSOKButton && [[sheet filenames] count] > 0) {
    NSString *file = [[sheet filenames] objectAtIndex:0];
    NSString *src = nil;
    if ([[[file pathExtension] lowercaseString] isEqualToString:@"scpt"]) {
      id script = [[[self scriptClass] alloc] initWithContentsOfURL:[NSURL fileURLWithPath:file] error:nil];
      src = [[script source] retain];
      [script release];
    } else {
      src = [[NSString alloc] initWithContentsOfFile:file];
    }
    [ibScript setSource:src];
    [src release];
  }
}

#pragma mark Import
- (IBAction)import:(id)sender {
  NSOpenPanel *oPanel = [NSOpenPanel openPanel];  
  [oPanel setAllowsMultipleSelection:NO];
  [oPanel setCanChooseDirectories:NO];
  [oPanel setResolvesAliases:YES];
  [oPanel beginSheetForDirectory:nil
                            file:nil
                           types:[NSArray arrayWithObjects:@"scpt", @"osas", nil]
                  modalForWindow:[[self actionView] window]
                   modalDelegate:self
                  didEndSelector:@selector(importPanelDidEnd:returnCode:contextInfo:)
                     contextInfo:nil];
}

- (void)importPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSOKButton && [[sheet filenames] count] > 0) {
    NSString *file = [[sheet filenames] objectAtIndex:0];
    NSDictionary *errors = nil;
    NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:file] error:&errors];
    [sheet close];
    if (![script isCompiled]) {
      NSBeginAlertSheet(NSLocalizedStringFromTableInBundle(@"INVALID_SCRIPT_FILE_ALERT", nil, AppleScriptActionBundle,
                                                           @"Import uncompiled Script Error * Title *"), 
                        NSLocalizedStringWithDefaultValue(@"OK", nil, AppleScriptActionBundle, @"OK",
                                                          @"Alert default button"),
                        nil,nil, [[self actionView] window], nil ,nil, nil, nil,
                        NSLocalizedStringFromTableInBundle(@"INVALID_SCRIPT_FILE_ALERT_MSG", nil, AppleScriptActionBundle,
                                                           @"Import uncompiled Script Error * Msg *"), [file lastPathComponent]);
    } else {
      [self setScriptFile:file];
    }
    [script release];
  } else {
    [self setScriptFile:nil];
  }
}

#pragma mark Launch
- (IBAction)launchEditor:(id)sender {
  AppleEvent aevt = SKAEEmptyDesc();
  AEDesc document = SKAEEmptyDesc();
  
  /* Launch Script Editor */
  ProcessSerialNumber psn = SKProcessGetProcessWithSignature('ToyS');
  if (kNoProcess == psn.lowLongOfPSN) {
    if (noErr == SKLSLaunchApplicationWithSignature('ToyS',kLSLaunchDefaults &~kLSLaunchAsync))
      psn = SKProcessGetProcessWithSignature('ToyS');
  }
  require(kNoProcess != psn.lowLongOfPSN, dispose);
  
  /* activate */
  OSStatus err = SKAESendSimpleEventToProcess(&psn, kAEMiscStandards, kAEActivate);
  require_noerr(err, dispose);
  
  NSString *src = [[ibScript textStorage] string];
  if (!src || ![src length]) {
    return;
  }
  
  /* set the_document to make document */
  err = SKAECreateEventWithTargetProcess(&psn, kAECoreSuite, kAECreateElement, &aevt);
  require_noerr(err, dispose);
  
  OSType type = cDocument;
  err = SKAEAddAEDescWithData(&aevt, keyAEObjectClass, typeType, &type, sizeof(OSType));
  require_noerr(err, dispose);
  
  err = SKAEAddSubject(&aevt);
  require_noerr(err, dispose);
  err = SKAEAddMagnitude(&aevt);
  require_noerr(err, dispose);
  
  err = SKAESendEventReturnAEDesc(&aevt, typeObjectSpecifier, &document);
  SKAEDisposeDesc(&aevt);
  require_noerr(err, dispose);
  
  /* set text of the_document to 'src' */
  err = SKAECreateEventWithTargetProcess(&psn, kAECoreSuite, kAESetData, &aevt);
  require_noerr(err, dispose);
  
  err = SKAEAddIndexObjectSpecifier(&aevt, keyDirectObject, 'ctxt', kAEAll, &document);
  require_noerr(err, dispose);
  
  err = SKAEAddCFStringAsUnicodeText(&aevt, keyAEData, (CFStringRef)src);
  require_noerr(err, dispose);
  
  err = SKAESendEventNoReply(&aevt);
  require_noerr(err, dispose);
  
dispose:
    SKAEDisposeDesc(&aevt);
  SKAEDisposeDesc(&document);
}

#pragma mark -
- (int)selectedTab {
  return as_tidx;
}
- (void)setSelectedTab:(int)tab {
  as_tidx = tab;
}

- (NSString *)scriptFile {
  return as_file;
}
- (void)setScriptFile:(NSString *)aFile {
  SKSetterCopy(as_file, aFile);
}

@end

@implementation AppleScriptNSPlugin

static NSDictionary *sAttributes = nil;

+ (void)initialize {
  if ([AppleScriptActionPlugin class] == self) {
    sAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
      SKInt(NSUnderlineStyleNone), NSUnderlineStyleAttributeName,
      [NSFont userFixedPitchFontOfSize:10], NSFontAttributeName,
      [NSColor purpleColor], NSForegroundColorAttributeName,
      nil];
  }
}

- (void)dealloc {
  [super dealloc];
}

- (void)awakeFromNib {
  [ibScript setTextFont:[sAttributes objectForKey:NSFontAttributeName]];
  [ibScript setTextColor:[sAttributes objectForKey:NSForegroundColorAttributeName]];
  [ibScript setTypingAttributes:sAttributes];
}

- (NSAlert *)alertForScriptError:(NSDictionary *)errors {
  int error = [[errors objectForKey:@"NSAppleScriptErrorNumber"] intValue];
  switch (error) {
    case -128: //=> User Cancel
      return nil;
  }
  id title = [errors objectForKey:@"NSAppleScriptErrorBriefMessage"];
  id message = [errors objectForKey:@"NSAppleScriptErrorMessage"];
  NSRange range = [[errors objectForKey:@"NSAppleScriptErrorRange"] rangeValue];
  [ibScript setSelectedRange:range];
  return [NSAlert alertWithMessageText:title
                         defaultButton:NSLocalizedStringWithDefaultValue(@"OK", nil, AppleScriptActionBundle, @"OK",
                                                                         @"Alert default button")
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:message];
}

- (NSAlert *)compileScript:(NSAppleScript *)script {
  NSAlert *alert = nil;
  NSDictionary *error = nil;
  if (![script compileAndReturnError:&error]) {
    alert = [self alertForScriptError:error];
    [alert setMessageText:NSLocalizedStringFromTableInBundle(@"SYNTAX_ERROR_ALERT", nil, AppleScriptActionBundle,
                                                             @"Syntax Error * Title *")];
  }
  return alert;
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
  [ibScript setTypingAttributes:sAttributes];
}

@end

@implementation AppleScriptOSAPlugin 

- (Class)scriptClass {
  return [OSAScript class];
}

- (id)init {
  if (self = [super init]) {
    as_ctrl = [[OSAScriptController alloc] init];
  }
  return self;
}

- (void)dealloc {
  [as_ctrl release];
  [super dealloc];
}

- (void)awakeFromNib {
  OSAScriptView *view = [[OSAScriptView alloc] initWithFrame:[ibScript frame]];
  NSScrollView *parent = [ibScript enclosingScrollView];
  [parent setDocumentView:view];
  [as_ctrl setScriptView:view];
  ibScript = view;
  [view release];
}

#pragma mark -
- (IBAction)compile:(id)sender {
  [as_ctrl compileScript:sender];
}

- (IBAction)run:(id)sender {
  [as_ctrl runScript:sender];
}

- (NSAlert *)alertForScriptError:(NSDictionary *)errors {
  int error = [[errors objectForKey:OSAScriptErrorNumber] intValue];
  if (-128 == error) {
    //=> User Cancel
    return nil;
  }
  NSString *title = [errors objectForKey:OSAScriptErrorBriefMessage];
  NSString *message = [errors objectForKey:OSAScriptErrorMessage];
  
  NSRange range = [[errors objectForKey:OSAScriptErrorRange] rangeValue];
  [ibScript setSelectedRange:range];
  
  return [NSAlert alertWithMessageText:title
                         defaultButton:NSLocalizedStringWithDefaultValue(@"OK", nil, AppleScriptActionBundle, @"OK",
                                                                         @"Alert default button")
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:message];
}

- (NSAlert *)compileScript:(OSAScript *)script {
  NSAlert *alert = nil;
  NSDictionary *error = nil;
  if (![script compileAndReturnError:&error]) {
    alert = [self alertForScriptError:error];
    if (![alert messageText])
      [alert setMessageText:NSLocalizedStringFromTableInBundle(@"SYNTAX_ERROR_ALERT", nil, AppleScriptActionBundle,
                                                               @"Syntax Error * Title *")];
  }
  return alert;
}

@end

#pragma mark -
@implementation SourceView
- (void)paste:(id)sender {
  [super pasteAsPlainText:sender];
}
- (NSString *)source {
  return [[self textStorage] string];
}
- (void)setSource:(NSString *)src {
  [super setString:src];
}

@end
