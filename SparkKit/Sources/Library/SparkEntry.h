/*
 *  SparkEntry.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

typedef NS_ENUM(NSUInteger, SparkEntryType) {
  kSparkEntryTypeDefault = 0, /* Inherits or global */
  kSparkEntryTypeSpecific = 1, /* Defined in custom application only */
  kSparkEntryTypeOverWrite = 2, /* OverWrite a default action and status */
  kSparkEntryTypeWeakOverWrite = 3, /* Overwrite default status but same action */
};

SPARK_EXPORT
NSString * const SparkEntryDidAppendChildNotification;

SPARK_EXPORT
NSString * const SparkEntryWillRemoveChildNotification;

@class SparkEntryManager;
@class SparkAction, SparkTrigger, SparkApplication;

SPARK_OBJC_EXPORT
@interface SparkEntry : NSObject <NSCopying>

@property(nonatomic, readonly) uint32_t uid;

@property(nonatomic, readonly) SparkEntryType type;

@property(nonatomic, readonly, retain) SparkAction *action;
@property(nonatomic, readonly, retain) SparkTrigger *trigger;
@property(nonatomic, readonly, retain) SparkApplication *application;

/* convenient accessors: forward to the entry's action */
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSImage *icon;

@property (nonatomic, readonly) NSString *category;
@property (nonatomic, readonly) NSString *actionDescription;
@property (nonatomic, readonly) NSString *triggerDescription;

/* status */
@property (nonatomic, readonly, getter=isActive) BOOL active;
@property (nonatomic, readonly, getter=isPlugged) BOOL plugged;
@property (nonatomic, readonly, getter=isPersistent) BOOL persistent;

@property (nonatomic, getter=isEnabled) BOOL enabled;

/* usefull for SparkList (root is 'self' on orphan and system actions, else it is 'parent') */
@property (nonatomic, readonly) BOOL isRoot;
@property (nonatomic, readonly) SparkEntry *root;

/* return YES if this is a system entry */
@property (nonatomic, readonly) BOOL isSystem;

/* System entry only */

/* Returns YES if contains at least one variant (valid only on system entry) */
@property (nonatomic, readonly) BOOL hasVariant;

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

@property (nonatomic, getter=isRegistred) BOOL registred;

@end

