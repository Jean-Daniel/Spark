/*
 *  ApplicationAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "ApplicationAction.h"

#import <SparkKit/SparkShadowKit.h>

#import <ShadowKit/SKAlias.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKImageUtils.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKProcessFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

static NSString * const kApplicationNameKey = @"ApplicationName";
static NSString * const kApplicationFlagsKey = @"ApplicationFlags";
static NSString * const kApplicationActionKey = @"ApplicationAction";
static NSString * const kApplicationLSFlagsKey = @"ApplicationLSFlags";

/* Only for coding */
static NSString * const kApplicationIdentifierKey = @"kApplicationIdentifierKey";

@implementation ApplicationAction

static bool sInit = false;

static 
ApplicationVisualSetting *AAGetSharedSettings() {
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
  } else {
    // Remove key
    SparkPreferencesSetValue(@"AAVisualLaunch", NULL, SparkPreferencesLibrary);
    SparkPreferencesSetValue(@"AAVisualActivate", NULL, SparkPreferencesLibrary);
    
    /* Reset to default */
    shared->launch = YES;
    shared->activation = NO;
  }
  *shared = *settings;
}

+ (void)didLoadLibrary:(NSNotification *)aNotification {
  /* Reset settings */
  sInit = false;
}

+ (void)setLibraryPreferenceValue:(id)value forKey:(NSString *)key {
  ApplicationVisualSetting *shared = AAGetSharedSettings();
  if ([@"AAVisualLaunch" isEqualToString:key]) {
    shared->launch = [value boolValue];
  } else if ([@"AAVisualActivate" isEqualToString:key]) {
    shared->activation = [value boolValue];
  }
}

+ (void)initialize {
  if ([ApplicationAction class] == self) {
    /* If daemon, listen updates */
    if (kSparkDaemonContext == SparkGetCurrentContext()) {
      SparkPreferencesRegisterObserver(self, @selector(setLibraryPreferenceValue:forKey:), 
                                       @"AAVisualLaunch", SparkPreferencesLibrary);
      SparkPreferencesRegisterObserver(self, @selector(setLibraryPreferenceValue:forKey:), 
                                       @"AAVisualActivate", SparkPreferencesLibrary);
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
  copy->aa_action = aa_action;
  copy->aa_lsFlags = aa_lsFlags;
  copy->aa_aaFlags = aa_aaFlags;
  
  copy->aa_application = [aa_application copy];
  return copy;
}

- (UInt32)encodeFlags {
  UInt32 flags = 0;
  flags |= aa_aaFlags.active & 0x3; /* bits 0 & 1 */
  if (aa_aaFlags.reopen) flags |= 1 << 2; /* bits 2 */
  
  if (aa_aaFlags.visual) flags |= 1 << 16; /* bits 16 */
  if (aa_aaFlags.atLaunch) flags |= 1 << 17; /* bits 17 */
  if (aa_aaFlags.atActivate) flags |= 1 << 18; /* bits 18 */
  return flags;
}
- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:aa_action forKey:kApplicationActionKey];
  [coder encodeInt:aa_lsFlags forKey:kApplicationLSFlagsKey];
  [coder encodeInt:[self encodeFlags] forKey:kApplicationFlagsKey];
  
  if (aa_application)
    [coder encodeObject:aa_application forKey:kApplicationIdentifierKey];
  return;
}

