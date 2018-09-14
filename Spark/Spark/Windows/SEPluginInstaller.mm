/*
 *  SEPlugInInstaller.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEPlugInInstaller.h"

#import "Spark.h"

#import <WonderBox/WonderBox.h>

#import <SparkKit/SparkActionLoader.h>

@interface SEPlugInInstaller ()
- (NSURL *)installPlugIn:(NSURL *)plugin domain:(WBPlugInDomain)skdomain;
@end

@implementation SEPlugInInstaller {
  NSURL *se_plugin;
}

- (id)init {
  if (self = [super init]) {
    
  }
  return self;
}

#pragma mark -
- (IBAction)update:(id)sender {
  [ibInfo setHidden:[ibMatrix selectedRow] == 0];
}

- (IBAction)install:(id)sender {
  WBPlugInDomain domain;
  if ([ibMatrix selectedRow] == 0) {
    // User
    domain = kWBPlugInDomainUser;
  } else {
    // Local
    domain = kWBPlugInDomainLocal;
  }
  NSURL *url = [self installPlugIn:se_plugin domain:domain];
  if (url) {
    [self close:sender];
    [[SparkActionLoader sharedLoader] loadPlugInAtURL:url];
    [[NSWorkspace sharedWorkspace] openFile:[[url URLByDeletingLastPathComponent] path]];
  } else {
    SPXDebug(@"PlugIn installation failed");
  }
}

static inline
void _Setup(SEPlugInInstaller *self) {
  /* Load nib if needed */
  [self window];
  /* Get plugin bundle ID */
  /* If plugin already installed => ? */
  NSString *name = [[NSFileManager defaultManager] displayNameAtPath:[self->se_plugin path]];
  NSString *explain = [NSString stringWithFormat:@"The plugin '%@' must be install before you can use it. Do you want to install it now?", name];
  [self->ibExplain setStringValue:explain];
}

- (void)setPlugIn:(NSString *)path {
  se_plugin = [NSURL fileURLWithPath:path];
  _Setup(self);
}

- (OSStatus)moveFile:(NSURL *)file to:(NSURL *)destination copy:(BOOL)flag {
  wb::AEDesc desc;
  wb::AppleEvent aevt;
  OSStatus err = WBAECreateEventWithTargetBundleID(kWBAEFinderBundleIdentifier, kAECoreSuite, flag ? kAECopy : kAEMove, &aevt);
  if (noErr == err)
    err = WBAEAddFileURL(&aevt, keyDirectObject, SPXNSToCFURL(file));
  if (noErr == err)
    err = WBAEAddFileURL(&aevt, keyAEInsertHere, SPXNSToCFURL(destination));
  if (noErr == err) {
    err = WBAESendEventReturnAEDesc(&aevt, typeWildCard, &desc);
    
    if (noErr == err && typeNull == desc.descriptorType)
      err = userCanceledErr;
  }
  return err;
}

- (BOOL)installPlugIn:(NSURL *)plugin into:(NSURL *)dest copy:(BOOL)flag {
  dest = [dest URLByAppendingPathComponent:plugin.lastPathComponent];
  if (flag)
    return [[NSFileManager defaultManager] copyItemAtURL:plugin toURL:dest error:NULL];
  return [[NSFileManager defaultManager] moveItemAtURL:plugin toURL:dest error:NULL];
}

- (NSURL *)installPlugIn:(NSURL *)plugin domain:(WBPlugInDomain)skdomain {
  /* FIXME: remove temp file */
  if (![plugin checkResourceIsReachableAndReturnError:NULL]) {
    [[NSAlert alertWithMessageText:@"The plugin was not installed"
         informativeTextWithFormat:@"Cannot find plugin at path ”%@”", plugin] runModal];
    return nil;
  }
  
  
  NSURL *url = [[SparkActionLoader sharedLoader] URLForDomain:skdomain];
  if (!url) {
    [[NSAlert alertWithMessageText:@"The plugin was not installed"
                   informativeText:@"Spark cannot find plugin folder"] runModal];
    return nil;
  }
  
  BOOL installed = NO;
  NSURL *location = url;
  if ([[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL]) {
    /* First try to copy the file using workspace operation */
    if (![self installPlugIn:plugin into:url copy:YES]) {
      /* If failed, ask the finder to move the file (it will take care of the authentification for us) */
      OSStatus err = [self moveFile:plugin to:url copy:YES];
      if (noErr != err && userCanceledErr != err) {
        [[NSAlert alertWithMessageText:@"The plugin was not installed"
                       informativeText:@"An error prevent plugin installation"] runModal];
      } else {
        installed = YES;
      }
    } else {
      installed = YES;
    }
  } else {
    // Try to workaround lack of permission by asking the finder to install the plugin for us
    NSMutableArray *cmpt = [[NSMutableArray alloc] init];
    NSFileManager *manager = [NSFileManager defaultManager];
    while ([url.path length] > 1 && ![url checkResourceIsReachableAndReturnError:NULL]) {
      [cmpt addObject:[url lastPathComponent]];
      url = [url URLByDeletingLastPathComponent];
    }
    if ([url.path length] <= 1) {
      [[NSAlert alertWithMessageText:@"The plugin was not installed"
                     informativeText:@"Unknown error while looking for plugin path"] runModal];
    } else {
      NSURL *root = nil;
      NSInteger count = [cmpt count];
      NSURL *tmp = [NSFileManager.defaultManager temporaryDirectory];
      while (count-- > 0) {
        tmp = [tmp URLByAppendingPathComponent:cmpt[count]];
        if (!root)
          root = tmp;
        [manager createDirectoryAtURL:tmp withIntermediateDirectories:NO attributes:nil error:NULL];
      }
      
      if (![self installPlugIn:plugin into:tmp copy:YES]) {
        [[NSAlert alertWithMessageText:@"The plugin was not installed"
                       informativeText:@"An error prevent plugin installation"] runModal];
      } else {
        // tell finder to move root into path
        OSStatus err = [self moveFile:root to:url copy:NO];
        if (noErr != err && userCanceledErr != err) {
          [[NSAlert alertWithMessageText:@"The plugin was not installed"
                         informativeText:@"An error prevent plugin installation"] runModal];
        } else {
          installed = YES;
        }
      }
    }
  }
  if (installed)
    return [location URLByAppendingPathComponent:plugin.lastPathComponent];
  return nil;
}

@end
