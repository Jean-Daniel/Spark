/*
 *  ApplicationAction.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) Shadow Lab. 2004 - 2006. All rights reserved.
 */

#import "ApplicationAction.h"

#import <SparkKit/SparkShadowKit.h>

#import <ShadowKit/SKAlias.h>
#import <ShadowKit/SKIconView.h>
#import <ShadowKit/SKBezelItem.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKApplication.h>
#import <ShadowKit/SKProcessFunctions.h>

static NSString * const kApplicationNameKey = @"ApplicationName";
static NSString * const kApplicationFlagsKey = @"ApplicationFlags";
static NSString * const kApplicationActionKey = @"ApplicationAction";

static NSString * const kApplicationAliasKey = @"ApplicationAlias";
/* Only for coding */
static NSString * const kApplicationIdentifierKey = @"kApplicationIdentifierKey";

static
SKBezelItem *ApplicationSharedVisual() {
  static SKBezelItem *visual = nil;
  if (visual)
    return visual;
  @synchronized ([ApplicationAction class]) {
    if (!visual) {
      visual = [[SKBezelItem alloc] initWithContent:[[SKIconView alloc] initWithFrame:NSMakeRect(0, 0, 128, 128)]];
    }
  }
  return visual;
}

@implementation ApplicationAction
#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  ApplicationAction* copy = [super copyWithZone:zone];
  copy->aa_flags = aa_flags;
  copy->aa_action = aa_action;
  
  copy->aa_alias = [aa_alias copy];
  copy->aa_application = [aa_application copy];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:aa_flags forKey:kApplicationFlagsKey];
  [coder encodeInt:aa_action forKey:kApplicationActionKey];
  
  if (aa_alias)
    [coder encodeObject:aa_alias forKey:kApplicationAliasKey];
  if (aa_application)
    [coder encodeObject:aa_application forKey:kApplicationIdentifierKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    aa_flags = [coder decodeIntForKey:kApplicationFlagsKey];
    aa_action = [coder decodeIntForKey:kApplicationActionKey];
    
    aa_alias = [[coder decodeObjectForKey:kApplicationAliasKey] retain];
    aa_application = [[coder decodeObjectForKey:kApplicationIdentifierKey] retain];
  }
  return self;
}

#pragma mark -
- (id)init {
  if (self = [super init]) {
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
      return kApplicationForceQuit;
    case 5:
      return kApplicationHideOther;
    case 6:
      return kApplicationHideFront;
  }
  return 0;
}

- (void)initFromOldPropertyList:(id)plist {
  /* Simply load alias and application without control (lazy resolution) */
  aa_alias = [[SKAlias alloc] initWithData:[plist objectForKey:@"App Alias"]];
  aa_application = [[SKApplication alloc] init];
  OSType sign = [[plist objectForKey:@"App Sign"] intValue];
  if (sign) {
    [aa_application setSignature:sign];
  } else {
    NSString *bundle = [plist objectForKey:@"BundleID"];
    if (bundle) {
      [aa_application setBundleIdentifier:bundle];
    }
  }

  [self setFlags:[[plist objectForKey:@"LSFlags"] intValue]];
  [self setAction:_ApplicationTypeFromTag([[plist objectForKey:@"Action"] intValue])];
}

- (id)initWithSerializedValues:(NSDictionary *)plist {
  if (self = [super initWithSerializedValues:plist]) {
    if ([self version] < 0x200) {
      [self initFromOldPropertyList:plist];
      [self setVersion:0x200];
    } else {
      [self setFlags:[[plist objectForKey:kApplicationFlagsKey] unsignedIntValue]];
      [self setAction:SKOSTypeFromString([plist objectForKey:kApplicationActionKey])];
      
      switch ([self action]) {
        case kApplicationHideFront:
        case kApplicationHideOther:
          break;
        default:
          aa_application = [[SKApplication alloc] initWithSerializedValues:plist];
          aa_alias = [[SKAlias alloc] initWithData:[plist objectForKey:kApplicationAliasKey]];
      }
    }
  }
  return self;
}

- (void)dealloc {
  [aa_alias release];
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
        NSData *alias = [aa_alias data];
        if (alias)
          [plist setObject:alias forKey:kApplicationAliasKey];
        
        if (aa_application)
          [aa_application serialize:plist];
        
        NSString *name = [[NSFileManager defaultManager] displayNameAtPath:[self path]];
        if (name)
          [plist setObject:name forKey:kApplicationNameKey];
      }
    }
    
    [plist setObject:SKUInt(aa_flags) forKey:kApplicationFlagsKey];
    [plist setObject:SKStringForOSType(aa_action) forKey:kApplicationActionKey];
    return YES;
  }
  return NO;
}

