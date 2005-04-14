//
//  KeyWarningList.m
//  Spark Editor
//
//  Created by Grayfox on 01/11/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "KeyWarningList.h"
#import "ServerController.h"

NSString * const kWarningListDidChangeNotification = @"WarningListDidChangeNotification";

@implementation KeyWarningList

#pragma mark -
#pragma mark Constructors

- (id)init {
  if (self = [super init]) {
    [self setName:NSLocalizedStringFromTable(@"WARNING_LIST", @"Libraries", @"Key Warning List Display Name")];
    [self setIcon:[NSImage imageNamed:@"Warning"]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hotkeyDidChange:)
                                                 name:kSparkHotKeyDidChangeNotification
                                               object:nil];
    /* A key can become invalid when removing an action, an application or an applications list */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(libraryDidChange:)
                                                 name:kSparkLibraryDidRemoveListNotification
                                               object:SparkDefaultLibrary()];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(libraryDidChange:)
                                                 name:kSparkLibraryDidRemoveActionNotification
                                               object:SparkDefaultLibrary()];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(libraryDidChange:)
                                                 name:kSparkLibraryDidRemoveApplicationNotification
                                               object:SparkDefaultLibrary()];
    [self reload];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

#pragma mark -
#pragma mark Inherited Methods
- (BOOL)isEditable {
  return NO;
}
- (BOOL)isCustomizable {
  return NO;
}

- (void)didAddHotKey:(NSNotification *)aNotification {
  id hotkey = SparkNotificationObject(aNotification);
  if ([hotkey isInvalid]) {
    [self addObject:hotkey];
  } 
}

#pragma mark -
#pragma mark Specifics Methods

- (void)reload {
  id keys = [[self contentsLibrary] objectEnumerator];
  id hotkey;
  while (hotkey = [keys nextObject]) {
    if ([hotkey isInvalid]) {
      [self addObject:hotkey];
    }
  }
}

- (void)libraryDidChange:(NSNotification *)aNotification {
  unsigned count = [self count];
  [self reload];
  if (count != [self count]) {
    [[NSNotificationCenter defaultCenter] postNotificationName:kWarningListDidChangeNotification object:self];
  }
}

- (void)hotkeyDidChange:(NSNotification *)aNotification {
  id key = [aNotification object];
  if ([key isInvalid]) {
    [self addObject:key];
  } else {
    [self removeObject:key];
  }
}

@end
