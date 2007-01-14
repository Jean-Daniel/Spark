/*
 *  SELibraryDocument.m
 *  Spark Editor
 *
 *  Created by Grayfox on 14/01/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import "SELibraryDocument.h"
#import "SELibraryWindow.h"
#import "SEEntriesManager.h"

@implementation SELibraryDocument

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc {
  [se_library release];
  [se_manager release];
  [super dealloc];
}

- (void)makeWindowControllers {
  NSWindowController *ctrl = [[SELibraryWindow alloc] init];
  [self addWindowController:ctrl];
  [ctrl release];
}

- (SparkLibrary *)library {
  return se_library;
}
- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (se_library)
    [NSException raise:NSInternalInconsistencyException format:@"Library cannot be changed"];
  
  se_library = [aLibrary retain];
  se_manager = [[SEEntriesManager alloc] initWithLibrary:se_library];
  
  if ([se_library path])
    [self setFileName:@"Spark"];
}

- (SEEntriesManager *)manager {
  return se_manager;
}

@end
