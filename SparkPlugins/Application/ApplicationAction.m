/*
 *  ApplicationAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "ApplicationAction.h"

#import <Sparkkit/SparkPrivate.h>

#import <WonderBox/WBAlias.h>
#import <WonderBox/WBFunctions.h>
#import <WonderBox/WBAEFunctions.h>
#import <WonderBox/WBFSFunctions.h>
#import <WonderBox/WBImageFunctions.h>
#import <WonderBox/NSImage+WonderBox.h>

static NSString * const kApplicationNameKey = @"ApplicationName";
static NSString * const kApplicationFlagsKey = @"ApplicationFlags";
static NSString * const kApplicationActionKey = @"ApplicationAction";
static NSString * const kApplicationLSFlagsKey = @"ApplicationLSFlags";

/* Only for coding */
static NSString * const kApplicationIdentifierKey = @"kApplicationIdentifierKey";

@implementation ApplicationAction {
@private
  struct _aa_aaFlags {
    unsigned int active:2;
    unsigned int reopen:1;

    unsigned int visual:1;
    unsigned int atLaunch:1;
    unsigned int atActivate:1;
    unsigned int reserved:26;
  } aa_aaFlags;
  IconRef aa_icon;
}

static bool sInit = false;

static 
ApplicationVisualSetting *AAGetSharedSettings(void) {
  static ApplicationVisualSetting sShared = {NO, NO};
  if (!sInit) {
    sInit = true;
    
    NSNumber *value = SparkPreferencesGetValue(@"AAVisualLaunch", SparkPreferencesLibrary);
    if (!value || [value boolValue])
      sShared.launch = YES;
    
    sShared.activation = SparkPreferencesGetBooleanValue(@"AAVisualActivate", SparkPreferencesLibrary);
  }
  return &sShared;
}

+ (void)getSharedSettings:(ApplicationVisualSetting *)settings {
  *settings = *AAGetSharedSettings();
}
+ (void)setSharedSettings:(ApplicationVisualSetting *)settings {
  ApplicationVisualSetting *shared = AAGetSharedSettings();
  if (settings) {
    if (settings->launch != shared->launch)
      SparkPreferencesSetBooleanValue(@"AAVisualLaunch", settings->launch, SparkPreferencesLibrary);
    if (settings->activation != shared->activation)
      SparkPreferencesSetBooleanValue(@"AAVisualActivate", settings->activation, SparkPreferencesLibrary);
    
    *shared = *settings;
  } else {
    // Remove key
    SparkPreferencesSetValue(@"AAVisualLaunch", NULL, SparkPreferencesLibrary);
    SparkPreferencesSetValue(@"AAVisualActivate", NULL, SparkPreferencesLibrary);
    
    /* Reset to default */
    shared->launch = YES;
    shared->activation = NO;
  }
}

+ (void)didLoadLibrary:(NSNotification *)aNotification {
  /* Reset settings */
  sInit = false;
}

+ (void)initialize {
  if ([ApplicationAction class] == self) {
    /* If daemon, listen updates */
    if (kSparkContext_Daemon == SparkGetCurrentContext()) {
      SparkPreferencesRegisterObserver(@"AAVisualLaunch", SparkPreferencesLibrary,
                                       ^(NSString *key, id value) {
                                         ApplicationVisualSetting *shared = AAGetSharedSettings();
                                         shared->launch = [value boolValue];
                                       });

      SparkPreferencesRegisterObserver(@"AAVisualActivate", SparkPreferencesLibrary,
                                       ^(NSString *key, id value) {
                                         ApplicationVisualSetting *shared = AAGetSharedSettings();
                                         shared->activation = [value boolValue];
                                       });
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLoadLibrary:)
                                                 name:SparkDidSetActiveLibraryNotification object:nil];
  }
}

#pragma mark -
#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  ApplicationAction* copy = [super copyWithZone:zone];
  copy->_action = _action;
  copy->_flags = _flags;
  copy->aa_aaFlags = aa_aaFlags;
  
  copy->_application = [_application copy];
  return copy;
}

