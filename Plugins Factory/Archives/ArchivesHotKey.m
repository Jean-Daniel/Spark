//
//  ZipHotKey.m
//  Spark
//
//  Created by Fox on Tue Feb 17 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
#include <unistd.h>

#import "ArchivesHotKey.h"

#define BOM_HELPER		"/System/Library/CoreServices/BOMArchiveHelper.app/Contents/MacOS/BOMArchiveHelper"
#define FORMAT			-archive-format
#define SOURCE			-source-path
#define TARGET			-target-path

NSString *const kArchiveZipFormat = @"zip";
NSString *const kArchiveCpioFormat = @"cpio";
NSString *const kArchiveCpgzFormat = @"cpgz";

NSString *const kArchiveTarFormat = @"tar";
NSString *const kArchiveGzFormat = @"gz";
NSString *const kArchiveBz2Format = @"bz2";

@implementation ArchivesHotKey

- (SparkAlert *)execute {
  id files = ShadowAEGetFinderSelection();
  switch ([files count]) {
    case 0:
      NSBeep();
      break;
    case 1:
      [NSThread detachNewThreadSelector:@selector(compressFile:) toTarget:self withObject:[files objectAtIndex:0]];
      break;
    default:
      [self compressFiles:files];
  }
  return nil;
}

- (void)compressFile:(NSString *)file {
  char *toolPath = nil;
  switch (format) {
    case kZipFormat:
    case kCpioFormat:
      toolPath = BOM_HELPER;
      break;
  }
  if (toolPath) {
    int childPID = vfork();
    if (childPID == 0) {						// Child    
      execl(toolPath, toolPath, nil);
      NSLog(@"Error while execl");
      _exit(0);
    }
  }
  else {
    NSLog(@"Erreur");
  }
}

- (void)compressFiles:(NSArray *)files {
 // [NSThread detachNewThreadSelector:@selector(compressFile:) toTarget:self withObject:[files objectAtIndex:0]];
}

@end
