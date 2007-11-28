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

@class SparkAction, SparkTrigger, SparkApplication;

SPARK_CLASS_EXPORT
@interface SparkEntry : NSObject <NSCopying> {
  @private
  UInt32 sp_uid;
  SparkAction *sp_action;
  SparkTrigger *sp_trigger;
  SparkApplication *sp_application;

  /* status */
  UInt32 sp_flags;
  SparkEntry *sp_parent;
}

+ (id)entryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

- (id)initWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

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

@end

@interface SparkEntry (SparkEntryManager)

- (void)setUID:(UInt32)anUID;

/* cached status */
- (void)setPlugged:(BOOL)flag;

/* direct object access */
- (void)setAction:(SparkAction *)action;
- (void)setTrigger:(SparkTrigger *)trigger;
- (void)setApplication:(SparkApplication *)anApplication;

/* fast access */
- (SparkUID)actionUID;
- (SparkUID)triggerUID;
- (SparkUID)applicationUID;

@end
