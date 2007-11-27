/*
 *  SparkEntry.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

typedef enum {
  kSparkEntryTypeDefault = 0, /* Inherits or global */
  kSparkEntryTypeSpecific = 1, /* Defined in custom application only */
  kSparkEntryTypeOverWrite = 2, /* OverWrite a default action and status */
  kSparkEntryTypeWeakOverWrite = 3, /* Overwrite default status but same action */
} SparkEntryType;

@class SparkAction, SparkTrigger, SparkApplication;

SK_CLASS_EXPORT
@interface SparkEntry : NSObject <NSCopying> {
  @private
  UInt32 sp_uid;
  SparkAction *sp_action;
  SparkTrigger *sp_trigger;
  SparkApplication *sp_application;

  /* status */
  UInt8 sp_type;
  UInt32 sp_flags;
  /* parent entry, NULL for root entries */
  SparkEntry *sp_parent;
}

+ (id)entryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

- (id)initWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

- (UInt32)uid;
- (void)setUID:(UInt32)anUID;

- (SparkAction *)action;
- (void)setAction:(SparkAction *)action;

- (SparkTrigger *)trigger;
- (void)setTrigger:(SparkTrigger *)trigger;

- (SparkApplication *)application;
- (void)setApplication:(SparkApplication *)anApplication;

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

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

- (BOOL)isPlugged;
- (void)setPlugged:(BOOL)flag; /* internal use only */

- (BOOL)isPersistent;
- (void)setPersistent:(BOOL)flag;

/* type */
- (SparkEntryType)type;
- (void)setType:(SparkEntryType)type;

@end

