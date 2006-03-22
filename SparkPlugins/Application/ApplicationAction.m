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

static NSString * const kHotKeyAliasKey = @"App Alias";
static NSString * const kHotKeySignKey = @"App Sign";
static NSString * const kHotKeyActionKey = @"Action";
static NSString * const kHotKeyFlagsKey = @"LSFlags";
static NSString * const kHotKeyBundleIdKey = @"BundleID";

@implementation ApplicationAction

#pragma mark Protocols Implementation

- (id)copyWithZone:(NSZone *)zone {
  ApplicationAction* copy = [super copyWithZone:zone];
  copy->_appAction = _appAction;
  copy->_flags = _flags;
  [copy setAlias:_alias];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:_flags forKey:kHotKeyFlagsKey];
  [coder encodeInt:_appAction forKey:kHotKeyActionKey];
  if (_alias)
    [coder encodeObject:_alias forKey:kHotKeyAliasKey];
  return;
}

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    _flags = [coder decodeIntForKey:kHotKeyFlagsKey];
    _appAction = [coder decodeIntForKey:kHotKeyActionKey];
    _alias = [[coder decodeObjectForKey:kHotKeyAliasKey] retain];
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
  [_alias release];
  [super dealloc];
}

- (NSMutableDictionary *)propertyList {
  id dico = [super propertyList];
  id aliasData = [_alias data];
  if (aliasData) {
    [dico setObject:aliasData forKey:kHotKeyAliasKey];
  }
  id sign = [self sign];
  if (sign)
    [dico setObject:sign forKey:kHotKeySignKey];
  id bundleId = [self bundleId];
  if (bundleId)
    [dico setObject:bundleId forKey:kHotKeyBundleIdKey];
  [dico setObject:SKInt(_appAction) forKey:kHotKeyActionKey];
  [dico setObject:SKInt(_flags) forKey:kHotKeyFlagsKey];
  return dico;
}

- (SparkAlert *)check {
  /* Don't check path if hide or hide all */
  if (_appAction != kHideFrontTag && _appAction != kHideAllTag) {
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
    switch (_appAction) {
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
  id sign = [_alias signature];
  return ([sign isEqualToString:@"????"]) ? nil : sign;
}

- (void)setPath:(NSString *)path {
  if (_alias) {
    [_alias release];
    _alias = nil;
  }
  _alias = [[SKApplicationAlias alloc] initWithPath:path];
}

- (NSString *)path {
  return [_alias path];
}

- (void)setAlias:(SKApplicationAlias *)alias {
  if (_alias != alias) {
    [_alias release];
    _alias = [alias copy];
  }
}

- (SKApplicationAlias *)alias {
  return _alias;
}

- (void)setAppAction:(int)action {
  _appAction = action;
}

- (int)appAction {
  return _appAction;
}

- (void)setFlags:(int)flags {
  _flags = flags;
}

- (int)flags {
  return _flags;
}

- (NSString *)bundleId {
  return [_alias bundleIdentifier];
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
  DLog(@"Open Application");
  ProcessSerialNumber psn;
  if (!(_flags & kLSLaunchNewInstance) && [self getApplicationProcess:&psn]) {
    SetFrontProcess(&psn);
    ShadowAESendSimpleEventToProcess(&psn, kCoreEventClass, kAEReopenApplication);
    if (_flags & kLSLaunchAndHideOthers)
      [self hideOthers];
  } else {
    [self launchAppWithFlag:kLSLaunchDefaults | _flags];
  }
}

- (void)quitApplication {
  DLog(@"Quit Application");
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
