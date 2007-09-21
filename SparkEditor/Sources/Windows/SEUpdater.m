//
//  SEUpdater.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 18/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SEUpdater.h"
#import "SEUpdaterVersion.h"

#import <ShadowKit/SKArchive.h>
#import <ShadowKit/SKArchiveFile.h>

#import <ShadowKit/SKUpdater.h>
#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKUpdaterVersion.h>
#import <ShadowKit/SKCryptoFunctions.h>

SKSingleton(SEUpdater, sharedUpdater);

@implementation SEUpdater

- (id)init {
  if (self = [super init]) {
    
  }
  return self;
}

- (void)dealloc {
  [se_size release];
  [se_updater cancel:nil];
  [super dealloc];
}

- (void)runInBackground {
  if (!se_updater) {
    se_search = false;
    se_updater = [[SKUpdater alloc] initWithDelegate:self];
    [se_updater searchVersions:[NSURL URLWithString:NSLocalizedStringFromTable(@"UPDATE_FILE_URL", @"SEUpdater", 
                                                                               @"URL of the update file (.xml or .plist).")] waitNetwork:YES];
  }
}

- (void)search {
  if (se_updater && [se_updater status] == kSKUpdaterWaitNetwork) {
    [se_updater cancel:nil];
  }
  /* set manual flags */
  se_search = true;
  se_updater = [[SKUpdater alloc] initWithDelegate:self];
  if (![se_updater searchVersions:[NSURL URLWithString:NSLocalizedStringFromTable(@"UPDATE_FILE_URL", @"SEUpdater", 
                                                                                  @"URL of the update file (.xml or .plist).")] waitNetwork:NO]) {
    NSRunAlertPanel(@"Network unreachable", @"connect and retry", @"OK", nil, nil);
  }
}

#pragma mark Delegate
/* Required: Properties found */
- (void)updater:(SKUpdater *)updater didSearchVersions:(NSArray *)versions {
  SKUpdaterVersion *last = [versions lastObject];
  if (last) {
    if ([last version] > SKVersionGetCurrentNumber()) {
      se_version = [last version];
      SEUpdaterVersion *dialog = [[SEUpdaterVersion alloc] init];
      [dialog setVersions:versions];
      if (NSOKButton == [dialog runModal]) {
        [updater downloadArchive:[last archiveForVersion:SKVersionGetCurrentNumber()]];
      } else {
        [se_updater release];
        se_updater = nil;
      }
    } else {
      /* if we are in manual mode */
      if (se_search)
        NSRunAlertPanel(@"Spark is up to date", @"you are using the last Sark version", @"OK", nil, nil);
      [se_updater release];
      se_updater = nil;
    }
  }
}

/* Update downloaded */
- (void)updater:(SKUpdater *)updater didDownloadArchive:(SKUpdaterArchive *)archive atPath:(NSString *)path {
  [ibProgressWindow close];
  /* Check digest */
  if ([archive digest] && [archive digestAlgorithm]) {
    bool valid = false;
    SKCryptoProvider csp;
    SKCryptoData digest = {0, NULL};
    SKCryptoResult res = SKCryptoCspAttach(&csp);
    if (CSSM_OK == res) {
      res = SKCryptoDigestFile(csp, [archive digestAlgorithm], [path fileSystemRepresentation], &digest);
      if (CSSM_OK == res && digest.Length == [[archive digest] length])
        valid = (0 == memcmp(digest.Data, [[archive digest] bytes], digest.Length));
      if (digest.Data)
        SKCDSAFree(csp, digest.Data);
      SKCryptoCspDetach(csp);
    }
    if (!valid)
      WLog(@"checksum verification failed");
  }
  
  SKArchive *arch = [[SKArchive alloc] initWithArchiveAtPath:path];
  SKArchiveFile *root = [[arch files] objectAtIndex:0];
  
  SKArchiveFile *file;
  NSEnumerator *files = [root deepChildEnumerator];
  while (file = [files nextObject]) {
    DLog(@"%@", [file path]);
  }
  [arch release];
  
  FSRef fref;
  if (noErr == FSPathMakeRef((const UInt8 *)[path UTF8String], &fref, NULL))
    FSDeleteObject(&fref);
  
  /* no longer need updater */
  [se_updater release];
  se_updater = nil;
}

- (void)updater:(SKUpdater *)updater didCancelOperation:(SKUpdaterStatus)status {
  ShadowTrace();
  [ibProgressWindow close];
  [se_updater release];
  se_updater = nil;
}

/* Required: Network unreachable or download failed */
- (void)updater:(SKUpdater *)updater errorOccured:(NSError *)anError duringOperation:(SKUpdaterStatus)theStatus {
  if (anError)
    [NSApp presentError:anError];
  
  [ibProgressWindow close];
  [se_updater release];
  se_updater = nil;
}

/* Update download */
- (void)updater:(SKUpdater *)updater didStartDownloadArchive:(SKUpdaterArchive *)archive length:(SInt64)length {
  [self showProgressPanel];
  /* Set panel name */
  CFStringRef vers = SKVersionCreateStringForNumber(se_version);
  NSString *name = [NSString stringWithFormat:@"Downloading %@ v%@", 
    [[NSProcessInfo processInfo] processName], vers];
  if (vers) CFRelease(vers);
  [ibName setStringValue:name];
  
  if (NSURLResponseUnknownLength == length) {
    [ibProgress setIndeterminate:YES];
  } else {
    [ibProgress setIndeterminate:NO];
    [ibProgress setMaxValue:length];
    
    [se_size release];
    se_size = [[NSString localizedStringWithSize:length unit:@"B" precision:2] retain];
  }
}

- (void)updater:(SKUpdater *)updater downloadProgress:(SInt64)progress {
  [ibProgress setDoubleValue:progress];
  CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
  /* limit string refresh rate: 100 ms */
  if (now >= se_refresh + 0.1) {
    se_refresh = now;
    NSString *size = [NSString localizedStringWithSize:progress unit:@"B" precision:2];
    
    NSString *str = [NSString stringWithFormat:@"%@ / %@", size, se_size];
    [ibProgressText setStringValue:str];
  }
}

#pragma mark Human Interface
- (IBAction)cancel:(id)sender {
  [se_updater cancel:nil];
}

- (void)showProgressPanel {
  NSNib *nib = [[NSNib alloc] initWithNibNamed:@"SEUpdater" bundle:[NSBundle mainBundle]];
  [nib instantiateNibWithOwner:self topLevelObjects:nil];
  [nib release];
  [ibProgressWindow makeKeyAndOrderFront:nil];
}

@end