- (void)decodeFlags:(UInt32)flags {
  aa_aaFlags.active = flags & 0x3; /* bits 0 & 1 */
  if (flags & 1 << 2) aa_aaFlags.reopen = 1;
  
  if (flags & 1 << 16) aa_aaFlags.visual = 1;
  if (flags & 1 << 17) aa_aaFlags.atLaunch = 1;
  if (flags & 1 << 18) aa_aaFlags.atActivate = 1;
}
- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    aa_action = [coder decodeIntForKey:kApplicationActionKey];
    aa_lsFlags = [coder decodeIntForKey:kApplicationLSFlagsKey];
    [self decodeFlags:[coder decodeIntForKey:kApplicationFlagsKey]];
      
    aa_application = [[coder decodeObjectForKey:kApplicationIdentifierKey] retain];
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
SK_INLINE
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
  
  SKAlias *alias = nil;
  NSData *data = [plist objectForKey:@"App Alias"];
  if (data) {
    alias = [[SKAlias alloc] initWithData:data];
    aa_application = [[SKAliasedApplication alloc] initWithAlias:alias];
    [alias release];
  }
  if (!aa_application) {
    aa_application = [[SKAliasedApplication alloc] init];
    OSType sign = [[plist objectForKey:@"App Sign"] intValue];
    if (sign) {
      [aa_application setSignature:sign];
    } else {
      NSString *bundle = [plist objectForKey:@"BundleID"];
      if (bundle) {
        [aa_application setBundleIdentifier:bundle];
      }
    }
  }
  
  [self setFlags:[[plist objectForKey:@"LSFlags"] intValue]];
  [self setAction:_ApplicationTypeFromTag([[plist objectForKey:@"Action"] intValue])];
  
  if ([self shouldSaveIcon] && aa_application) {
    NSImage *icon = [aa_application icon];
    if (icon) {
      SKImageSetRepresentationsSize(icon, NSMakeSize(16, 16));
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
      [self setFlags:[[plist objectForKey:kApplicationLSFlagsKey] unsignedIntValue]];
      [self setAction:SKOSTypeFromString([plist objectForKey:kApplicationActionKey])];
      [self decodeFlags:[[plist objectForKey:kApplicationFlagsKey] unsignedIntValue]];
      
      switch ([self action]) {
        case kApplicationHideFront:
        case kApplicationHideOther:
          break;
        default: {
          aa_application = [[SKAliasedApplication alloc] initWithSerializedValues:plist];
        }
      }
    }
    
    /* Update description */
    NSString *description = ApplicationActionDescription(self, [aa_application name]);
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
  [aa_application release];
  [super dealloc];
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
        if (aa_application)
          [aa_application serialize:plist];
        
        NSString *name = [[NSFileManager defaultManager] displayNameAtPath:[self path]];
        if (name)
          [plist setObject:name forKey:kApplicationNameKey];
      }
    }
    
    [plist setObject:SKUInt(aa_lsFlags) forKey:kApplicationLSFlagsKey];
    [plist setObject:SKUInt([self encodeFlags]) forKey:kApplicationFlagsKey];
    [plist setObject:SKStringForOSType(aa_action) forKey:kApplicationActionKey];
    return YES;
  }
  return NO;
}

/* Do not check application path at load time */
- (SparkAlert *)actionDidLoad {
  switch (aa_action) {
    case kApplicationLaunch:
    case kApplicationQuit:
    case kApplicationToggle:
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
  switch (aa_action) {
    case kApplicationLaunch:
    case kApplicationQuit:
    case kApplicationToggle:
      if (![self path]) {
        NSString *title = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT", nil, kApplicationActionBundle,
                                                                                        @"Check * App Not Found *") , [self name]];
        return [SparkAlert alertWithMessageText:title
                      informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT_MSG",
                                                                                   nil, kApplicationActionBundle,@"Check * App Not Found *"), [self name]];
      }
      break;
  }
  return nil;
}

