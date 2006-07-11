//
//  ApplicationActionPlugin.m
//  Short-Cut
//
//  Created by Fox on Mon Dec 08 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#if defined (DEBUG)
#warning Debug defined in ApplicationAction!
#endif

#import "ApplicationAction.h"
#import "ApplicationActionPlugin.h"

#import <ShadowKit/SKExtensions.h>

volatile int SparkApplicationGDBWorkaround = 0;

NSString * const kApplicationActionBundleIdentifier = @"org.shadowlab.spark.application";

@implementation ApplicationActionPlugin

+ (void)initialize {
  [self setKeys:[NSArray arrayWithObject:@"action"] triggerChangeNotificationsForDependentKey:@"useFrontApplication"];
  [self setKeys:[NSArray arrayWithObject:@"action"] triggerChangeNotificationsForDependentKey:@"displayLaunchOptions"];
}

- (void)dealloc {
  [_appName release];
  [_appIcon release];
  [super dealloc];
}
/*===============================================*/

- (void)loadSparkAction:(ApplicationAction *)sparkAction toEdit:(BOOL)edit {
  [super loadSparkAction:sparkAction toEdit:edit];
  if (edit) {
    id undo = [self undoManager];
    [undo registerUndoWithTarget:self selector:@selector(setAppPath:) object:[sparkAction path]];
    [(ApplicationActionPlugin *)[undo prepareWithInvocationTarget:self] setAction:[sparkAction action]];
    [self setFlags:[sparkAction flags]];
    [self setAppPath:[sparkAction path]];
    [self setAction:[sparkAction action]];
  } else {
    [self setAction:kOpenActionTag];
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  if (([self action] != kHideFrontTag && [self action] != kHideAllTag) && ![self appPath]) {
    return [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT", nil, ApplicationActionBundle,
                                                                            @"Create Action without Application Error * Title *")
                           defaultButton:NSLocalizedStringFromTableInBundle(@"OK", nil, ApplicationActionBundle,
                                                                            @"Alert default button")
                         alternateButton:nil
                             otherButton:nil
               informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT_MSG", nil, ApplicationActionBundle,
                                                                            @"Create Action without Application Error * Msg *")];
  } else if ([[[self name] stringByTrimmingWhitespaceAndNewline] length] == 0) {
    [self setName:_appName];
  }
  return nil;
}

- (void)configureAction {
  [super configureAction];
  ApplicationAction *action = [self sparkAction];
  [action setFlags:flags];
  [action setShortDescription:[self actionDescription:action]];
}

#pragma mark -
/*===============================================*/
- (IBAction)chooseApplication:(id)sender {
  NSOpenPanel *oPanel = [NSOpenPanel openPanel];
  
  [oPanel setAllowsMultipleSelection:NO];
  [oPanel setCanChooseDirectories:NO];
  
  [oPanel beginSheetForDirectory:nil
                            file:nil
                           types:[NSArray arrayWithObjects:@"app", @"APPL", nil]
                  modalForWindow:[sender window]
                   modalDelegate:self
                  didEndSelector:@selector(choosePanel:returnCode:contextInfo:)
                     contextInfo:nil];
}

- (void)choosePanel:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSCancelButton) {
    return;
  }
  [self setAppPath:[[sheet filenames] objectAtIndex:0]];
}

/*===============================================*/

- (BOOL)useFrontApplication {
  return [self action] == kHideFrontTag || [self action] == kHideAllTag;
}

- (BOOL)displayLaunchOptions {
  return [self action] != kOpenActionTag && [self action] != kOpenCloseActionTag;
}

