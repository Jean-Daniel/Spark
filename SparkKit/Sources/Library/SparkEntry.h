/*
 *  SparkEntry.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

typedef enum {
  kSparkEntryTypeDefault = 0, /* Inherits or global */
  kSparkEntryTypeSpecific = 1, /* Defined in custom application only */
  kSparkEntryTypeOverWrite = 2, /* OverWrite a default action and status */
  kSparkEntryTypeWeakOverWrite = 3, /* Overwrite default status but same action */
} SparkEntryType;

SPARK_EXPORT
NSString * const SparkEntryDidAppendChildNotification;
SPARK_EXPORT
NSString * const SparkEntryWillRemoveChildNotification;

@class SparkEntryManager;
@class SparkAction, SparkTrigger, SparkApplication;
SPARK_CLASS_EXPORT
@interface SparkEntry : NSObject <NSCopying> {
  @private
  UInt32 sp_uid;
  SparkAction *sp_action;
  SparkTrigger *sp_trigger;
  SparkApplication *sp_application;

  /* status */
  struct _sp_seFlags {
    unsigned int enabled:1;
		unsigned int editing:1;
    unsigned int registred:1;
    unsigned int unplugged:1;
    unsigned int reserved:28;
  } sp_seFlags;
  /* chained list of children */
  SparkEntry *sp_child;
  /* list head (or nil) */
  __weak SparkEntry *sp_parent;
  
  /* Manager */
  __weak SparkEntryManager *sp_manager;
}

- (UInt32)uid;

- (SparkEntryType)type;

- (SparkAction *)action;
- (SparkTrigger *)trigger;
- (SparkApplication *)application;

/* convenient accessors */
- (NSImage *)icon;
- (void)setIcon:(NSImage *)anIcon;

- (NSString *)name;
- (void)setName:(NSString *)aName;

- (NSString *)categorie;
- (NSString *)actionDescription;
- (NSString *)triggerDescription;

/* status */
- (BOOL)isActive;
- (BOOL)isPlugged;
- (BOOL)isPersistent;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

/* usefull for SparkList (root is 'self' on orphan and system actions, else it is 'parent') */
- (BOOL)isRoot;
- (SparkEntry *)root;

/* return YES if this is a system entry */
- (BOOL)isSystem;

/* System entry only */

/* Returns YES if contains at least one variant (valid only on system entry) */
- (BOOL)hasVariant;

/* returns the root entry and all children */
- (NSArray *)variants;
/* returns the specific entry for anApplication, or nil if not found */
- (SparkEntry *)variantWithApplication:(SparkApplication *)anApplication;

@end

@interface SparkEntry (SparkMutableEntry)

/* start to record change for the entry manager */
- (void)beginEditing;
/* commit change to the entry manager */
- (void)endEditing;

/* entry edition */
- (void)replaceAction:(SparkAction *)action;
- (void)replaceTrigger:(SparkTrigger *)trigger;
- (void)replaceApplication:(SparkApplication *)anApplication;

/* derive entries */
- (SparkEntry *)createWeakVariantWithApplication:(SparkApplication *)anApplication;
- (SparkEntry *)createVariantWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

@end

@interface SparkEntry (SparkRegistration)

- (BOOL)isRegistred;
- (void)setRegistred:(BOOL)flag;

@end

