/*
 *  ApplicationPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "ApplicationPlugin.h"

#import <ShadowKit/SKImageView.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKAppKitExtensions.h>

NSString * const kApplicationActionBundleIdentifier = @"org.shadowlab.spark.application";

@implementation ApplicationActionPlugin

- (void)dealloc {
  [aa_name release];
  [aa_path release];
  [super dealloc];
}
- (void)awakeFromNib {
  [ibIcon setImageInterpolation:NSImageInterpolationHigh];
}

#pragma mark -
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
  } else {
    [self setAction:kApplicationLaunch];
  }
  [ibName setStringValue:[sparkAction name] ? : @""];
}

- (NSAlert *)sparkEditorShouldConfigureAction {
  switch ([self action]) {
    case kApplicationHideFront:
    case kApplicationHideOther:
    case kApplicationForceQuitFront:
    case kApplicationForceQuitDialog:
      break;
    default:
      if (!aa_path)
        return [NSAlert alertWithMessageText:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT", nil, kApplicationActionBundle,
                                                                                @"Create Action without Application Error * Title *")
                               defaultButton:NSLocalizedStringFromTableInBundle(@"OK", nil, kApplicationActionBundle,
                                                                                @"Alert default button")
                             alternateButton:nil
                                 otherButton:nil
                   informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT_MSG", nil, kApplicationActionBundle,
                                                                                @"Create Action without Application Error * Msg *")];
  }
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
  
  switch ([self action]) {
    case kApplicationHideFront:
    case kApplicationHideOther:
    case kApplicationForceQuitFront:
    case kApplicationForceQuitDialog:
      [action setPath:nil];
      break;
    default:
      [action setPath:aa_path];
      [action setIcon:[ibIcon image]];
  }
  if ([ibName stringValue] && [[ibName stringValue] length])
    [action setName:[ibName stringValue]];
  else
    [action setName:[[ibName cell] placeholderString]]; 
  
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

#pragma mark -
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
    case kApplicationToggle:
      [ibOptions setHidden:NO];
      [ibOptions setEnabled:YES];
      break;
    case kApplicationHideFront:
    case kApplicationHideOther:
    case kApplicationForceQuitFront:
    case kApplicationForceQuitDialog:
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
    case kApplicationHideOther: 
    case kApplicationForceQuitFront:
    case kApplicationForceQuitDialog:
      [[ibName cell] setPlaceholderString:ApplicationActionDescription([self sparkAction], nil)];
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
    case 0: // Shared visual
      if (!shared) {
        [[self sparkAction] setUsesSharedVisual:YES];
        [[self sparkAction] setVisualSettings:&aa_settings];
        [ApplicationAction getSharedSettings:&aa_settings];
      }
      break;
    case 1: // This action only
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
