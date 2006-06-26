//
//  ApplicationAction.m
//  Spark
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "ApplicationAction.h"
#import "ApplicationActionPlugin.h"
#import "ASExtension.h"

#import <ShadowKit/SKBezelItem.h>

static NSString * const kHotKeySignKey = @"App Sign";
static NSString * const kHotKeyActionKey = @"Action";
static NSString * const kHotKeyFlagsKey = @"LSFlags";
static NSString * const kHotKeyAliasKey = @"App Alias";
static NSString * const kHotKeyBundleIdKey = @"BundleID";

@implementation ApplicationAction

#pragma mark Protocols Implementation

- (id)copyWithZone:(NSZone *)zone {
  ApplicationAction* copy = [super copyWithZone:zone];
  copy->sa_appAction = sa_appAction;
  copy->sa_flags = sa_flags;
  [copy setAlias:sa_alias];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:sa_flags forKey:kHotKeyFlagsKey];
  [coder encodeInt:sa_appAction forKey:kHotKeyActionKey];
  if (sa_alias)
    [coder encodeObject:sa_alias forKey:kHotKeyAliasKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    sa_flags = [coder decodeIntForKey:kHotKeyFlagsKey];
    sa_appAction = [coder decodeIntForKey:kHotKeyActionKey];
    sa_alias = [[coder decodeObjectForKey:kHotKeyAliasKey] retain];
  }
  return self;
}

#pragma mark -
#pragma mark Required Methods.
- (id)initFromPropertyList:(id)plist {
  if (self = [super initFromPropertyList:plist]) {
    SKApplicationAlias *alias = [[SKApplicationAlias alloc] initWithData:[plist objectForKey:kHotKeyAliasKey]];
    if (![alias path]) {// !!!:fox:20040315 => alias never nil so use alias->path for test (V1.0)
      id sign = [plist objectForKey:kHotKeySignKey];
      if (sign)
        [alias setSignature:sign];
    }
    if (![alias path]) {
      id bundleId = [plist objectForKey:kHotKeyBundleIdKey];
      if (bundleId)
        [alias setBundleIdentifier:bundleId];      
    }
    if (alias) {
      [self setAlias:alias];
      [alias release];
    }
    [self setAppAction:[[plist objectForKey:kHotKeyActionKey] intValue]];
    [self setFlags:[[plist objectForKey:kHotKeyFlagsKey] intValue]];
  }
  return self;
}

- (void)dealloc {
  [sa_alias release];
  [sa_bezel release];
  [super dealloc];
}

- (NSMutableDictionary *)propertyList {
  id dico = [super propertyList];
  id aliasData = [sa_alias data];
  if (aliasData) {
    [dico setObject:aliasData forKey:kHotKeyAliasKey];
  }
  id sign = [self sign];
  if (sign)
    [dico setObject:sign forKey:kHotKeySignKey];
  id bundleId = [self bundleId];
  if (bundleId)
    [dico setObject:bundleId forKey:kHotKeyBundleIdKey];
  [dico setObject:SKInt(sa_appAction) forKey:kHotKeyActionKey];
  [dico setObject:SKInt(sa_flags) forKey:kHotKeyFlagsKey];
  return dico;
}

- (SparkAlert *)check {
  /* Don't check path if hide or hide all */
  if (sa_appAction != kHideFrontTag && sa_appAction != kHideAllTag) {
    if ([self path] == nil) {
      id title = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT", nil,ApplicationActionBundle,
                                                                               @"Check * App Not Found *") , [self name]];
      return [SparkAlert alertWithMessageText:title
                    informativeTextWithFormat:NSLocalizedStringFromTableInBundle(@"INVALID_APPLICATION_ALERT_MSG",
                                                                                 nil,ApplicationActionBundle,@"Check * App Not Found *"), [self name]];
    }
  }
  return nil;
}

- (SparkAlert *)execute {
  id alert = [self check];
  if (alert == nil) {
    switch (sa_appAction) {
      case kHideFrontTag:
        [self hideFront];
        break;
      case kHideAllTag:
        [self hideOthers];
        break;
      case kOpenActionTag:
        [self launchApplication];
        break;
      case kOpenCloseActionTag:
        [self toggleApplicationState];
        break;
      case kQuitActionTag:
        [self quitApplication];
        break;
      case kKillActionTag:
        [self killApplication];
        break;
    }
  }
  return alert;
}

