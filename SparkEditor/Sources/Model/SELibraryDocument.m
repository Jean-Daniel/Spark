/*
 *  SELibraryDocument.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SELibraryDocument.h"
#import "SELibraryWindow.h"
#import "SEEntryEditor.h"
#import "SEEntryCache.h"


#import <SparkKit/SparkLibrary.h>

NSString * const SEApplicationDidChangeNotification = @"SEApplicationDidChange";

@implementation SELibraryDocument

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc {
  [se_cache release];
  [se_editor release];
  [se_library release];
  [se_application release];
  [super dealloc];
}

- (void)makeWindowControllers {
  NSWindowController *ctrl = [[SELibraryWindow alloc] init];
  [self addWindowController:ctrl];
  [ctrl release];
  [self displayFirstRunIfNeeded];
}

- (SparkLibrary *)library {
  return se_library;
}
- (void)setLibrary:(SparkLibrary *)aLibrary {
  if (se_library)
    [NSException raise:NSInternalInconsistencyException format:@"Library cannot be changed"];
  
  se_library = [aLibrary retain];
  if (se_library) {
    [se_library setUndoManager:[self undoManager]];
    if ([se_library path])
      [self setFileName:@"Spark"];
    
    if (se_cache) [se_cache release];
    se_cache = [[SEEntryCache alloc] initWithDocument:self];
  }
}

- (SEEntryCache *)cache {
  return se_cache;
}

- (SparkApplication *)application {
  return se_application;
}
- (void)setApplication:(SparkApplication *)anApplication {
  if (se_application != anApplication) {
    [se_application release];
    se_application = [anApplication retain];
    /* Refresh cache */
    [se_cache refresh];
    /* Notify change */
    [[NSNotificationCenter defaultCenter] postNotificationName:SEApplicationDidChangeNotification
                                                        object:self];
  }
}

- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo {
  if (se_library == SparkActiveLibrary()) {
    [se_library synchronize];
    [self updateChangeCount:NSChangeCleared];
  } 
  [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

#pragma mark Editor
- (SEEntryEditor *)editor {
  if (!se_editor) {
    se_editor = [[SEEntryEditor alloc] init];
    /* Load */
    [se_editor window];
    [se_editor setDelegate:self];
  }
  /* Update application */
  [se_editor setApplication:[self application]];
  return se_editor;
}

- (void)makeEntryOfType:(SparkPlugIn *)type {
  SEEntryEditor *editor = [self editor];
  [editor setEntry:nil];
  [editor setActionType:type];
  
  [NSApp beginSheet:[editor window]
     modalForWindow:[self windowForSheet]
      modalDelegate:nil
     didEndSelector:NULL
        contextInfo:nil];
}

@end