- (NSUInteger)encodeFlags {
  NSUInteger flags = 0;
  flags |= aa_aaFlags.active & 0x3; /* bits 0 & 1 */
  if (aa_aaFlags.reopen) flags |= 1 << 2; /* bits 2 */
  
  if (aa_aaFlags.visual) flags |= 1 << 16; /* bits 16 */
  if (aa_aaFlags.atLaunch) flags |= 1 << 17; /* bits 17 */
  if (aa_aaFlags.atActivate) flags |= 1 << 18; /* bits 18 */
  return flags;
}
- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:_action forKey:kApplicationActionKey];
  [coder encodeInt:_flags forKey:kApplicationLSFlagsKey];
	[coder encodeInteger:[self encodeFlags] forKey:kApplicationFlagsKey];
  
  if (_application)
    [coder encodeObject:_application forKey:kApplicationIdentifierKey];
  return;
}

- (void)decodeFlags:(NSUInteger)flags {
  aa_aaFlags.active = flags & 0x3; /* bits 0 & 1 */
  if (flags & 1 << 2) aa_aaFlags.reopen = 1;
  
  if (flags & 1 << 16) aa_aaFlags.visual = 1;
  if (flags & 1 << 17) aa_aaFlags.atLaunch = 1;
  if (flags & 1 << 18) aa_aaFlags.atActivate = 1;
}
- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    _action = [coder decodeIntForKey:kApplicationActionKey];
    _flags = [coder decodeIntForKey:kApplicationLSFlagsKey];
    [self decodeFlags:[coder decodeIntForKey:kApplicationFlagsKey]];
      
    _application = [coder decodeObjectForKey:kApplicationIdentifierKey];
  }
  return self;
}

#pragma mark -
- (void)initFlags {
  [self setReopen:YES];
  [self setActivation:kFlagsBringAllFront];
  
  [self setUsesSharedVisual:YES];
  aa_aaFlags.atLaunch = 1;
  aa_aaFlags.atActivate = 0;
}

- (id)init {
  if (self = [super init]) {
    [self initFlags];
    [self setVersion:0x200];
  }
  return self;
}

#pragma mark -
#pragma mark Required Methods.
WB_INLINE
ApplicationActionType _ApplicationTypeFromTag(int tag) {
  switch (tag) {
    case 0:
      return kApplicationLaunch;
    case 2:
      return kApplicationQuit;
    case 4:
      return kApplicationToggle;
    case 3:
      return kApplicationForceQuitDialog;
    case 5:
      return kApplicationHideOther;
    case 6:
      return kApplicationHideFront;
  }
  return 0;
}

- (void)initFromOldPropertyList:(id)plist {
  /* Simply load alias and application without control (lazy resolution) */
  [self initFlags];
  
  WBAlias *alias = nil;
  NSData *data = [plist objectForKey:@"App Alias"];
  if (data) {
    alias = [[WBAlias alloc] initFromData:data];
    _application = [[WBApplication alloc] initWithPath:alias.path];
  }
  if (!_application) {
    _application = [[WBApplication alloc] init];
    OSType sign = [[plist objectForKey:@"App Sign"] intValue];
    if (sign) {
      [_application setSignature:sign];
    } else {
      NSString *bundle = [plist objectForKey:@"BundleID"];
      if (bundle) {
        [_application setBundleIdentifier:bundle];
      }
    }
  }
  
  [self setFlags:[[plist objectForKey:@"LSFlags"] intValue]];
  [self setAction:_ApplicationTypeFromTag([[plist objectForKey:@"Action"] intValue])];
  
  if ([self shouldSaveIcon] && _application) {
    NSImage *icon = [_application icon];
    if (icon) {
      WBImageSetRepresentationsSize(icon, NSMakeSize(16, 16));
      [self setIcon:icon];
    }
  } else if (![self shouldSaveIcon]) {
    [self setIcon:nil];
  }
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    if ([self version] < 0x200) {
      [self initFromOldPropertyList:plist];
      [self setVersion:0x200];
    } else {
      [self setFlags:(LSLaunchFlags)[[plist objectForKey:kApplicationLSFlagsKey] integerValue]];
      [self setAction:WBOSTypeFromString([plist objectForKey:kApplicationActionKey])];
      [self decodeFlags:[[plist objectForKey:kApplicationFlagsKey] integerValue]];
      
      switch ([self action]) {
        case kApplicationHideFront:
        case kApplicationHideOther:
          break;
        default: {
          _application = [[WBApplication alloc] initWithSerializedValues:plist];
        }
      }
    }
    
    /* Update description */
    NSString *description = ApplicationActionDescription(self, [_application name]);
    if (description)
      [self setActionDescription:description];
  }
  return self;
}

