//
//  SparkLibraryPrivate.m
//  SparkKit
//
//  Created by Grayfox on 01/12/07.
//  Copyright 2007 Shadow Lab. All rights reserved.
//

#import "SparkLibraryPrivate.h"

#import <SparkKit/SparkObjectSet.h>
#import <SparkKit/SparkApplication.h>

@implementation SparkLibrary (SparkLibraryApplication)

- (SparkApplication *)applicationWithBundleIdentifier:(NSString *)bundleID {
  __block SparkApplication *result = nil;
  if (bundleID) {
    [self.applicationSet enumerateObjectsUsingBlock:^(SparkApplication *sa, BOOL *stop) {
      if ([sa.bundleIdentifier isEqualToString:bundleID]) {
        result = sa;
        *stop = YES;
      }
    }];
  }
  return result;
}

- (SparkApplication *)applicationWithProcessIdentifier:(pid_t)pid {
  NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
  if (app)
    return [self applicationWithBundleIdentifier:app.bundleIdentifier];

  return nil;
}

- (SparkApplication *)frontmostApplication {
  NSRunningApplication *app = [[NSWorkspace sharedWorkspace] frontmostApplication];
  if (app)
    return [self applicationWithBundleIdentifier:app.bundleIdentifier];

  return nil;
}

@end

#pragma mark Archiver
@implementation SparkLibraryArchiver

@end

@implementation SparkLibraryUnarchiver

- (id)initForReadingWithData:(NSData *)data library:(SparkLibrary *)aLibrary {
  if (self = [super initForReadingWithData:data]) {
    _library = aLibrary;
  }
  return self;
}

@end
