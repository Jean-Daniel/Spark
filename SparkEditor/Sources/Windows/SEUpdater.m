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
#import <ShadowKit/SKThreadPort.h>
#import <ShadowKit/SKExtensions.h>
#import <ShadowKit/SKAEFunctions.h>
#import <ShadowKit/SKFSFunctions.h>
#import <ShadowKit/SKProgressPanel.h>
#import <ShadowKit/SKUpdaterVersion.h>
#import <ShadowKit/SKCryptoFunctions.h>

SKSingleton(SEUpdater, sharedUpdater);

@interface SEArchiveExtractor : NSObject {
  @private
  id se_delegate;
  SEL se_selector;
  void *se_context;
    
  NSString *se_path;
  SKThreadPort *se_port;
  SKUpdaterArchive *se_archive;
  SKProgressPanel *se_progress;
}

- (id)initWithArchive:(SKUpdaterArchive *)archive path:(NSString *)path;

- (BOOL)verify;

- (NSString *)path;

- (void)extractToPath:(NSString *)destination modalDelegate:(id)delegate
       didEndSelector:(SEL)callback contextInfo:(void *)ctxt;

@end

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
      if (NSOKButton == [dialog runModal:YES]) {
        [updater downloadArchive:[last archiveForVersion:SKVersionGetCurrentNumber()]];
      } else {
        [se_updater release];
        se_updater = nil;
      }
    } else {
      /* if we are in manual mode */
      if (se_search)
        NSRunAlertPanel(@"Spark is up to date", @"you are using the last Spark version", @"OK", nil, nil);
      [se_updater release];
      se_updater = nil;
    }
  }
}

/* Update downloaded */
- (void)updater:(SKUpdater *)updater didDownloadArchive:(SKUpdaterArchive *)archive atPath:(NSString *)path {
  [se_progress stop];
  [se_progress close:nil];
  [se_progress release];
  se_progress = nil;
  
  SEArchiveExtractor *extractor = [[SEArchiveExtractor alloc] initWithArchive:archive path:path];
  if ([extractor verify]) {
    FSRef bref;
    NSString *bpath = [[NSBundle mainBundle] bundlePath];
    NSString *base = [@"~/Desktop/" stringByStandardizingPath];
    if ([bpath getFSRef:&bref]) {
      FSVolumeRefNum volume;
      OSStatus err = SKFSGetVolumeInfo(&bref, &volume, kFSVolInfoNone, NULL, NULL, NULL);
      if (noErr == err)
        base = SKFSFindFolder(kTemporaryFolderType, volume, true);
    }
    
    [extractor extractToPath:base modalDelegate:self didEndSelector:@selector(didEndExtracting:result:context:) contextInfo:nil];
  }
  
  /* no longer need updater */
  [se_updater release];
  se_updater = nil;
}

- (void)updater:(SKUpdater *)updater didCancelOperation:(SKUpdaterStatus)status {
  ShadowTrace();
  [se_progress close:nil];
  [se_progress release];
  se_progress = nil;
  [se_updater release];
  se_updater = nil;
}

/* Required: Network unreachable or download failed */
- (void)updater:(SKUpdater *)updater errorOccured:(NSError *)anError duringOperation:(SKUpdaterStatus)theStatus {
  if (anError)
    [NSApp presentError:anError];
  
  [se_progress close];
  [se_progress release];
  se_progress = nil;
  
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
  [se_progress setTitle:name];
  
  if (NSURLResponseUnknownLength == length) {
    [se_progress setIndeterminate:YES];
  } else {
    [se_progress setIndeterminate:NO];
    [se_progress setMaxValue:length];
    
    [se_size release];
    se_size = [[NSString localizedStringWithSize:length unit:@"B" precision:2] retain];
  }
  [se_progress start];
}

- (void)updater:(SKUpdater *)updater downloadProgress:(SInt64)progress {
  [se_progress setValue:progress];
}

#pragma mark Human Interface
- (IBAction)cancel:(id)sender {
  [se_updater cancel:nil];
}

- (void)showProgressPanel {
  if (!se_progress) {
    se_progress = [[SKProgressPanel alloc] init];
    [se_progress setDelegate:self];
    [se_progress setRefreshInterval:0.1];
    [se_progress setEvaluatesRemainingTime:YES];
  }
  [se_progress showWindow:nil];
}

- (NSString *)progressPanel:(SKProgressPanel *)aPanel messageForValue:(double)value {
  NSString *size = [NSString localizedStringWithSize:value unit:@"B" precision:2];
  return [NSString stringWithFormat:@"%@ / %@", size, se_size];
}