- (void)dealloc {
  if (aa_icon) {
    ReleaseIconRef(aa_icon);
    aa_icon = NULL;
  }
}

#pragma mark -
- (BOOL)serialize:(NSMutableDictionary *)plist {
  if ([super serialize:plist]) {
    /* Do not serialize alias and application is useless */
    switch ([self action]) {
      case kApplicationHideFront:
      case kApplicationHideOther:
        break;
      default: {
        if (_application)
          [_application serialize:plist];
        
        NSString *name = [[NSFileManager defaultManager] displayNameAtPath:[self path]];
        if (name)
          [plist setObject:name forKey:kApplicationNameKey];
      }
    }
    
    [plist setObject:@(_flags) forKey:kApplicationLSFlagsKey];
    [plist setObject:@([self encodeFlags]) forKey:kApplicationFlagsKey];
    [plist setObject:WBStringForOSType(_action) forKey:kApplicationActionKey];
    return YES;
  }
  return NO;
}

/* Do not check application path at load time */
- (SparkAlert *)actionDidLoad {
  switch (_action) {
    case kApplicationLaunch:
    case kApplicationQuit:
    case kApplicationToggle:
		case kApplicationActivateQuit:
    case kApplicationForceQuitAppli:
      // TODO check application path if editor.
      break;
      /* Hide */
    case kApplicationHideOther:
    case kApplicationHideFront:
      /* Kill */
    case kApplicationForceQuitFront:
    case kApplicationForceQuitDialog:
      break;
      
    default:
      return [SparkAlert alertWithMessageText:@"INVALID_ACTION_ALERT"
                    informativeTextWithFormat:@"INVALID_ACTION_ALERT_MSG"];
  }
  return nil;
}

- (SparkAlert *)verify {
  switch (_action) {
    case kApplicationLaunch:
    case kApplicationQuit:
    case kApplicationToggle:
		case kApplicationActivateQuit:
    case kApplicationForceQuitAppli:
      if (![self path]) {
        NSString *title = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT", nil, kApplicationActionBundle,
                                                                                        @"Check * App Not Found *") , [self name]];
        return [SparkAlert alertWithMessageText:title
                      informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT_MSG",
                                                                                   nil, kApplicationActionBundle,@"Check * App Not Found *"), [self name]];
      }
      return nil;
    default:
      return nil;
  }
}

- (SparkAlert *)performAction {
  SparkAlert *alert = [self verify];
  if (!alert) {
    switch (_action) {
      case kApplicationLaunch:
        [self launchApplication];
        break;
      case kApplicationQuit:
        [self quitApplication];
        break;
      case kApplicationToggle:
        [self toggleApplicationState];
        break;
			case kApplicationActivateQuit:
				[self activateQuitApplication];
				break;
				
      case kApplicationHideFront:
        [self hideFront];
        break;
      case kApplicationHideOther:
        [self hideOthers];
        break;
        
      case kApplicationForceQuitAppli:
        [self forceQuitApplication];
        break;
      case kApplicationForceQuitFront:
        [self forceQuitFront];
        break;
      case kApplicationForceQuitDialog:
        [self forceQuitDialog];
        break;
    }
  }
  return alert;
}

- (BOOL)needsToBeRunOnMainThread {
  return NO;
}
- (BOOL)supportsConcurrentRequests {
  return YES;
}

- (BOOL)shouldSaveIcon {
  switch ([self action]) {
    case kApplicationQuit:
    case kApplicationLaunch:
    case kApplicationToggle:
		case kApplicationActivateQuit:
    case kApplicationForceQuitAppli:
      return YES;
    default:
      return NO;
  }
}
/* Icon lazy loading */
- (NSImage *)icon {
  NSImage *icon = [super icon];
  if (!icon) {
    icon = ApplicationActionIcon(self);
    [super setIcon:icon];
  }
  return icon;
}

- (NSImage *)iconCacheMiss {
  NSImage *icon = [_application icon];
  if (icon) {
    WBImageSetRepresentationsSize(icon, NSMakeSize(16, 16));
  }
  return icon;
}

#pragma mark -
- (NSString *)path {
  return [_application path];
}
- (void)setPath:(NSString *)path {
  if (!_application && path)
    _application = [[WBApplication alloc] initWithPath:path];
  else if (path)
    [_application setPath:path];
  else if (_application) {
    _application = nil;
  }
}

- (BOOL)reopen {
  return aa_aaFlags.reopen;
}
- (void)setReopen:(BOOL)flag {
  SPXFlagSet(aa_aaFlags.reopen, flag);
}

