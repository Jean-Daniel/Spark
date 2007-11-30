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

@class SparkLibrary, SparkEntryPlaceholder;
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
    unsigned int managed:1;
    unsigned int unplugged:1;
    unsigned int reserved:29;
  } sp_seFlags;
  SparkEntry *sp_parent;
}

+ (id)entryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

- (id)initWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

- (UInt32)uid;
- (SparkEntry *)parent;
- (void)setParent:(SparkEntry *)aParent;

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

+ (SparkEntry *)entryWithPlaceholder:(SparkEntryPlaceholder *)placeholder library:(SparkLibrary *)aLibrary;

- (void)setUID:(UInt32)anUID;

/* cached status */
- (void)setPlugged:(BOOL)flag;

/* is the entry in a manager */
- (BOOL)isManaged;
- (void)setManaged:(BOOL)managed;

/* direct object access */
- (void)setAction:(SparkAction *)action;
- (void)setTrigger:(SparkTrigger *)trigger;
- (void)setApplication:(SparkApplication *)anApplication;

/* fast access */
- (SparkUID)actionUID;
- (SparkUID)triggerUID;
- (SparkUID)applicationUID;

@end

#pragma mark Placeholder
@interface SparkEntryPlaceholder : NSObject {
  @private
  BOOL sp_enabled;
  
  SparkUID sp_action;
  SparkUID sp_trigger;
  SparkUID sp_application;
}

- (id)initWithActionUID:(SparkUID)act triggerUID:(SparkUID)trg applicationUID:(SparkUID)app;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

- (SparkUID)actionUID;
- (SparkUID)triggerUID;
- (SparkUID)applicationUID;

- (void)setActionUID:(SparkUID)action;
- (void)setTriggerUID:(SparkUID)trigger;
- (void)setApplicationUID:(SparkUID)application;

@end

