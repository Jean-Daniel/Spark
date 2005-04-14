//
//  ListEditorController.m
//  Spark
//
//  Created by Fox on Thu Jan 22 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
#import <SparkKit/SparkKit.h>

#import "ListEditorController.h"
#import "KeyLibraryController.h"

@implementation ListEditorController

- (id)init {
  if (self= [super initWithWindowNibName:@"ListEditor"]) {
    [self window];
  }
  return self;
}

- (void)dealloc {
  [name release];
  [super dealloc];
}

- (SparkObjectList *)object {
  return _list;
}

- (void)setObject:(SparkObjectList *)list {
  NSParameterAssert(nil != list);
  _list = list;
  [super setObject:list];
  [self setName:[_list name]];
  [title setStringValue:NSLocalizedStringFromTable(@"UPDATE_LIST",
                                                   @"Editors", @"ListEditor Panel * Update Title *")];
}

- (Class)listClass {
  return _listClass;
}

- (void)setListClass:(Class)listClass {
  _listClass = listClass;
}

- (IBAction)create:(id)sender {
  NSAssert(_listClass != nil, @"ListClass not set");
  _list = [_listClass listWithName:name];
  [super create:sender];
}

- (IBAction)update:(id)sender {
  [_list setName:[self name]];
  [super update:sender];
}

- (NSString *)name {
  return name;
}

- (void)setName:(NSString *)newName {
  if (name != newName) {
    [name release];
    name = [newName copy];
  }
}

#pragma mark -
- (void)windowWillClose:(NSNotification *)aNotification {
  [objectController setContent:nil];
}

@end
