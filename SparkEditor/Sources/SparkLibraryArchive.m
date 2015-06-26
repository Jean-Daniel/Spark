/*
 *  SparkLibraryArchive.m
 *  SparkKit
 *
 *  Created by Grayfox on 24/02/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import "SparkLibraryArchive.h"

#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkPrivate.h>

#import <SparkKit/SparkIconManagerPrivate.h>

#import <SArchiveKit/SArchive.h>
#import <SArchiveKit/SArchiveFile.h>
#import <SArchiveKit/SArchiveDocument.h>

@interface SparkIconManager (SparkArchiveExtension)

- (void)readFromArchive:(SArchive *)archive path:(SArchiveFile *)path;
- (void)writeToArchive:(SArchive *)archive atPath:(SArchiveFile *)path;

@end

const OSType kSparkLibraryArchiveHFSType = 'SliX';
NSString * const kSparkLibraryArchiveExtension = @"splx";

static 
NSString * const kSparkLibraryArchiveFileName = @"Spark Library";

@implementation SparkLibrary (SparkArchiveExtension)

- (instancetype)initFromArchiveAtURL:(NSURL *)url {
  return [self initFromArchiveAtURL:url loadPreferences:YES];
}

- (instancetype)initFromArchiveAtURL:(NSURL *)url loadPreferences:(BOOL)flag {
  if (self = [self initWithURL:nil]) {
    SArchive *archive = [[SArchive alloc] initWithURL:url];
    
    SArchiveFile *library = [archive fileWithName:kSparkLibraryArchiveFileName];
    if (library) {
      NSFileWrapper *wrapper = [library fileWrapper];
      if (wrapper) {
        /* Init in memory icon manager */
        _icons = [[SparkIconManager alloc] initWithLibrary:self URL:nil];
        /* Load library */
        [self readFromFileWrapper:wrapper error:nil];
        /* Load icons */
        SArchiveFile *icons = [archive fileWithName:@"Icons"];
        NSAssert(icons != nil, @"Invalid archive");
        [_icons readFromArchive:archive path:icons];
      }
    }
    [archive close];
  }
  return self;
}

- (BOOL)archiveToURL:(NSURL *)url {
  NSFileWrapper *wrapper = [self fileWrapper:nil];
  if (wrapper) {
    SArchive *archive = [[SArchive alloc] initWithURL:url writable:YES];
    SArchiveDocument *doc = [archive addDocumentWithName:@"SparkLibrary"];

    CFDateFormatterRef df = CFDateFormatterCreate(kCFAllocatorDefault, CFLocaleGetSystem(), kCFDateFormatterNoStyle, kCFDateFormatterNoStyle);
    CFDateFormatterSetFormat(df, CFSTR("yyyy-MM-dd HH:mm:ss zzz"));
    CFStringRef dates = CFDateFormatterCreateStringWithAbsoluteTime(kCFAllocatorDefault, df, CFAbsoluteTimeGetCurrent());
    if (dates) {
      [doc setValue:SPXCFToNSString(dates) forProperty:@"archive/date"];
      CFRelease(dates);
    }
    CFRelease(df);
    [doc setValue:[NSString stringWithFormat:@"%u", 1] forAttribute:@"format" property:@"archive"];
    
    /* library version */
    CFStringRef str = CFUUIDCreateString(kCFAllocatorDefault, [self uuid]);
    if (str) {
      [doc setValue:SPXCFToNSString(str) forProperty:@"library/uuid"];
      CFRelease(str);
    }
    [doc setValue:[NSString stringWithFormat:@"%lu", (unsigned long)kSparkLibraryCurrentVersion] forAttribute:@"version" property:@"library"];
    
    [wrapper setFilename:kSparkLibraryArchiveFileName];
    [archive addFileWrapper:wrapper parent:nil];
    
    /* Save icons */
    if (self.iconManager) {
      SArchiveFile *icons = [archive addFolderWithName:@"Icons" properties:nil parent:nil];
      [self.iconManager writeToArchive:archive atPath:icons];
    }
    
    [archive close];
    return YES;
  }
  return NO;
}

@end

#pragma mark -
@implementation SparkIconManager (SparkArchiveExtension)

- (void)readFromArchive:(SArchive *)archive path:(SArchiveFile *)path {
  @autoreleasepool {
    for (NSUInteger idx = 0; idx < 4; idx++) {
      /* Get Folder */
      SArchiveFile *folder = [path fileWithName:[NSString stringWithFormat:@"%lu", (unsigned long)idx]];

      for (SArchiveFile *file in [folder files]) {
        NSData *data = [file extractContents];
        NSImage *icon = data ? [[NSImage alloc] initWithData:data] : nil;
        if (icon) {
          _SparkIconEntry *entry = [self entryForObjectType:(uint8_t)idx uid:[[file name] intValue]];
          if (entry)
            [entry setIcon:icon];
        }
      }
    }
  }
}

- (void)writeToArchive:(SArchive *)archive atPath:(SArchiveFile *)path {
  @autoreleasepool {
    for (NSUInteger idx = 0; idx < 4; idx++) {
      /* Create Folder */
      SArchiveFile *folder = [archive addFolderWithName:[NSString stringWithFormat:@"%lu", (unsigned long)idx] properties:nil parent:path];

      NSMutableSet *blacklist = [[NSMutableSet alloc] init];
      [blacklist addObject:@".DS_Store"];
      /* Then, write in memory entries */
      [self enumerateEntries:(uint8_t)idx usingBlock:^(SparkUID uid, _SparkIconEntry *entry, BOOL *stop) {
        /* If should save in memory entry */
        if ([entry hasChanged] || !self.URL) {
          NSString *strid = [NSString stringWithFormat:@"%u", uid];
          [blacklist addObject:strid];
          if ([entry icon]) {
            NSData *data = [[entry icon] TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1];
            if (data) {
              [archive addFileWithName:strid content:data parent:folder];
            }
          }
        }
      }];
      /* Finaly, archive on disk icons */
      if (self.URL) {
        NSURL *fspath = [self.URL URLByAppendingPathComponent:[folder name]];
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[fspath path] error:NULL];
        for (NSString *fsicon in files) {
          if (![blacklist containsObject:fsicon]) {
            NSURL *fullpath = [fspath URLByAppendingPathComponent:fsicon];
            [archive addFileAtURL:fullpath name:fsicon parent:folder];
          }
        }
      }
    }
  }
}

@end
