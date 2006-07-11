//
//  AppleScriptAction.m
//  Spark
//
//  Created by Fox on Fri Feb 20 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#if defined (DEBUG)
#warning Debug defined in AppleScriptAction!
#endif

#import "AppleScriptActionPlugin.h"
#import "AppleScriptAction.h"

#import <ShadowKit/SKAppKitExtensions.h>

volatile int SparkAppleScriptGDBWorkaround = 0;

enum {
  kSourceTab,
  kFileTab
};

NSString * const kASActionBundleIdentifier = @"org.shadowlab.spark.applescript";

@implementation AppleScriptActionPlugin

+ (void)initialize {
  static BOOL tooLate = NO;
  if (!tooLate ) {
    [self setKeys:[NSArray arrayWithObject:@"scriptFile"] triggerChangeNotificationsForDependentKey:@"scriptName"];
    tooLate = YES;
  }
}

- (void)dealloc {
  [attr release];
  [_script release];
  [_scriptFile release];
  [super dealloc];
}

- (void)awakeFromNib {
  [textView setDelegate:self];
  [self setAttributes];
}

- (void)loadSparkAction:(id)sparkAction toEdit:(BOOL)edit {
  [super loadSparkAction:sparkAction toEdit:edit];
  id value;
  if (value = [sparkAction scriptFile]) {
    [self setScriptFile:value];
    [self setValue:SKInt(1) forKey:@"tabIndex"];
  }
  else if (value = [sparkAction script]) {
    [value compileAndReturnError:nil];
    [self setScript:value];
  } else {
    [textView setSelectedRange:NSMakeRange(0, [[textView textStorage] length])];
    [textView insertText:@""];
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  id alert = nil;
  switch (tabIndex) {
    case kSourceTab:
      alert = [self checkSyntax];
      break;
    case kFileTab:
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
  [action setName:[self name]];
  [action setIcon:[NSImage imageNamed:@"AppleScriptIcon" inBundle:AppleScriptActionBundle]];
  switch (tabIndex) {
    case kSourceTab:
      [action setScriptFile:nil]; // Au cas ou on mette ˆ jour un clŽ.
      [action setScript:[self script]];
      [action setShortDescription:NSLocalizedStringFromTableInBundle(@"DESC_EXECUTE_SOURCE", nil, AppleScriptActionBundle,
                                                                     @"Simple Script Action Description")];
      break;
    case kFileTab:
      [action setScript:nil]; // Au cas ou on mette ˆ jour un clŽ.
      [action setScriptFile:[self scriptFile]];
      [action setShortDescription:[NSString stringWithFormat:
        NSLocalizedStringFromTableInBundle(@"DESC_EXECUTE_FILE", nil, AppleScriptActionBundle,
                                           @"File Script Action Description (%@ => File name)"),
        [[self scriptFile] lastPathComponent]]];
      break;
  }
}

#pragma mark -
- (IBAction)checkSyntax:(id)sender {
  id alert = nil;
  [self setScript:nil];
  if ([[textView textStorage] length]) {
    if (alert = [self checkSyntax]) {
      [alert beginSheetModalForWindow:[textView window]
                        modalDelegate:nil
                       didEndSelector:nil
                          contextInfo:nil];
    }
  } 
}

- (IBAction)run:(id)sender {
  [self checkSyntax:nil];
  id script = [self script];
  if (script) {
    id error = nil;
    if (![script executeAndReturnError:&error]) {
      id alert = [self alertForScriptError:error];
      [alert setMessageText:NSLocalizedStringFromTableInBundle(@"EXECUTION_ERROR_ALERT", nil, AppleScriptActionBundle,
                                                               @"Execution Error * Title *")];
      [alert beginSheetModalForWindow:[textView window]
                        modalDelegate:nil
                       didEndSelector:nil
                          contextInfo:nil];
    }
  }
}

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

- (IBAction)launchEditor:(id)sender {
  id src = [[[textView textStorage] string] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  id url = [NSURL URLWithString:[NSString stringWithFormat:@"applescript://com.apple.scripteditor?action=new&script=%@", src]];
  [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSOKButton) {
    id file = [[sheet filenames] objectAtIndex:0];
    id src = nil;
    if ([[[file pathExtension] lowercaseString] isEqualToString:@"scpt"]) {
      id scriptUrl = [NSURL fileURLWithPath:file];
      id script = [[NSAppleScript alloc] initWithContentsOfURL:scriptUrl error:nil];
      src = [script source];
      [script release];
    }
    else {
      src = [NSString stringWithContentsOfFile:file];
    }
    [textView setSelectedRange:NSMakeRange(0, [[textView textStorage] length])];
    [textView insertText:src];
  }
}

- (void)importPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSOKButton) {
    id file = [[sheet filenames] objectAtIndex:0];
    id scriptUrl = [NSURL fileURLWithPath:file];
    id errors = nil;
    id script = [[NSAppleScript alloc] initWithContentsOfURL:scriptUrl error:&errors];
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
  }
  else {
    [self setScriptFile:nil];
  }
}

- (NSAlert *)checkSyntax {
  id alert = nil;
  [self setScript:nil];
  if ([[textView textStorage] length]) {
    id script = [[NSAppleScript alloc] initWithSource:[[textView textStorage] string]];
    if (!script) {
      alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"SCRIPT_CREATION_ERROR_ALERT", nil, AppleScriptActionBundle,
                                                                               @"Unknow Error in -initWithSource * Title *")
                              defaultButton:NSLocalizedStringWithDefaultValue(@"OK", nil, AppleScriptActionBundle, @"OK",
                                                                               @"Alert default button")
                            alternateButton:nil
                                otherButton:nil
                  informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"SCRIPT_CREATION_ERROR_ALERT_MSG", nil, AppleScriptActionBundle,
                                                                               @"Unknow Error in -initWithSource * Msg *")];
    }
    else {
      alert = [self compileScript:script];
    }
    if (!alert && script) {
      [self setScript:script];
    }
    [script release];
  }
  else {
    alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_SOURCE_ALERT", nil, AppleScriptActionBundle,
                                                                             @"Empty Source Error * Title *")
                            defaultButton:NSLocalizedStringWithDefaultValue(@"OK", nil, AppleScriptActionBundle, @"OK",
                                                                             @"Alert default button")
                          alternateButton:nil
                              otherButton:nil
                informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_SOURCE_ALERT_MSG", nil, AppleScriptActionBundle,
                                                                             @"Empty Source Error * Msg *")];
  }
  return alert;
}