- (NSString *)sign {
  id sign = [sa_alias signature];
  return ([sign isEqualToString:@"????"]) ? nil : sign;
}

- (void)setPath:(NSString *)path {
  if (sa_alias) {
    [sa_alias release];
    sa_alias = nil;
  }
  sa_alias = [[SKApplicationAlias alloc] initWithPath:path];
}

- (NSString *)path {
  return [sa_alias path];
}

- (void)setAlias:(SKApplicationAlias *)alias {
  if (sa_alias != alias) {
    [sa_alias release];
    sa_alias = [alias copy];
  }
}

- (SKApplicationAlias *)alias {
  return sa_alias;
}

- (void)setAppAction:(int)action {
  sa_appAction = action;
}

- (int)appAction {
  return sa_appAction;
}

- (void)setFlags:(int)flags {
  sa_flags = flags;
}

- (int)flags {
  return sa_flags;
}

- (NSString *)bundleId {
  return [sa_alias bundleIdentifier];
}


#pragma mark -

- (BOOL)getApplicationProcess:(ProcessSerialNumber *)psn {
  psn->highLongOfPSN = kNoProcess;
  psn->lowLongOfPSN = kNoProcess;
  id sign = [self sign];
  if (sign) {
    *psn = SKGetProcessWithSignature(SKHFSTypeCodeFromFileType(sign));
  } 
  if (kNoProcess == psn->lowLongOfPSN && kNoProcess == psn->highLongOfPSN) {
    id bundle = [self bundleId];
    if (bundle) {
      *psn = SKGetProcessWithBundleIdentifier((CFStringRef)bundle);
    }
  }
  return (psn->highLongOfPSN != kNoProcess) || (psn->lowLongOfPSN != kNoProcess);
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

  ProcessSerialNumber psn = {kNoProcess, kNoProcess};
  while (noErr == GetNextProcess(&psn) && psn.lowLongOfPSN != kNoProcess) {
    if (psn.lowLongOfPSN != front.lowLongOfPSN || psn.highLongOfPSN != front.highLongOfPSN) {
      ShowHideProcess(&psn, false);
    }
  }
}

- (void)launchApplication {
  ProcessSerialNumber psn;
  if (!(sa_flags & kLSLaunchNewInstance) && [self getApplicationProcess:&psn]) {
    SetFrontProcess(&psn);
    ShadowAESendSimpleEventToProcess(&psn, kCoreEventClass, kAEReopenApplication);
    if (sa_flags & kLSLaunchAndHideOthers)
      [self hideOthers];
  } else {
    [self launchAppWithFlag:kLSLaunchDefaults | sa_flags];
  }
  if (!sa_bezel) {
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[self path]];
    if (icon) [icon setSize:NSMakeSize(128, 128)];
    sa_bezel = [[SKBezelItem alloc] initWithContent:icon];
    [sa_bezel setDelay:1];
  }
  [sa_bezel display:nil];
}

- (void)quitApplication {
  ProcessSerialNumber psn;
  if ([self getApplicationProcess:&psn]) {
    QuitApplication(&psn);
  }
}

- (void)toggleApplicationState {
  ProcessSerialNumber psn;
  if ([self getApplicationProcess:&psn]) {
    QuitApplication(&psn);
  } else {
    [self launchApplication];
  }
}

- (void)killApplication {
  DLog(@"Kill Application");
  ProcessSerialNumber psn;
  if ([self getApplicationProcess:&psn]) {
    KillApplication(&psn);
  }
}

- (void)relaunchApplication {
  DLog(@"relaunch Application");
  [self quitApplication];
  [self launchApplication];
}

- (BOOL)launchAppWithFlag:(int)flag {
  LSLaunchURLSpec spec;
  BOOL result = NO;
  CFStringRef path = (CFStringRef)[self path];
  if (path != nil) {
    spec.appURL = (CFURLRef)CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, kCFURLPOSIXPathStyle, NO);
    if (spec.appURL != nil) {
      spec.itemURLs = nil;
      spec.passThruParams = nil;
      spec.launchFlags = flag | kLSLaunchDefaults;
      spec.asyncRefCon = nil;
      result = (noErr == LSOpenFromURLSpec(&spec, nil));
      CFRelease(spec.appURL);
    }
  }
  return result;
}

@end
