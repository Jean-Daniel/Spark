/*
 *  SETriggerEntry.h
 *  Spark Editor
 *
 *  Created by Grayfox on 09/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

SK_PRIVATE
NSArray *gSortByNameDescriptors;

#pragma mark -
@class SparkAction, SparkTrigger;
@interface SETriggerEntry : NSObject {
  @private
  SparkAction *se_action;
  SparkTrigger *se_trigger;
}

+ (id)entryWithTrigger:(SparkTrigger *)aTrigger action:(SparkAction *)anAction;
- (id)initWithTrigger:(SparkTrigger *)aTrigger action:(SparkAction *)anAction;

- (BOOL)isEnabled;
- (NSString *)name;
- (NSString *)categorie;
- (NSString *)shortDescription;
- (NSString *)triggerDescription;

- (SparkAction *)action;
- (void)setAction:(SparkAction *)action;

- (SparkTrigger *)trigger;
- (void)setTrigger:(SparkTrigger *)trigger;

@end

@interface SETriggerEntrySet : NSObject {
  @private
  NSMapTable *se_set;
  NSMutableArray *se_entries;
}
- (void)removeAllEntries;

- (void)addEntry:(SETriggerEntry *)entry;

- (void)addEntriesFromEntrySet:(SETriggerEntrySet *)set;
- (void)addEntriesFromDictionary:(NSDictionary *)aDictionary;

- (NSEnumerator *)entryEnumerator;

- (SETriggerEntry *)entryAtIndex:(unsigned)idx;
- (SETriggerEntry *)entryForTrigger:(SparkTrigger *)aTrigger;

- (BOOL)containsTrigger:(SparkTrigger *)trigger;
- (SparkAction *)actionForTrigger:(SparkTrigger *)trigger;

@end
