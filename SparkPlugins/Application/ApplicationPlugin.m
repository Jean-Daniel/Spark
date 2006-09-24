/*
 *  ApplicationActionPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) Shadow Lab. 2004 - 2006. All rights reserved.
 */

#import "ApplicationPlugin.h"

#import <ShadowKit/SKImageView.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKAppKitExtensions.h>

NSString * const kApplicationActionBundleIdentifier = @"org.shadowlab.spark.application";

@implementation ApplicationActionPlugin

- (void)dealloc {
  [aa_name release];
  [aa_icon release];
  [aa_path release];
  [super dealloc];
}
- (void)awakeFromNib {
  [ibIcon setImageInterpolation:NSImageInterpolationHigh];
}

/*===============================================*/
- (void)loadSparkAction:(ApplicationAction *)sparkAction toEdit:(BOOL)edit {
  [self willChangeValueForKey:@"visual"];
  [self willChangeValueForKey:@"notifyLaunch"];
  [self willChangeValueForKey:@"notifyActivation"];
  if ([sparkAction usesSharedVisual]) {
    [ApplicationAction getSharedSettings:&aa_settings];
  } else {
    [sparkAction getVisualSettings:&aa_settings];
  }
  [self didChangeValueForKey:@"notifyActivation"];
  [self didChangeValueForKey:@"notifyLaunch"];
  [self didChangeValueForKey:@"visual"];
  if (edit) {
    [self setPath:[sparkAction path]];
    [self setFlags:[sparkAction flags]];
    [self setAction:[sparkAction action]];
    [ibName setStringValue:[sparkAction name] ? : @""];
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
  
  /* Save visual if needed */
  if (![action usesSharedVisual]) {
    [action setVisualSettings:&aa_settings];
  }
  
  [action setName:[ibName stringValue]];
  [action setActionDescription:ApplicationActionDescription(action, aa_name)];
}

- (void)pluginViewWillBecomeHidden {
  if ([[self sparkAction] usesSharedVisual]) {
    // Update defaut configuration
    [ApplicationAction setSharedSettings:&aa_settings];
  }
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
  SKSetterRetain(aa_path, aPath);
  NSString *name = [[[NSFileManager defaultManager] displayNameAtPath:aPath] stringByDeletingPathExtension];
  [ibApplication setStringValue:name ? : @""];
  [[ibName cell] setPlaceholderString:name ? : @"Action Name"];
  [ibIcon setImage:aPath ? [[NSWorkspace sharedWorkspace] iconForFile:aPath] : [NSImage imageNamed:@"undefined" inBundle:kApplicationActionBundle]];
}

- (ApplicationActionType)action {
  return [(ApplicationAction *)[self sparkAction] action];
}

- (void)setAction:(ApplicationActionType)newAction {
  [(ApplicationAction *)[self sparkAction] setAction:newAction];
  // Adjust interface.
  [ibAppView setHidden:NO];
  switch (newAction) {
    case kApplicationLaunch:
      [ibOptions setHidden:NO];
      [ibOptions setEnabled:YES];
      break;
    case kApplicationHideFront:
    case kApplicationHideOther:
      [ibAppView setHidden:YES];
      // Fall thought
    default:
      [ibOptions setHidden:YES];
      [ibOptions setEnabled:NO];
      break;
  }
  /* Update placeholder */
  switch (newAction) {
    case kApplicationHideFront:
      [[ibName cell] setPlaceholderString:@"Hide Front"];
      break;
    case kApplicationHideOther: 
      [[ibName cell] setPlaceholderString:@"Hide Others"];
      break;
    default: {
      NSString *name = [ibApplication stringValue];
      [[ibName cell] setPlaceholderString:[name length] > 0 ? name : @"Action Name"];
      break;
    }
  }
}

- (int)visual {
  return [[self sparkAction] usesSharedVisual] ? 0 : 1;
}
- (void)setVisual:(int)visual {
  BOOL shared = [[self sparkAction] usesSharedVisual];
  [self willChangeValueForKey:@"notifyLaunch"];
  [self willChangeValueForKey:@"notifyActivation"];
  switch (visual) {
    case 0:
      if (!shared) {
        [[self sparkAction] setUsesSharedVisual:YES];
        [[self sparkAction] setVisualSettings:&aa_settings];
        [ApplicationAction getSharedSettings:&aa_settings];
      }
      break;
    case 1:
      if (shared) {
        [[self sparkAction] setUsesSharedVisual:NO];
        [ApplicationAction setSharedSettings:&aa_settings];
        [[self sparkAction] getVisualSettings:&aa_settings];
      }
  }
  [self didChangeValueForKey:@"notifyActivation"];
  [self didChangeValueForKey:@"notifyLaunch"];
}

- (BOOL)notifyLaunch {
  return aa_settings.launch;
}
- (void)setNotifyLaunch:(BOOL)flag {
  aa_settings.launch = flag;
}
- (BOOL)notifyActivation {
  return aa_settings.activation;
}
- (void)setNotifyActivation:(BOOL)flag {
  aa_settings.activation = flag;
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