- (NSInteger)activation {
  return aa_aaFlags.active;
}
- (void)setActivation:(NSInteger)actv {
  aa_aaFlags.active = actv & 0x3;
}

- (BOOL)usesSharedVisual {
  return aa_aaFlags.visual;
}
- (void)setUsesSharedVisual:(BOOL)flag {
  SPXFlagSet(aa_aaFlags.visual, flag);
}

- (void)getVisualSettings:(ApplicationVisualSetting *)settings {
  settings->launch = aa_aaFlags.atLaunch;
  settings->activation = aa_aaFlags.atActivate;
}
- (void)setVisualSettings:(ApplicationVisualSetting *)settings {
  aa_aaFlags.atLaunch = settings->launch;
  aa_aaFlags.atActivate = settings->activation;
}

- (void)displayNotification {
  if (!aa_icon) {
    FSRef path;
    if ([[self path] getFSRef:&path]) {
      GetIconRefFromFileInfo(&path, 0, NULL,
                             kFSCatInfoNone, NULL,
                             kIconServicesNoBadgeFlag, 
                             &aa_icon, NULL);
    }
  }
  SparkNotificationDisplayIcon(aa_icon, -1);
}

#pragma mark -
- (NSRunningApplication *)applicationProcess {
  return [NSRunningApplication runningApplicationsWithBundleIdentifier:_application.bundleIdentifier].firstObject;
}

- (void)hideFront {
  ProcessSerialNumber front = {kNoProcess, kNoProcess};
  if (noErr == GetFrontProcess(&front)) {
    ShowHideProcess(&front, false);
  }
}

- (void)hideOthers {
  ProcessSerialNumber front = {kNoProcess, kNoProcess};
  GetFrontProcess(&front);

  /* ShowHideProcess can change process order, and potentialy affect enumeration */
  unsigned idx = 0;
  unsigned max = 128;
  ProcessSerialNumber psn;
  ProcessSerialNumber processes[128];
  psn.lowLongOfPSN = kNoProcess;
  psn.highLongOfPSN = 0;
  while (noErr == GetNextProcess(&psn) && idx < max) {
    Boolean same;
    if (noErr == SameProcess(&front, &psn, &same) && !same) {
      processes[idx] = psn;
      idx++;
    }
  }
  while (idx-- > 0) {
    ShowHideProcess(&processes[idx], false);
  }
}

- (void)activate:(NSRunningApplication *)app {
	switch ([self activation]) {
		case kFlagsBringAllFront:
      [app activateWithOptions:NSApplicationActivateAllWindows];
			break;
		case kFlagsBringMainFront:
      [app activateWithOptions:0];
			break;
	}
	if ([self activation] != kFlagsDoNothing) {
		if ([self reopen]) {
			/* TODO: improve reopen event */
			AppleEvent reopen = WBAEEmptyDesc();
			OSStatus err = WBAECreateEventWithTargetProcessIdentifier(app.processIdentifier, kCoreEventClass, kAEReopenApplication, &reopen);
			require_noerr(err, bail);
			
			err = WBAEAddBoolean(&reopen, 'frnt', false);
			require_noerr(err, bail);
			
			err = WBAESendEventNoReply(&reopen);
			require_noerr(err, bail);
			
		bail:
			WBAEDisposeDesc(&reopen);
		}
		
		/* Handle visual settings */
		ApplicationVisualSetting settings;
		if ([self usesSharedVisual])
			[ApplicationAction getSharedSettings:&settings];
		else
			[self getVisualSettings:&settings];
		
		if (_flags & kLSLaunchAndHideOthers)
			[self hideOthers];
		if (settings.activation)
			[self performSelectorOnMainThread:@selector(displayNotification) withObject:nil waitUntilDone:NO];
	}
}

- (void)launchApplication {
  NSRunningApplication *app = nil;
  if (!(_flags & kLSLaunchNewInstance) && (app = self.applicationProcess)) {
    [self activate:app];
  } else {
    [self launchAppWithFlag:kLSLaunchDefaults | _flags];
		
		/* Handle visual feedback */
		ApplicationVisualSetting settings;
		if ([self usesSharedVisual])
			[ApplicationAction getSharedSettings:&settings];
		else
			[self getVisualSettings:&settings];
		
    if (settings.launch)
      [self performSelectorOnMainThread:@selector(displayNotification) withObject:nil waitUntilDone:NO];
  }
}

