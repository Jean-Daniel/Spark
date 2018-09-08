/*
 *  ApplicationPlugin.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "ApplicationPlugin.h"

#import <WonderBox/WonderBox.h>

@implementation ApplicationPlugin {
@private
  NSString *aa_name;
  ApplicationVisualSetting aa_settings;
}

@synthesize URL = _url;

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
    self.URL = sparkAction.URL;
    self.flags = sparkAction.flags;
    self.action = sparkAction.action;
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
      if (!_url) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT", nil, kApplicationActionBundle,
                                                               @"Create Action without Application Error * Title *");
        alert.informativeText = NSLocalizedStringFromTableInBundle(@"CREATE_ACTION_WITHOUT_APPLICATION_ALERT_MSG", nil, kApplicationActionBundle,
                                                                   @"Create Action without Application Error * Msg *");
        return alert;
      }
  }
  return nil;
}

- (void)configureAction {
  [super configureAction];
  ApplicationAction *action = [self sparkAction];
  [action setFlags:_flags];
  
  /* Save visual if needed */
  if (![action usesSharedVisual]) {
    [action setVisualSettings:&aa_settings];
  }
  
  switch ([self action]) {
    case kApplicationHideFront:
    case kApplicationHideOther:
    case kApplicationForceQuitFront:
    case kApplicationForceQuitDialog:
      action.URL = nil;
      action.icon = ApplicationActionIcon(action);
      break;
    default: {
      action.URL = _url;
      NSImage *icon = [[ibIcon image] copy];
      if (icon) {
        WBImageSetRepresentationsSize(icon, NSMakeSize(16, 16));
        action.icon = icon;
      }
    }
  }
  if ([ibName stringValue] && [[ibName stringValue] length])
    [action setName:[ibName stringValue]];
  else
    [action setName:[[ibName cell] placeholderString]]; 
  
  [action setActionDescription:ApplicationActionDescription(action, [[action application] name])];
}

- (void)plugInViewWillBecomeHidden {
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

- (IBAction)chooseApplication:(NSView *)sender {
  NSOpenPanel *oPanel = [NSOpenPanel openPanel];
  
  [oPanel setCanChooseDirectories:NO];
  [oPanel setAllowsMultipleSelection:NO];

  oPanel.preventsApplicationTerminationWhenModal = NO;
  oPanel.directoryURL = [_url URLByDeletingLastPathComponent];
  oPanel.nameFieldStringValue = _url.lastPathComponent ?: @"";
  oPanel.allowedFileTypes = @[ @"app", SPXCFToNSString(kUTTypeApplication) ];

  [oPanel beginSheetModalForWindow:sender.window completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSModalResponseOK && [oPanel.URLs count] > 0) {
      [self setURL:oPanel.URLs.firstObject];
    }
  }];
}

#pragma mark -
- (void)setURL:(NSURL *)anURL {
  NSArray *keys = @[NSURLEffectiveIconKey, NSURLLocalizedNameKey];
  SPXSetterCopyAndDo(_url, anURL, {
    NSDictionary *rsrc = [anURL resourceValuesForKeys:keys error:NULL];
    NSString *name = [rsrc[NSURLLocalizedNameKey] stringByDeletingPathExtension];
    [ibApplication setStringValue:name ? : @""];
    [[ibName cell] setPlaceholderString:name ? : NSLocalizedStringFromTableInBundle(@"ACTION_NAME",
                                                                                    NULL, kApplicationActionBundle, 
                                                                                    @"Action Name Placeholder")];
    NSImage *icon = rsrc[NSURLEffectiveIconKey];
    [ibIcon setImage:icon ?: [NSImage imageNamed:@"AAUndefined" inBundle:SPXCurrentBundle()]];
  });
}

- (ApplicationActionType)action {
  return [(ApplicationAction *)[self sparkAction] action];
}

- (void)setAction:(ApplicationActionType)newAction {
	[self willChangeValueForKey:@"showOptions"];
	[self willChangeValueForKey:@"showChooser"];
  [(ApplicationAction *)[self sparkAction] setAction:newAction];
	[self didChangeValueForKey:@"showChooser"];
	[self didChangeValueForKey:@"showOptions"];

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
      [[ibName cell] setPlaceholderString:[name length] > 0 ? name : NSLocalizedStringFromTableInBundle(@"ACTION_NAME",
                                                                                                        NULL, kApplicationActionBundle, 
                                                                                                        @"Action Name Placeholder")];
      break;
    }
  }
}

- (BOOL)showChooser {
	switch ([self action]) {
		case kApplicationQuit:
		case kApplicationLaunch:
    case kApplicationToggle:
		case kApplicationActivateQuit:
    case kApplicationForceQuitAppli:
			return YES;
		case kApplicationHideFront:
    case kApplicationHideOther:
    case kApplicationForceQuitFront:
    case kApplicationForceQuitDialog:
			return NO;
	}
	return NO;
}

- (BOOL)showOptions {
	switch ([self action]) {
		case kApplicationLaunch:
    case kApplicationToggle:
		case kApplicationActivateQuit:
			return YES;
		case kApplicationQuit:
		case kApplicationHideFront:
    case kApplicationHideOther:
    case kApplicationForceQuitAppli:
    case kApplicationForceQuitFront:
    case kApplicationForceQuitDialog:
			return NO;
	}
	return NO;
}

- (NSInteger)visual {
  return [[self sparkAction] usesSharedVisual] ? 0 : 1;
}
- (void)setVisual:(NSInteger)visual {
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
- (void)setFlags:(NSWorkspaceLaunchOptions)value {
  [self setHide:(value & NSWorkspaceLaunchAndHide) != 0];
  [self setDontSwitch:(value & NSWorkspaceLaunchWithoutActivation) != 0];
  [self setNewInstance:(value & NSWorkspaceLaunchNewInstance) != 0];
  [self setHideOthers:(value & NSWorkspaceLaunchAndHideOthers) != 0];
}

- (BOOL)dontSwitch {
  return (_flags & NSWorkspaceLaunchWithoutActivation) != 0;
}
- (void)setDontSwitch:(BOOL)dontSwitch {
  _flags = dontSwitch ? _flags | NSWorkspaceLaunchWithoutActivation : _flags & ~NSWorkspaceLaunchWithoutActivation;
}

- (BOOL)newInstance {
  return (_flags & NSWorkspaceLaunchNewInstance) != 0;
}
- (void)setNewInstance:(BOOL)newInstance {
  _flags = newInstance ? _flags | NSWorkspaceLaunchNewInstance : _flags & ~NSWorkspaceLaunchNewInstance;
}

- (BOOL)hide {
  return (_flags & NSWorkspaceLaunchAndHide) != 0;
}
- (void)setHide:(BOOL)hide {
  _flags = hide ? _flags | NSWorkspaceLaunchAndHide : _flags & ~NSWorkspaceLaunchAndHide;
}

- (BOOL)hideOthers {
  return (_flags & NSWorkspaceLaunchAndHideOthers) != 0;
}
- (void)setHideOthers:(BOOL)hideOthers {
  _flags = hideOthers ? _flags | NSWorkspaceLaunchAndHideOthers : _flags & ~NSWorkspaceLaunchAndHideOthers;
}

#pragma mark -
- (BOOL)hasCustomView {
  return YES;
}

+ (NSImage *)plugInViewIcon {
  return [NSImage imageNamed:@"AAApplication" inBundle:kApplicationActionBundle];
}

@end
