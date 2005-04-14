//
//  KeyPlugInList.m
//  Spark Editor
//
//  Created by Grayfox on 18/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "KeyPlugInList.h"
#import "ServerController.h"

@implementation KeyPlugInList

#pragma mark Protocols Implementation
- (id)copyWithZone:(NSZone *)zone {
  KeyPlugInList *copy = [super copyWithZone:zone]; 
  copy->_plugIn = [_plugIn retain];
  return copy;
}

#pragma mark -
#pragma mark Statics Methods
+ (NSString *)defaultIconName {
  return @"PlugInListIcon";
}

#pragma mark -
#pragma mark Constructors
+ (id)listWithPlugIn:(SparkPlugIn *)plugIn {
  return [[[self alloc] initWithPlugIn:plugIn] autorelease];
}

- (id)initWithPlugIn:(SparkPlugIn *)plugIn {
  if (self = [super initWithName:[plugIn name] icon:[plugIn icon]]) {
    [self setPlugIn:plugIn];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hotkeyDidChange:)
                                                 name:kSparkHotKeyDidChangeNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_plugIn release];
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
  if (![hotkey hasManyActions] && [[hotkey defaultAction] class] == [_plugIn actionClass]) {
    [self addObject:hotkey];
  } 
}

#pragma mark -
#pragma mark Specifics Methods
- (SparkPlugIn *)plugIn {
  return _plugIn;
}
- (void)setPlugIn:(SparkPlugIn *)plugIn {
  if (_plugIn != plugIn) {
    [_plugIn release];
    _plugIn = [plugIn retain];
    [self reload];
  }
}

- (void)reload {
  id keys = [[self contentsLibrary] objectEnumerator];
  id hotkey;
  while (hotkey = [keys nextObject]) {
    if (![hotkey hasManyActions] && [[hotkey defaultAction] class] == [_plugIn actionClass]) {
      [self addObject:hotkey];
    }
  }
}

- (void)hotkeyDidChange:(NSNotification *)aNotification {
  id key = [aNotification object];
  if ([key hasManyActions] || [[key defaultAction] class] != [_plugIn actionClass]) {
    [self removeObject:key];
  } else {
    [self addObject:key];
  }
}

@end

@implementation MultipleActionsKeyList

- (id)copyWithZone:(NSZone *)zone {
  MultipleActionsKeyList *copy = [super copyWithZone:zone];
  return copy;
}

- (id)init {
  if (self = [super init]) {
    [self setName:NSLocalizedStringFromTable(@"CUSTOM_KEY_LIST", @"Libraries", @"Custom Keys List (Display Name)")];
    [self setIcon:[NSImage imageNamed:@"CustomKeysList"]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hotkeyDidChange:)
                                                 name:kSparkHotKeyDidChangeNotification
                                               object:nil];
    [self reload];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (BOOL)isEditable {
  return NO;
}
- (BOOL)isCustomizable {
  return NO;
}

- (void)reload {
  id keys = [[self contentsLibrary] objectEnumerator];
  id hotkey;
  while (hotkey = [keys nextObject]) {
    if ([hotkey hasManyActions]) {
      [self addObject:hotkey];
    }
  }
}

- (void)didAddHotKey:(NSNotification *)aNotification {
  id hotkey = SparkNotificationObject(aNotification);
  if ([hotkey hasManyActions]) {
    [self addObject:hotkey];
  } 
}

- (void)hotkeyDidChange:(NSNotification *)aNotification {
  id key = [aNotification object];
  if (![key hasManyActions]) {
    [self removeObject:key];
  } else {
    [self addObject:key];
  }
}

@end