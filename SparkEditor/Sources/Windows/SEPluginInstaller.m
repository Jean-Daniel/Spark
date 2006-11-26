/*
 *  SEPluginInstaller.m
 *  Spark Editor
 *
 *  Created by Grayfox on 14/11/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEPluginInstaller.h"

#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKAEFunctions.h>

#import <SparkKit/SparkActionLoader.h>

NSString * const SEPluginInstallerDidInstallPluginNotification = @"SEPluginInstallerDidInstallPlugin";

@implementation SEPluginInstaller

- (id)init {
  if (self = [super init]) {
    
  }
  return self;
}

- (void)dealloc {
  [se_plugin release];
  [super dealloc];
}

#pragma mark -
- (IBAction)update:(id)sender {
  [ibInfo setHidden:[ibMatrix selectedRow] == 0];
}

- (IBAction)install:(id)sender {
  int domain;
  if ([ibMatrix selectedRow] == 0) {
    // User
    domain = kSKUserDomain;
  } else {
    // Local
    domain = kSKLocalDomain;
  }
  NSString *path = [self installPlugin:se_plugin domain:domain];
  if (path) {
    [self close:sender];
    [[SparkActionLoader sharedLoader] loadPlugin:path];
    [[NSWorkspace sharedWorkspace] openFile:[path stringByDeletingLastPathComponent]];
    [[NSNotificationCenter defaultCenter] postNotificationName:SEPluginInstallerDidInstallPluginNotification
                                                        object:nil];
  } else {
    DLog(@"Plugin installation failed");
  }
}

- (void)setPlugin:(NSString *)path {
  /* Load nib if needed */
  [self window];
  
  SKSetterRetain(se_plugin, path);
  /* Get plugin bundle ID */
  /* If plugin already installed => ? */
  NSString *name = [[NSFileManager defaultManager] displayNameAtPath:path];
  NSString *explain = [NSString stringWithFormat:@"The plugin '%@' must be install before you can use it. Do you want to install it now?", name];
  [ibExplain setStringValue:explain];
}

- (OSStatus)moveFile:(NSString *)file to:(NSString *)destination copy:(BOOL)flag {
  AppleEvent aevt = SKAEEmptyDesc();
  AEDesc desc = SKAEEmptyDesc();
  OSStatus err = fnfErr;
  
  FSRef src, dest;
  if ([file getFSRef:&src] && [destination getFSRef:&dest]) {
    OSType finder = 'MACS';
    err = AEBuildAppleEvent(kAECoreSuite, flag ? kAECopy : kAEMove, 
                            typeApplSignature, &finder, sizeof(OSType),
                            kAutoGenerateReturnID, kAnyTransactionID,
                            &aevt, NULL,    /* can be NULL */
                            "'----':fsrf(@), 'insh':fsrf(@)", sizeof(src), &src, sizeof(dest), &dest);
    require_noerr(err, dispose);
    
    err = SKAEAddSubject(&aevt);
    require_noerr(err, dispose);
    
    err = SKAEAddMagnitude(&aevt);
    require_noerr(err, dispose);
  
    err = SKAESendEventReturnAEDesc(&aevt, typeWildCard, &desc);
    require_noerr(err, dispose);
    
    if (typeNull == desc.descriptorType)
      err = userCanceledErr;
  }
  
dispose:
    SKAEDisposeDesc(&aevt);
  SKAEDisposeDesc(&desc);
  
  return err;
}

- (BOOL)installPlugin:(NSString *)plugin into:(NSString *)dest copy:(BOOL)flag {
  NSString *src = [plugin stringByDeletingLastPathComponent];
  NSArray *files = [NSArray arrayWithObject:[plugin lastPathComponent]];
  return [[NSWorkspace sharedWorkspace] performFileOperation:(flag ? NSWorkspaceCopyOperation : NSWorkspaceMoveOperation) source:src destination:dest files:files tag:NULL];
}

- (NSString *)installPlugin:(NSString *)plugin domain:(int)skdomain {
  if (![[NSFileManager defaultManager] fileExistsAtPath:plugin]) {
    NSRunAlertPanel(@"The plugin was not installed", @"Cannot find plugin at path \"%@\"", @"OK", nil, nil, plugin);
    return NO;
  }
  
  BOOL installed = NO;
  NSString *location = nil;
  NSArray *paths = [SparkActionLoader pluginPathsForDomains:skdomain];
  if (!paths || [paths count] == 0) {
    NSRunAlertPanel(@"The plugin was not installed", @"Spark cannot find plugin folder", @"OK", nil, nil);
  } else {
    NSString *path = [paths objectAtIndex:0];
    location = path;
    if (noErr == SKFSCreateFolder((CFStringRef)path)) {
      if (![self installPlugin:plugin into:path copy:YES]) {
        OSStatus err = [self moveFile:plugin to:path copy:YES];
        if (noErr != err && userCanceledErr != err) {
          NSRunAlertPanel(@"The plugin was not installed", @"An error prevent plugin installation.", @"OK", nil, nil);
        } else {
          installed = YES;
        }
      } else {
        installed = YES;
      }
    } else {
      NSString *tmp = SKFSFindFolder(kTemporaryFolderType, kLocalDomain);
      NSMutableArray *cmpt = [[NSMutableArray alloc] init];
      NSFileManager *manager = [NSFileManager defaultManager];
      while ([path length] && ![manager fileExistsAtPath:path isDirectory:NULL]) {
        [cmpt addObject:[path lastPathComponent]];
        path = [path stringByDeletingLastPathComponent];
      }
      if (![path length]) {
        NSRunAlertPanel(@"The plugin was not installed", @"Unknown error while looking for plugin path", @"OK", nil, nil);
      } else {
        NSString *root = nil;
        unsigned count = [cmpt count];
        while (count-- > 0) {
          tmp = [tmp stringByAppendingPathComponent:[cmpt objectAtIndex:count]];
          if (!root)
            root = tmp;
          [manager createDirectoryAtPath:tmp attributes:nil];
        }
        [cmpt release];
        
        if (![self installPlugin:plugin into:tmp copy:YES]) {
          NSRunAlertPanel(@"The plugin was not installed", @"An error prevent plugin installation.", @"OK", nil, nil);
        } else {
          // tell finder to move root into path
          OSStatus err = [self moveFile:root to:path copy:NO];
          if (noErr != err && userCanceledErr != err) {
            NSRunAlertPanel(@"The plugin was not installed", @"An error prevent plugin installation.", @"OK", nil, nil);
          } else {
            installed = YES;
          }
        }
      }
    }
  }
  if (installed) {
    return [location stringByAppendingPathComponent:[plugin lastPathComponent]];
  }
  return nil;
}

@end