- (NSAlert *)compileScript:(NSAppleScript *)script {
  id error = nil;
  id alert = nil;
  if (![script compileAndReturnError:&error]) {
    alert = [self alertForScriptError:error];
    [alert setMessageText:NSLocalizedStringFromTableInBundle(@"SYNTAX_ERROR_ALERT", nil, AppleScriptActionBundle,
                                                             @"Syntax Error * Title *")];
  }
  return alert;
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
  [textView setSelectedRange:range];
  return [NSAlert alertWithMessageText:title
                         defaultButton:NSLocalizedStringWithDefaultValue(@"OK", nil, AppleScriptActionBundle, @"OK",
                                                                          @"Alert default button")
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:message];
}

- (id)script {
  return [[_script retain] autorelease];
}

- (void)setScript:(id)newScript {
  if (_script != newScript) {
    [_script release];
    _script = [newScript retain];
    if (_script && [_script isCompiled]) {
      NSAttributedString *src = [_script richTextSource];
      [textView setSelectedRange:NSMakeRange(0, [[textView textStorage] length])];
      [textView insertText:src];
      [self setAttributes];
    }
  }
}

- (id)scriptFile {
  return [[_scriptFile retain] autorelease];
}

- (void)setScriptFile:(id)newScriptFile {
  if (_scriptFile != newScriptFile) {
    [_scriptFile release];
    _scriptFile = [newScriptFile copy];
  }
}

- (id)scriptName {
  return [_scriptFile lastPathComponent]; 
}

- (void)setAttributes {
  if (!attr) {
    attr = [[NSMutableDictionary alloc] init];
    [attr setObject:[NSFont userFixedPitchFontOfSize:10] forKey:NSFontAttributeName];
    [attr setObject:[NSColor purpleColor] forKey:NSForegroundColorAttributeName];
    [attr setObject:SKInt(0) forKey:NSUnderlineStyleAttributeName];
  }
  [textView setTypingAttributes:attr];
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
  [self setAttributes];
}

@end
#pragma mark -
@implementation SourceView
- (void)paste:(id)sender {
  [super pasteAsPlainText:sender];
}
@end