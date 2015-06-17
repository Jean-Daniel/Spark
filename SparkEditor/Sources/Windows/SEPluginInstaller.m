/*
 *  SEPlugInInstaller.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEPlugInInstaller.h"

#import "Spark.h"

#import <WonderBox/WBFSFunctions.h>

#import <WonderBox/WBAEFunctions.h>
#import <WonderBox/WBFinderSuite.h>

#import <SparkKit/SparkActionLoader.h>

@interface SEPlugInInstaller ()
- (NSURL *)installPlugIn:(NSURL *)plugin domain:(WBPlugInDomain)skdomain;
@end

@implementation SEPlugInInstaller

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
  se_plugin = [[NSURL fileURLWithPath:path] retain];
  _Setup(self);
}

- (OSStatus)moveFile:(NSString *)file to:(NSString *)destination copy:(BOOL)flag {
  AppleEvent aevt = WBAEEmptyDesc();
  AEDesc desc = WBAEEmptyDesc();
  OSStatus err = fnfErr;
  
  FSRef src, dest;
  if ([file getFSRef:&src] && [destination getFSRef:&dest]) {
    OSType finder = WBAEFinderSignature;
    err = AEBuildAppleEvent(kAECoreSuite, flag ? kAECopy : kAEMove, 
                            typeApplSignature, &finder, sizeof(OSType),
                            kAutoGenerateReturnID, kAnyTransactionID,
                            &aevt, NULL,    /* can be NULL */
                            "'----':fsrf(@), 'insh':fsrf(@)", sizeof(src), &src, sizeof(dest), &dest);
    require_noerr(err, dispose);
    
//    err = WBAESetStandardAttributes(&aevt);
//    require_noerr(err, dispose);
  
    err = WBAESendEventReturnAEDesc(&aevt, typeWildCard, &desc);
    require_noerr(err, dispose);
    
    if (typeNull == desc.descriptorType)
      err = userCanceledErr;
  }
  
dispose:
    WBAEDisposeDesc(&aevt);
  WBAEDisposeDesc(&desc);
  
  return err;
}

- (BOOL)installPlugIn:(NSString *)plugin into:(NSString *)dest copy:(BOOL)flag {
  NSString *src = [plugin stringByDeletingLastPathComponent];
  NSArray *files = [NSArray arrayWithObject:[plugin lastPathComponent]];
  return [[NSWorkspace sharedWorkspace] performFileOperation:(flag ? NSWorkspaceCopyOperation : NSWorkspaceMoveOperation) source:src destination:dest files:files tag:NULL];
}

- (NSURL *)installPlugIn:(NSString *)plugin domain:(WBPlugInDomain)skdomain {
	/* FIXME: remove temp file */
  if (![[NSFileManager defaultManager] fileExistsAtPath:plugin]) {
    NSRunAlertPanel(@"The plugin was not installed", @"Cannot find plugin at path \"%@\"", @"OK", nil, nil, plugin);
    return nil;
  }
  
  BOOL installed = NO;
  NSString *location = nil;
  NSString *path = [[SparkActionLoader sharedLoader] pathForDomain:skdomain];
  if (!path) {
    NSRunAlertPanel(@"The plugin was not installed", @"Spark cannot find plugin folder", @"OK", nil, nil);
  } else {
    location = path;
    if ([[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL]) {
      /* First try to copy the file using workspace operation */
      if (![self installPlugIn:plugin into:path copy:YES]) {
        /* If failed, ask the finder to move the file (it will take care of the authentification for us) */
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
      NSString *tmp = [WBFSFindFolder(kTemporaryFolderType, kLocalDomain, true) path];
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
        NSUInteger count = [cmpt count];
        while (count-- > 0) {
          tmp = [tmp stringByAppendingPathComponent:[cmpt objectAtIndex:count]];
          if (!root)
            root = tmp;
          [manager createDirectoryAtPath:tmp withIntermediateDirectories:NO attributes:nil error:NULL];
        }
        
        if (![self installPlugIn:plugin into:tmp copy:YES]) {
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
      [cmpt release];
    }
  }
  if (installed) {
    return [NSURL fileURLWithPath:[location stringByAppendingPathComponent:[plugin lastPathComponent]]];
  }
  return nil;
}

@end
