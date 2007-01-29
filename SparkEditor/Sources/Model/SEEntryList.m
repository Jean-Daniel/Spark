/*
 *  SEEntryList.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEEntryList.h"
#import "SEEntryCache.h"
#import "SESparkEntrySet.h"
#import "SELibraryDocument.h"

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkTrigger.h>

static 
BOOL SEPluginListFilter(SparkList *slist, SparkObject *object, id ctxt) {
  SEEntryList *list = (SEEntryList *)slist;
  SEEntryCache *cache = [[list document] cache];
  SparkEntry *entry = [[cache entries] entryForTrigger:(SparkTrigger *)object];
  return entry && [[entry action] isKindOfClass:[[list kind] actionClass]];
}

@implementation SEEntryList

- (id)initWithDocument:(SELibraryDocument *)aDocument kind:(SparkPlugIn *)kind {
  if (self = [super initWithObjectSet:[[aDocument library] triggerSet]]) {
    se_kind = kind;
    se_document = aDocument;
    
    /* Configure */
    [self setName:[kind name]];
    [self setIcon:[kind icon]];
    
    /* Self set filter */
    [self setListFilter:SEPluginListFilter context:nil];
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (SparkPlugIn *)kind {
  return se_kind;
}

- (SELibraryDocument *)document {
  return se_document;
}

- (void)registerNotifications {
  SparkLibrary *library = [self library];
  [[library notificationCenter] addObserver:self
                                   selector:@selector(didAddEntry:)
                                       name:SEEntryCacheDidAddEntryNotification
                                     object:nil];
  [[library notificationCenter] addObserver:self
                                   selector:@selector(didUpdateEntry:)
                                       name:SEEntryCacheDidUpdateEntryNotification
                                     object:nil];
  [[library notificationCenter] addObserver:self
                                   selector:@selector(didRemoveEntry:)
                                       name:SEEntryCacheDidRemoveEntryNotification
                                     object:nil];
}

- (void)unregisterNotifications {
  SparkLibrary *library = [self library];
  [[library notificationCenter] removeObserver:self];
}


- (void)didAddEntry:(NSNotification *)aNotification {
  ShadowTrace();
}

- (void)didUpdateEntry:(NSNotification *)aNotification {
  ShadowTrace();
}

- (void)didRemoveEntry:(NSNotification *)aNotification {
  ShadowTrace();
}

@end
