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

+ (id)entryWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;
- (id)initWithAction:(SparkAction *)anAction trigger:(SparkTrigger *)aTrigger application:(SparkApplication *)anApplication;

- (void)setUID:(UInt32)anUID;

/* cached status */
- (void)setPlugged:(BOOL)flag;

/* is the entry in a manager */
- (SparkEntryManager *)manager;
- (void)setManager:(SparkEntryManager *)aManager;

- (void)setAction:(SparkAction *)action;
- (void)setTrigger:(SparkTrigger *)trigger;
- (void)setApplication:(SparkApplication *)anApplication;

/* fast access */
- (SparkUID)actionUID;
- (SparkUID)triggerUID;
- (SparkUID)applicationUID;

/* tree */
/* system entry only */
- (SparkEntry *)firstChild;
/* specific entry only */
- (SparkEntry *)sibling;
- (SparkEntry *)parent;

@end