- (void)didEndExtracting:(SEArchiveExtractor *)extractor result:(NSInteger)result context:(void *)ctxt {
  FSRef fref;
  if (noErr == FSPathMakeRef((const UInt8 *)[[extractor path] UTF8String], &fref, NULL))
    FSDeleteObject(&fref);
  
  [extractor autorelease];
}

@end

#pragma mark -
@implementation SEArchiveExtractor

- (id)initWithArchive:(SKUpdaterArchive *)archive path:(NSString *)path {
  if (self = [super init]) {
    se_path = [path copy];
    se_archive = [archive retain];
    se_port = [[SKThreadPort alloc] init];
  }
  return self;
}

- (void)dealloc {
  [se_port release];
  [se_path release];
  [se_archive release];
  [se_progress release];
  [super dealloc];
}

#pragma mark -
- (BOOL)verify {
  /* Check digest */
  if ([se_archive digest] && [se_archive digestAlgorithm]) {
    bool valid = false;
    SKCryptoProvider csp;
    SKCryptoData digest = {0, NULL};
    SKCryptoResult res = SKCryptoCspAttach(&csp);
    if (CSSM_OK == res) {
      res = SKCryptoDigestFile(csp, [se_archive digestAlgorithm], [se_path fileSystemRepresentation], &digest);
      if (CSSM_OK == res && digest.Length == [[se_archive digest] length])
        valid = (0 == memcmp(digest.Data, [[se_archive digest] bytes], digest.Length));
      if (digest.Data)
        SKCDSAFree(csp, digest.Data);
      SKCryptoCspDetach(csp);
    }
    return valid;
  }
  return YES;
}

- (NSString *)path {
  return se_path;
}

- (void)extract:(NSString *)destination {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  SKArchive *arch = [[SKArchive alloc] initWithArchiveAtPath:se_path];
  
  [[se_port prepareWithInvocationTarget:se_progress] setMaxValue:[arch size]];
  
  //DLog(@"Extracting %@", [NSString localizedStringWithSize:[arch size] unit:@"B" precision:2]);
  
  [[se_port prepareWithInvocationTarget:se_progress] start];
  NSInteger result = [arch extractToPath:destination handler:self] ? 1 : 0;
  [(SKProgressPanel *)[se_port prepareWithInvocationTarget:se_progress] stop];
  
  /* Force Finder to refesh items */
  NSArray *roots = [arch files];
  for (NSUInteger idx = 0; idx < [roots count]; idx++) {
    FSRef ref;
    NSString *fpath = [destination stringByAppendingPathComponent:[[roots objectAtIndex:idx] name]];
    if ([fpath getFSRef:&ref]) {
      SKAEFinderSyncFSRef(&ref);
      SKAEFinderRevealFSRef(&ref, false);
    }
  }
  [arch release];
  
  NSInvocation *invoc = [NSInvocation invocationWithTarget:se_delegate selector:se_selector];
  [invoc setArgument:&self atIndex:2];
  [invoc setArgument:&result atIndex:3];
  [invoc setArgument:&se_context atIndex:4];
  [se_port performInvocation:invoc waitUntilDone:NO timeout:MACH_MSG_TIMEOUT_NONE];
  
  /* cleanup */
  se_selector = NULL;
  se_delegate = nil;
  se_context = NULL;
  [pool release];
}

- (void)showProgressPanel {
  if (!se_progress) {
    se_progress = [[SKProgressPanel alloc] init];
    [se_progress setDelegate:self];
    [se_progress setRefreshInterval:0.1];
    [se_progress setEvaluatesRemainingTime:YES];
  }
  [se_progress showWindow:nil];
}

- (void)extractToPath:(NSString *)destination modalDelegate:(id)delegate didEndSelector:(SEL)callback contextInfo:(void *)ctxt {
  se_context = ctxt;
  se_delegate = delegate;
  se_selector = callback;
  [self showProgressPanel];
  [NSThread detachNewThreadSelector:@selector(extract:) toTarget:self withObject:destination];
}

- (NSString *)progressPanel:(SKProgressPanel *)aPanel messageForValue:(double)value {
  NSString *size = [NSString localizedStringWithSize:value unit:@"B" precision:2];
  return [NSString stringWithFormat:@"%@", size];
}

#pragma mark Archive
//- (void)archive:(SKArchive *)manager willProcessFile:(SKArchiveFile *)file {
//  DLog(@"extract %@", [file name]);
//}

- (void)archive:(SKArchive *)manager didProcessFile:(SKArchiveFile *)file path:(NSString *)fsPath {
  UInt64 size = [file size];
  if (size > 0)
    [[se_port prepareWithInvocationTarget:se_progress] incrementBy:size];
}

- (BOOL)archive:(SKArchive *)manager shouldProceedAfterError:(NSError *)anError {
  DLog(@"%@", anError);
  return YES;
}

@end