- (void)quitApplication {
  NSRunningApplication *app = self.applicationProcess;
  if (app)
    [app terminate];
}

- (void)forceQuitApplication {
  NSRunningApplication *app = self.applicationProcess;
  if (app && ![app terminate])
    [app forceTerminate];
}

- (void)toggleApplicationState {
  NSRunningApplication *app = self.applicationProcess;
  if (app && !app.terminated) {
    [app terminate];
  } else {
    /* toogle incompatible with new instance */
    if (_flags & kLSLaunchNewInstance)
      _flags &= ~kLSLaunchNewInstance;
    [self launchApplication];
  }	
}

- (void)activateQuitApplication {
  NSRunningApplication *app = self.applicationProcess;
  if (app) {
		if (app.active) {
			[app terminate];
		} else {
			[self activate:app];
		}
  } else {
    /* toogle incompatible with new instance */
    if (_flags & kLSLaunchNewInstance)
      _flags &= ~kLSLaunchNewInstance;
    [self launchApplication];
  }
}

- (void)forceQuitFront {
  NSRunningApplication *front = [[NSWorkspace sharedWorkspace] frontmostApplication];
  if (front && ![front terminate])
    [front forceTerminate];
}

- (void)forceQuitDialog {
  WBAESendSimpleEventToTarget(WBAESystemTarget(), kCoreEventClass, 'apwn');
}

- (BOOL)launchAppWithFlag:(LSLaunchFlags)flag {
  FSRef ref;
  BOOL result = NO;
  LSApplicationParameters params = {};
  NSString *path = [self path];
  if (path != nil && [path getFSRef:&ref]) {
    params.application = &ref;
    params.flags = flag | kLSLaunchDefaults;
    result = (noErr == LSOpenApplication(&params, nil));
  }
  return result;
}

@end

NSImage *ApplicationActionIcon(ApplicationAction *action) {
  NSString *name = nil;
  switch ([action action]) {
    case kApplicationHideFront:
      name = @"AAHide";
      break;
    case kApplicationHideOther:
      name = @"AAHide";
      break;      
    case kApplicationForceQuitFront:
      name = @"AAStop";
      break;
    case kApplicationForceQuitDialog:
      name = @"AAWStop";
      break;
    default:
      break;
  }
  return name ? [NSImage imageNamed:name inBundle:kApplicationActionBundle] : nil;
}

NSString *ApplicationActionDescription(ApplicationAction *anAction, NSString *name) {
  NSString *desc = nil;
  switch ([anAction action]) {
    case kApplicationLaunch:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_LAUNCH", nil, kApplicationActionBundle,
                                               @"Launch Application * Action Description *");
      break;
    case kApplicationToggle:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SWITCH_OPEN_CLOSE", nil, kApplicationActionBundle,
                                               @"Open/Close Application * Action Description *");
      break;
		case kApplicationActivateQuit:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SWITCH_ACTIVE_CLOSE", nil, kApplicationActionBundle,
																								@"Open - Activate/Close Application * Action Description *");
      break;
    case kApplicationQuit:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_QUIT", nil, kApplicationActionBundle,
                                               @"Quit Application * Action Description *");
      break;
      
    case kApplicationHideFront:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_HIDE_FRONT", nil, kApplicationActionBundle,
                                                @"Hide Front Applications * Action Description *");
      break;
    case kApplicationHideOther:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_HIDE_ALL", nil, kApplicationActionBundle,
                                                @"Hide All Applications * Action Description *");
      break;
    case kApplicationForceQuitAppli:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_FORCE_QUIT_APPLI", nil, kApplicationActionBundle,
                                                @"Force Quit Application * Action Description *");
      break;
    case kApplicationForceQuitFront:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_FORCE_QUIT_FRONT", nil, kApplicationActionBundle,
                                               @"Force Quit Front * Action Description *");
      break;
    case kApplicationForceQuitDialog:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_FORCE_QUIT_DIALOG", nil, kApplicationActionBundle,
                                                @"Force Quit Dialog * Action Description *");
      break;
    default:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_ERROR", nil, kApplicationActionBundle,
                                               @"Unknow Action * Action Description *");
  }
  if (name)
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESCRIPTION", nil, kApplicationActionBundle,
                                                                         @"Description: %1$@ => Action, %2$@ => App Name"), desc, name];
  else return desc;
}