- (SparkAlert *)performAction {
  SparkAlert *alert = [self verify];
  if (!alert) {
    switch (aa_action) {
      case kApplicationLaunch:
        [self launchApplication];
        break;
      case kApplicationQuit:
        [self quitApplication];
        break;
      case kApplicationToggle:
        [self toggleApplicationState];
        break;
        
      case kApplicationHideFront:
        [self hideFront];
        break;
      case kApplicationHideOther:
        [self hideOthers];
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

- (BOOL)shouldSaveIcon {
  switch ([self action]) {
    case kApplicationQuit:
    case kApplicationLaunch:
    case kApplicationToggle:
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
  NSImage *icon = [aa_application icon];
  if (icon) {
    SKImageSetRepresentationsSize(icon, NSMakeSize(16, 16));
  }
  return icon;
}

#pragma mark -
- (NSString *)path {
  return [aa_application path];
}
- (void)setPath:(NSString *)path {
  if (!aa_application && path)
    aa_application = [[SKAliasedApplication alloc] initWithPath:path];
  else if (path)
    [aa_application setPath:path];
  else if (aa_application) {
    [aa_application release];
    aa_application = nil;
  }
}

- (ApplicationActionType)action {
  return aa_action;
}
- (void)setAction:(ApplicationActionType)action {
  aa_action = action;
}

- (SKAliasedApplication *)application {
  return aa_application;
}

- (LSLaunchFlags)flags {
  return aa_lsFlags;
}
- (void)setFlags:(LSLaunchFlags)flags {
  aa_lsFlags = flags;
}

- (BOOL)reopen {
  return aa_aaFlags.reopen;
}
- (void)setReopen:(BOOL)flag {
  SKSetFlag(aa_aaFlags.reopen, flag);
}

- (int)activation {
  return aa_aaFlags.active;
}
- (void)setActivation:(int)actv {
  aa_aaFlags.active = actv & 0x3;
}

- (BOOL)usesSharedVisual {
  return aa_aaFlags.visual;
}
- (void)setUsesSharedVisual:(BOOL)flag {
  SKSetFlag(aa_aaFlags.visual, flag);
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
- (BOOL)getApplicationProcess:(ProcessSerialNumber *)psn {
  *psn = [aa_application process];
  return psn->lowLongOfPSN != kNoProcess;
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

- (void)launchApplication {
  ProcessSerialNumber psn;
  ApplicationVisualSetting settings;
  if ([self usesSharedVisual])
    [ApplicationAction getSharedSettings:&settings];
  else
    [self getVisualSettings:&settings];
  
  if (!(aa_lsFlags & kLSLaunchNewInstance) && [self getApplicationProcess:&psn]) {
    switch ([self activation]) {
      case kFlagsBringAllFront:
        SetFrontProcess(&psn);
        break;
      case kFlagsBringMainFront:
        SetFrontProcessWithOptions(&psn, kSetFrontProcessFrontWindowOnly);
        break;
    }
    if ([self activation] != kFlagsDoNothing) {
      if ([self reopen])
        SKAESendSimpleEventToProcess(&psn, kCoreEventClass, kAEReopenApplication);
      if (aa_lsFlags & kLSLaunchAndHideOthers)
        [self hideOthers];
      if (settings.activation)
        [self displayNotification];
    }
  } else {
    [self launchAppWithFlag:kLSLaunchDefaults | aa_lsFlags];
    if (settings.launch)
      [self displayNotification];
  }
}

- (void)quitProcess:(ProcessSerialNumber *)psn {
  SKAESendSimpleEventToProcess(psn, kCoreEventClass, kAEQuitApplication);
}

- (void)quitApplication {
  ProcessSerialNumber psn;
  if ([self getApplicationProcess:&psn]) {
    [self quitProcess:&psn];
  }
}

- (void)toggleApplicationState {
  ProcessSerialNumber psn;
  if ([self getApplicationProcess:&psn]) {
    [self quitProcess:&psn];
  } else {
    /* toogle incompatible with new instance */
    if (aa_lsFlags & kLSLaunchNewInstance)
      aa_lsFlags &= ~kLSLaunchNewInstance;
    [self launchApplication];
  }
}

- (void)forceQuitFront {
  ProcessSerialNumber psn;
  if (noErr == GetFrontProcess(&psn))
    KillProcess(&psn);
}

- (void)forceQuitDialog {
  ProcessSerialNumber psn = {0, kSystemProcess};
  SKAESendSimpleEventToProcess(&psn, kCoreEventClass, 'apwn');
}

- (BOOL)launchAppWithFlag:(LSLaunchFlags)flag {
  BOOL result = NO;
  FSRef ref;
  LSLaunchFSRefSpec spec;
  bzero(&spec, sizeof(spec));
  NSString *path = [self path];
  if (path != nil && [path getFSRef:&ref]) {
    spec.appRef = &ref;
    spec.launchFlags = flag | kLSLaunchDefaults;
    result = (noErr == LSOpenFromRefSpec(&spec, nil));
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

