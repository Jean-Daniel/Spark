//
//  PluginInstaller.m
//  Spark Editor
//
//  Created by Grayfox on 15/12/2004.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "PluginInstaller.h"
#import "ScriptHandler.h"
#include <Security/Security.h>
#include <SecurityFoundation/SFAuthorization.h>

#define RM			"/bin/rm"
#define COPY		"/usr/bin/ditto"
#define MKDIR		"/bin/mkdir"

@implementation PluginInstaller

- (id)init {
  if (self = [super initWithWindowNibName:@"PluginInstall"]) {
    [self window];
  }
  return self;
}

- (void)dealloc {
  if (_src) CFRelease(_src);
  if (_dest) CFRelease(_dest);
  [_auth invalidateCredentials];
  [_auth release];
  [super dealloc];
}

- (void)updateUI {
  if (!_src) return;
  NSString *explainStr = nil;
  CFStringRef name = CFBundleGetValueForInfoDictionaryKey(_src, CFSTR("SparkPluginName"));
  if (_dest) {
    explainStr = [NSString stringWithFormat:NSLocalizedString(@"CONFIRM_REPLACE_OLDER_PLUGIN",
                                                              @"Explain: Older version (%@ => plugin name)"), name];
  } else {
    explainStr = [NSString stringWithFormat:NSLocalizedString(@"CONFIRM_INSTALL_PLUGIN", 
                                                              @"Explain: Should install (%@ => plugin name)"), name];
  }
  [explain setStringValue:explainStr];
  [installButton setTitle:(_dest) ? NSLocalizedString(@"CONFIRM_REPLACE_OLDER_PLUGIN_UPDATE", @"Install Plugin") : NSLocalizedString(@"CONFIRM_INSTALL_PLUGIN_INSTALL", @"Install Plugin")];
}

- (void)awakeFromNib {
  [self update:nil];
  [self updateUI];
}

- (SFAuthorization *)authorizations {
  if (!_auth) {
    AuthorizationItem items[3] = {
    {kAuthorizationRightExecute, strlen(RM), RM, 0},
    {kAuthorizationRightExecute, strlen(MKDIR), MKDIR, 0},
    {kAuthorizationRightExecute, strlen(COPY), COPY, 0},
    };
    AuthorizationRights rights;
    rights.count = 3;
    rights.items = items;
    _auth = [[SFAuthorization alloc] initWithFlags:kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights | kAuthorizationFlagPreAuthorize
                                            rights:&rights
                                       environment:kAuthorizationEmptyEnvironment];
  }
  return _auth;
}

- (CFBundleRef)source {
  return _src;
}

- (void)setSource:(CFBundleRef)source {
  if (_src != source) {
    if (_src) { CFRelease(_src); }
    _src = (source) ? (CFBundleRef)CFRetain(source) : nil;
    [self updateUI];
  }
}

- (CFBundleRef)destination {
  return _dest;
}

- (void)setDestination:(CFBundleRef)dest {
  if (_dest != dest) {
    if (_dest) { CFRelease(_dest); }
    _dest = (dest) ? (CFBundleRef)CFRetain(dest) : nil;
    [self updateUI];
  }
}

