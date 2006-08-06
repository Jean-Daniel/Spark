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

#import <ShadowKit/SKAlias.h>
#import <ShadowKit/SKBezelItem.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKApplication.h>
#import <ShadowKit/SKProcessFunctions.h>

static NSString * const kHotKeySignKey = @"App Sign";
static NSString * const kHotKeyActionKey = @"Action";
static NSString * const kHotKeyFlagsKey = @"LSFlags";
static NSString * const kHotKeyAliasKey = @"App Alias";
static NSString * const kHotKeyBundleIdKey = @"BundleID";

@implementation ApplicationAction

#pragma mark Protocols Implementation

- (id)copyWithZone:(NSZone *)zone {
  ApplicationAction* copy = [super copyWithZone:zone];
  copy->sa_action = sa_action;
  copy->sa_flags = sa_flags;
  [copy setAlias:sa_alias];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:sa_flags forKey:kHotKeyFlagsKey];
  [coder encodeInt:sa_action forKey:kHotKeyActionKey];
  if (sa_alias)
    [coder encodeObject:sa_alias forKey:kHotKeyAliasKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    sa_flags = [coder decodeIntForKey:kHotKeyFlagsKey];
    sa_action = [coder decodeIntForKey:kHotKeyActionKey];
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
      OSType sign = [[plist objectForKey:kHotKeySignKey] unsignedIntValue];
      if (sign)
        [alias setSignature:sign];
    }
    if (![alias path]) {
      NSString *bundleId = [plist objectForKey:kHotKeyBundleIdKey];
      if (bundleId)
        [alias setBundleIdentifier:bundleId];      
    }
    if (alias) {
      [self setAlias:alias];
      [alias release];
    }
    [self setAction:[[plist objectForKey:kHotKeyActionKey] intValue]];
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
  OSType sign = [self signature];
  if (sign)
    [dico setObject:SKUInt(sign) forKey:kHotKeySignKey];
  id bundleId = [self bundleIdentifier];
  if (bundleId)
    [dico setObject:bundleId forKey:kHotKeyBundleIdKey];
  [dico setObject:SKInt(sa_action) forKey:kHotKeyActionKey];
  [dico setObject:SKInt(sa_flags) forKey:kHotKeyFlagsKey];
  return dico;
}

- (SparkAlert *)check {
  /* Don't check path if hide or hide all */
  if (sa_action != kHideFrontTag && sa_action != kHideAllTag) {
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
    switch (sa_action) {
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

- (OSType)signature {
  OSType sign = [sa_alias signature];
  return sign == kUnknownType ? 0 : sign;
}

- (NSString *)bundleIdentifier {
  return [sa_alias bundleIdentifier];
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

- (void)setAction:(int)action {
  sa_action = action;
}

- (int)action {
  return sa_action;
}

- (void)setFlags:(int)flags {
  sa_flags = flags;
}

- (int)flags {
  return sa_flags;
}

#pragma mark -

- (BOOL)getApplicationProcess:(ProcessSerialNumber *)psn {
  psn->highLongOfPSN = kNoProcess;
  psn->lowLongOfPSN = kNoProcess;
  OSType sign = [self signature];
  if (sign) {
    *psn = SKGetProcessWithSignature(sign);
  } 
  if (kNoProcess == psn->lowLongOfPSN && kNoProcess == psn->highLongOfPSN) {
    NSString *bundle = [self bundleIdentifier];
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
  while (noErr == GetNextProcess(&psn)) {
    Boolean same;
    if (noErr == SameProcess(&front, &psn, &same) && !same) {
      ShowHideProcess(&psn, false);
    }
  }
}

- (void)launchApplication {
  ProcessSerialNumber psn;
  if (!(sa_flags & kLSLaunchNewInstance) && [self getApplicationProcess:&psn]) {
    SetFrontProcess(&psn);
    SKAESendSimpleEventToProcess(&psn, kCoreEventClass, kAEReopenApplication);
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
