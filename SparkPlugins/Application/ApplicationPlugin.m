/*
 *  ApplicationActionPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) Shadow Lab. 2004 - 2006. All rights reserved.
 */

#import "ApplicationPlugin.h"

#import <ShadowKit/SKExtensions.h>

NSString * const kApplicationActionBundleIdentifier = @"org.shadowlab.spark.application";

@implementation ApplicationActionPlugin

- (void)dealloc {
  [aa_name release];
  [aa_icon release];
  [super dealloc];
}
/*===============================================*/

- (void)loadSparkAction:(ApplicationAction *)sparkAction toEdit:(BOOL)edit {
  if (edit) {
    [self setPath:[sparkAction path]];
    [self setFlags:[sparkAction flags]];
    [self setAction:[sparkAction action]];
  } else {
    [self setAction:kApplicationLaunch];
  }
}

- (NSAlert *)sparkEditorShouldConfigureAction {
//  if (([self action] != kHideFrontTag && [self action] != kHideAllTag) && ![self appPath]) {
//    return [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT", nil, ApplicationActionBundle,
//                                                                            @"Create Action without Application Error * Title *")
//                           defaultButton:NSLocalizedStringFromTableInBundle(@"OK", nil, ApplicationActionBundle,
//                                                                            @"Alert default button")
//                         alternateButton:nil
//                             otherButton:nil
//               informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT_MSG", nil, ApplicationActionBundle,
//                                                                            @"Create Action without Application Error * Msg *")];
//  } else if ([[[self name] stringByTrimmingWhitespaceAndNewline] length] == 0) {
//    [self setName:_appName];
//  }
  return nil;
}

- (void)configureAction {
  [super configureAction];
  ApplicationAction *action = [self sparkAction];
  [action setFlags:aa_flags];
//  [action setShortDescription:[self actionDescription:action]];
}

#pragma mark -
- (IBAction)back:(id)sender {
  [ibTab selectTabViewItemAtIndex:0];
}
- (IBAction)options:(id)sende {
  [ibTab selectTabViewItemAtIndex:1];
}

- (IBAction)chooseApplication:(id)sender {
  NSOpenPanel *oPanel = [NSOpenPanel openPanel];
  
  [oPanel setCanChooseDirectories:NO];
  [oPanel setAllowsMultipleSelection:NO];
  
  [oPanel beginSheetForDirectory:nil
                            file:nil
                           types:[NSArray arrayWithObjects:@"app", @"APPL", nil]
                  modalForWindow:[sender window]
                   modalDelegate:self
                  didEndSelector:@selector(choosePanel:returnCode:contextInfo:)
                     contextInfo:nil];
}

- (void)choosePanel:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSOKButton && [[sheet filenames] count] > 0) {
    [self setPath:[[sheet filenames] objectAtIndex:0]];
  }
}

/*===============================================*/

- (void)setPath:(NSString *)aPath {
//  [(ApplicationAction *)[self sparkAction] setPath:appPath];
//  
//  [self setAppName:[[[NSFileManager defaultManager] displayNameAtPath:[self appPath]] stringByDeletingPathExtension]];
//  id icon = ([self appPath]) ? [[NSWorkspace sharedWorkspace] iconForFile:[self appPath]] : nil;
//  [self setAppIcon:icon];
}

//- (NSString *)appName { return [[_appName retain] autorelease]; }
//- (void)setAppName:(NSString *)appName { 
//  if (appName != _appName) {
//    NSString *name = [[self name] stringByTrimmingWhitespaceAndNewline];
//    if (![name length] || [name isEqualToString:_appName]) {
//      [self setName:appName];
//    }
//    [_appName release];
//    _appName = [appName copy];
//  }
//}
//
//- (NSImage *)appIcon { 
//  return _appIcon;
//}
//- (void)setAppIcon:(NSString *)appIcon {
//  if (appIcon != _appIcon) {
//    [_appIcon release];
//    _appIcon = [appIcon retain];
//    [self setIcon:_appIcon];
//  }
//}

- (ApplicationActionType)action {
  return [(ApplicationAction *)[self sparkAction] action];
}

- (void)setAction:(ApplicationActionType)newAction {
  [(ApplicationAction *)[self sparkAction] setAction:newAction];
  // Adjust interface.
  switch (newAction) {
    case kApplicationLaunch:
      break;
  }
}

#pragma mark -
#pragma mark Flags Manipulation
- (void)setFlags:(LSLaunchFlags)value {
  [self setHide:(value & kLSLaunchAndHide) != 0];
  [self setDontSwitch:(value & kLSLaunchDontSwitch) != 0];
  [self setNewInstance:(value & kLSLaunchNewInstance) != 0];
  [self setHideOthers:(value & kLSLaunchAndHideOthers) != 0];
}

- (BOOL)dontSwitch {
  return (aa_flags & kLSLaunchDontSwitch) != 0;
}
- (void)setDontSwitch:(BOOL)dontSwitch {
  aa_flags = dontSwitch ? aa_flags | kLSLaunchDontSwitch : aa_flags & ~kLSLaunchDontSwitch;
}

- (BOOL)newInstance {
  return (aa_flags & kLSLaunchNewInstance) != 0;
}
- (void)setNewInstance:(BOOL)newInstance {
  aa_flags = newInstance ? aa_flags | kLSLaunchNewInstance : aa_flags & ~kLSLaunchNewInstance;
}

- (BOOL)hide {
  return (aa_flags & kLSLaunchAndHide) != 0;
}
- (void)setHide:(BOOL)hide {
  aa_flags = hide ? aa_flags | kLSLaunchAndHide : aa_flags & ~kLSLaunchAndHide;
}

- (BOOL)hideOthers {
  return (aa_flags & kLSLaunchAndHideOthers) != 0;
}
- (void)setHideOthers:(BOOL)hideOthers {
  aa_flags = hideOthers ? aa_flags | kLSLaunchAndHideOthers : aa_flags & ~kLSLaunchAndHideOthers;
}

@end