- (BOOL)removePlugin:(CFBundleRef)plugin fromDomain:(int)domain {
  NSURL *url = (id)CFBundleCopyBundleURL(_dest);
  NSString *path = [url path];
  [url release];
  if (domain == 0) { // User Domain
    return [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
  } else if (domain == 1) { // Computer domain
    SFAuthorization *auths = [self authorizations];
    if (!auths) return NO;
    const char *argv[] = {"-rf", [path cString], nil};
    OSStatus err = AuthorizationExecuteWithPrivileges([auths authorizationRef], 
                                                      RM, 
                                                      kAuthorizationFlagDefaults, 
                                                      (char **)argv,
                                                      NULL);
    return errAuthorizationSuccess == err;
  }
  return YES;
}

- (void)removeDestination {
  NSURL *url = (id)CFBundleCopyBundleURL(_dest);
  NSString *path = [url path];
  [url release];
  path = [path stringByDeletingLastPathComponent];
  DLog(@"Search Domain: %@", path);
  int domain = [[SparkPlugInLoader plugInPaths] indexOfObject:path];
  if (domain != NSNotFound) {
    [self removePlugin:_dest fromDomain:domain];
  }
}

#pragma mark -
- (IBAction)update:(id)sender {
  [adminInfo setHidden:[form selectedRow] == 0];
}

- (IBAction)install:(id)sender {
  BOOL result = NO;
  if (!_dest || (_dest && [self removeDestination])) {
    if ([form selectedRow] == 0) {
      result = [self copyPluginForUser];
    } else {
      result = [self copyPluginForComputer];
    }
  }
  if (!result) {
    NSBeep();
    NSRunAlertPanel(NSLocalizedString(@"INSTALL_PLUGIN_ALERT",
                                      @"Unable to install plugin"),
                    NSLocalizedString(@"INSTALL_PLUGIN_ALERT_MSG",
                                      @"Unable to install plugin"),
                    NSLocalizedString(@"OK",
                                      @"Alert default button"), nil, nil);
  } else {
    [self close];
    if (_dest) {
      if ([[NSApp delegate] serverState] == kSparkDaemonStarted) {
        [Spark restartDaemon];
      }
      [Spark restartSpark];
    }
  }
}

- (IBAction)cancel:(id)sender {
  [self close];
}

- (void)close {
  if ([[self window] isSheet]) {
    [NSApp endSheet:[self window]];
  }
  [super close];
}

- (BOOL)copyPluginForUser {
  NSURL *url = (id)CFBundleCopyBundleURL(_src);
  id srcPath = [url path];
  [url release];
  NSFileManager *manager = [NSFileManager defaultManager];
  if ([manager fileExistsAtPath:srcPath]) {
    id destination = [[SparkPlugInLoader plugInPaths] objectAtIndex:0];
    destination = [destination stringByAppendingPathComponent:[srcPath lastPathComponent]];
    if ([manager copyPath:srcPath toPath:destination handler:nil]) {
      FSRef folder;
      if ([[[SparkPlugInLoader plugInPaths] objectAtIndex:0] getFSRef:&folder]) {
        FNNotify(&folder, kFNDirectoryModifiedMessage, kNilOptions);
      }
      return YES;
    } else {
      return NO;
    }
  }
  return NO;
}

- (BOOL)copyPluginForComputer {
  OSStatus err = noErr;
  id destination = [[SparkPlugInLoader plugInPaths] objectAtIndex:1];
  NSURL *url = (id)CFBundleCopyBundleURL(_src);
  NSString *srcPath = [url path];
  [url release];
  [self authorizations];
  if (_auth) {
    id dstBundle = [destination stringByAppendingPathComponent:[srcPath lastPathComponent]];
    
    const char *argv1[] = {"-p", [dstBundle cString], nil};
    err = AuthorizationExecuteWithPrivileges([_auth authorizationRef], 
                                             MKDIR, 
                                             kAuthorizationFlagDefaults, 
                                             (char **)argv1,
                                             NULL);
    if (errAuthorizationSuccess == err) {
      const char *argv2[] = {"--rsrc", [srcPath cString], [dstBundle cString], nil};
      err = AuthorizationExecuteWithPrivileges([_auth authorizationRef], 
                                               COPY, 
                                               kAuthorizationFlagDefaults, 
                                               (char **)argv2,
                                               NULL);
    }
    [_auth invalidateCredentials];
    [_auth release];
    _auth = nil;
    if (noErr == err) {
      FSRef folder;
      if ([destination getFSRef:&folder]) {
        FNNotify(&folder, kFNDirectoryModifiedMessage, kNilOptions);
      }
    }
  }
  return errAuthorizationSuccess == err;
}

@end