- (SparkAlert *)check {
  /* Don't check path if hide or hide all */
//  if (sa_action != kHideFrontTag && sa_action != kHideAllTag) {
//    if ([self path] == nil) {
//      id title = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT", nil,ApplicationActionBundle,
//                                                                               @"Check * App Not Found *") , [self name]];
//      return [SparkAlert alertWithMessageText:title
//                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT_MSG",
//                                                                                 nil,ApplicationActionBundle,@"Check * App Not Found *"), [self name]];
//    }
//  }
  return nil;
}

- (SparkAlert *)execute {
  id alert = [self check];
  if (alert == nil) {
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
      case kApplicationForceQuit:
        [self killApplication];
        break;
      case kApplicationHideFront:
        [self hideFront];
        break;
      case kApplicationHideOther:
        [self hideOthers];
        break;
    }
  }
  return alert;
}

- (void)setPath:(NSString *)path {
  if (aa_alias)
    [aa_alias setPath:path];
  else
    aa_alias = [[SKAlias alloc] initWithPath:path];
  
  [aa_application release];
  aa_application = path ? [[SKApplication alloc] initWithPath:path] : nil;
}

- (NSString *)path {
  return [aa_alias path] ? : [aa_application path];
}

- (void)setAlias:(SKAlias *)alias {
  SKSetterCopy(aa_alias, alias);
}

- (SKAlias *)alias {
  return aa_alias;
}

- (ApplicationActionType)action {
  return aa_action;
}
- (void)setAction:(ApplicationActionType)action {
  aa_action = action;
}

- (LSLaunchFlags)flags {
  return aa_flags;
}
- (void)setFlags:(LSLaunchFlags)flags {
  aa_flags = flags;
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
  ProcessSerialNumber processes[64];
  ProcessSerialNumber *psn = processes;
  psn->lowLongOfPSN = kNoProcess;
  psn->highLongOfPSN = 0;
  while (noErr == GetNextProcess(psn)) {
    Boolean same;
    if (noErr == SameProcess(&front, psn, &same) && !same) {
      psn++;
    }
  }
  psn = processes;
  while (psn->lowLongOfPSN != kNoProcess) {
    ShowHideProcess(psn++, false);
  }
}

- (void)launchApplication {
  ProcessSerialNumber psn;
  if (!(aa_flags & kLSLaunchNewInstance) && [self getApplicationProcess:&psn]) {
    SetFrontProcess(&psn); // kSetFrontProcessFrontWindowOnly
    SKAESendSimpleEventToProcess(&psn, kCoreEventClass, kAEReopenApplication);
    if (aa_flags & kLSLaunchAndHideOthers)
      [self hideOthers];
  } else {
    [self launchAppWithFlag:kLSLaunchDefaults | aa_flags];
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
    [self launchApplication];
  }
}

- (void)killApplication {
  DLog(@"Kill Application");
  ProcessSerialNumber psn;
  if ([self getApplicationProcess:&psn]) {
    KillProcess(&psn);
  }
}

- (void)relaunchApplication {
  DLog(@"relaunch Application");
  [self quitApplication];
  [self launchApplication];
}

- (BOOL)launchAppWithFlag:(int)flag {
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

NSString *ApplicationActionDescription(ApplicationAction *anAction, NSString *name) {
  NSString *desc = nil;
  switch ([anAction action]) {
    case kApplicationHideFront:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_HIDE_FRONT", nil,ApplicationActionBundle,
                                               @"Hide Front Applications * Action Description *");
      break;
    case kApplicationHideOther:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_HIDE_ALL", nil,ApplicationActionBundle,
                                               @"Hide All Applications * Action Description *");
      break;
    case kApplicationLaunch:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_LAUNCH", nil,ApplicationActionBundle,
                                               @"Launch Application * Action Description *");
      break;
    case kApplicationToggle:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_SWITCH_OPEN_CLOSE", nil,ApplicationActionBundle,
                                               @"Open/Close Application * Action Description *");
      break;
    case kApplicationQuit:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_QUIT", nil,ApplicationActionBundle,
                                               @"Quit Application * Action Description *");
      break;
    case kApplicationForceQuit:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_FORCE_QUIT", nil,ApplicationActionBundle,
                                               @"Force Quit Application * Action Description *");
      break;
    default:
      desc = NSLocalizedStringFromTableInBundle(@"DESC_ERROR", nil,ApplicationActionBundle,
                                               @"Unknow Action * Action Description *");
  }
  if (name)
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"DESCRIPTION", nil,ApplicationActionBundle,
                                                                         @"Description: %1$@ => Action, %2$@ => App Name"), desc, name];
  else return desc;
}

