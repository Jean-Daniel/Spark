/*
 *  SEEntryList.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEEntryList.h"
#import "SELibraryDocument.h"

//#import <SparkKit/SparkPlugIn.h>
//#import <SparkKit/SparkLibrary.h>
//#import <SparkKit/SparkTrigger.h>

#import <SparkKit/SparkEntry.h>

//static 
//BOOL SEPluginListFilter(SparkList *slist, SparkObject *object, id ctxt) {
//  SEEntryList *list = (SEEntryList *)slist;
//  SEEntryCache *cache = [[list document] cache];
//  SparkEntry *entry = [[cache entries] entryForTrigger:(SparkTrigger *)object];
//  return entry && [[entry action] isKindOfClass:[[list kind] actionClass]];
//}

@implementation SEEntryList

- (id)initWithName:(NSString *)name icon:(NSImage *)icon {
  if (self = [super init]) {
    [self setName:name];
    [self setIcon:icon];
  }
  return self;
}

- (void)dealloc {
  [se_icon release];
  [se_name release];
  [se_entries release];
  [super dealloc];
}

#pragma mark -
- (NSImage *)icon {
  return se_icon;
}
- (void)setIcon:(NSImage *)icon {
  SKSetterRetain(se_icon, icon);
}

- (NSString *)name {
  return se_name;
}
- (void)setName:(NSString *)name {
  SKSetterCopy(se_name, name);
}

- (UInt8)group {
  return se_elFlags.group;
}
- (void)setGroup:(UInt8)group {
  se_elFlags.group = group;
}

- (SELibraryDocument *)document {
  return se_document;
}
- (void)setDocument:(SELibraryDocument *)aDocument {
  se_document = aDocument;
}

- (BOOL)isEditable {
  return NO;
}

- (id)representation {
  return self;
}
- (void)setRepresentation:(NSString *)representation {
  [self setName:representation];
}

//- (void)registerNotifications {
//  SparkLibrary *library = [self library];
//  [[library notificationCenter] addObserver:self
//                                   selector:@selector(didAddEntry:)
//                                       name:SEEntryCacheDidAddEntryNotification
//                                     object:nil];
//  [[library notificationCenter] addObserver:self
//                                   selector:@selector(didUpdateEntry:)
//                                       name:SEEntryCacheDidUpdateEntryNotification
//                                     object:nil];
//  [[library notificationCenter] addObserver:self
//                                   selector:@selector(didRemoveEntry:)
//                                       name:SEEntryCacheDidRemoveEntryNotification
//                                     object:nil];
//}

//- (void)didAddEntry:(NSNotification *)aNotification {
//  ShadowTrace();
//}
//
//- (void)didUpdateEntry:(NSNotification *)aNotification {
//  ShadowTrace();
//}
//
//- (void)didRemoveEntry:(NSNotification *)aNotification {
//  ShadowTrace();
//}

@end