- (NSString *)actionDescription:(id)key {
  id act;
  switch ([self action]) {
    case kHideFrontTag:
      act = NSLocalizedStringFromTableInBundle(@"DESC_HIDE_FRONT", nil,ApplicationActionBundle,
                                               @"Hide Front Applications * Action Description *");
      break;
    case kHideAllTag:
      act = NSLocalizedStringFromTableInBundle(@"DESC_HIDE_ALL", nil,ApplicationActionBundle,
                                               @"Hide All Applications * Action Description *");
      break;
    case kOpenActionTag:
      act = NSLocalizedStringFromTableInBundle(@"DESC_LAUNCH", nil,ApplicationActionBundle,
                                               @"Launch Application * Action Description *");
      break;
    case kOpenCloseActionTag:
      act = NSLocalizedStringFromTableInBundle(@"DESC_SWITCH_OPEN_CLOSE", nil,ApplicationActionBundle,
                                               @"Open/Close Application * Action Description *");
      break;
    case kQuitActionTag:
      act = NSLocalizedStringFromTableInBundle(@"DESC_QUIT", nil,ApplicationActionBundle,
                                               @"Quit Application * Action Description *");
      break;
    case kKillActionTag:
      act = NSLocalizedStringFromTableInBundle(@"DESC_FORCE_QUIT", nil,ApplicationActionBundle,
                                               @"Force Quit Application * Action Description *");
      break;
    default:
      act = NSLocalizedStringFromTableInBundle(@"DESC_ERROR", nil,ApplicationActionBundle,
                                         @"Unknow Action * Action Description *");
  }
  if (_appName)
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESCRIPTION", nil,ApplicationActionBundle,
                                                                         @"Description: %1$@ => Action, %2$@ => App Name"), act, _appName];
  else return act;
}

- (NSString *)appPath {
  return [[self sparkAction] path];
}

- (void)setAppPath:(NSString *)appPath {
  [(ApplicationAction *)[self sparkAction] setPath:appPath];
  
  [self setAppName:[[[NSFileManager defaultManager] displayNameAtPath:[self appPath]] stringByDeletingPathExtension]];
  id icon = ([self appPath]) ? [[NSWorkspace sharedWorkspace] iconForFile:[self appPath]] : nil;
  [self setAppIcon:icon];
}

- (NSString *)appName { return [[_appName retain] autorelease]; }
- (void)setAppName:(NSString *)appName { 
  if (appName != _appName) {
    NSString *name = [[self name] stringByTrimmingWhitespaceAndNewline];
    if (![name length] || [name isEqualToString:_appName]) {
      [self setName:appName];
    }
    [_appName release];
    _appName = [appName copy];
  }
}

- (NSImage *)appIcon { 
  return _appIcon;
}
- (void)setAppIcon:(NSString *)appIcon {
  if (appIcon != _appIcon) {
    [_appIcon release];
    _appIcon = [appIcon retain];
    [self setIcon:_appIcon];
  }
}

- (int)action {
  return (int)[[self sparkAction] action];
}

- (void)setAction:(int)newAction {
  [(ApplicationAction *)[self sparkAction] setAction:newAction];
  if ([self useFrontApplication]) {
    [self setAppName:nil];
    [self setAppIcon:nil];
  } else {
    [self setAppPath:[self appPath]];
  }
}

#pragma mark -
#pragma mark Flags Manipulation
- (void)setFlags:(int)value {
  [self setDontSwitch:(value & kLSLaunchDontSwitch) != 0];
  [self setNewInstance:(value & kLSLaunchNewInstance) != 0];
  [self setHide:(value & kLSLaunchAndHide) != 0];
  [self setHideOthers:(value & kLSLaunchAndHideOthers) != 0];
}

- (BOOL)dontSwitch {
  return (flags & kLSLaunchDontSwitch) != 0;
}
- (void)setDontSwitch:(BOOL)dontSwitch {
  flags = dontSwitch ? flags | kLSLaunchDontSwitch : flags & ~kLSLaunchDontSwitch;
}

- (BOOL)newInstance {
  return (flags & kLSLaunchNewInstance) != 0;
}
- (void)setNewInstance:(BOOL)newInstance {
  flags = newInstance ? flags | kLSLaunchNewInstance : flags & ~kLSLaunchNewInstance;
}

- (BOOL)hide {
  return (flags & kLSLaunchAndHide) != 0;
}
- (void)setHide:(BOOL)hide {
  flags = hide ? flags | kLSLaunchAndHide : flags & ~kLSLaunchAndHide;
}

- (BOOL)hideOthers {
  return (flags & kLSLaunchAndHideOthers) != 0;
}
- (void)setHideOthers:(BOOL)hideOthers {
  flags = hideOthers ? flags | kLSLaunchAndHideOthers : flags & ~kLSLaunchAndHideOthers;
}

@end
