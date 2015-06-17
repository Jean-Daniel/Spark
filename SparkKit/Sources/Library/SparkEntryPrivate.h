/*
 *  SparkEntryPrivate.h
 *  SparkKit
 *
 *  Created by Jean-Daniel Dupas on 17/12/07.
 *  Copyright 2007 Ninsight. All rights reserved.
 *
 */

#import <SparkKit/SparkEntry.h>

@interface SparkEntry ()

+ (instancetype)entryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;
- (instancetype)initWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

@property(nonatomic, setter=setUID:) uint32_t uid;

/* cached status */
- (void)setPlugged:(BOOL)flag;

/* is the entry in a manager */
@property(nonatomic, assign) SparkEntryManager * manager;

@property(nonatomic, retain) SparkAction *action;
@property(nonatomic, retain) SparkTrigger *trigger;
@property(nonatomic, retain) SparkApplication *application;

/* fast access */
@property(nonatomic, readonly) SparkUID actionUID;
@property(nonatomic, readonly) SparkUID triggerUID;
@property(nonatomic, readonly) SparkUID applicationUID;

/* tree */
/* system entry only */
@property(nonatomic, readonly) SparkEntry *firstChild;
/* specific entry only */
@property(nonatomic, readonly) SparkEntry *sibling;
@property(nonatomic, readonly) SparkEntry *parent;

@end
