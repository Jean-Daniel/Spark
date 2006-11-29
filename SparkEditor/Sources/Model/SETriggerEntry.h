/*
 *  SETriggerEntry.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

enum {
  kSEEntryTypeGlobal = 0,
  kSEEntryTypeOverwrite,
  kSEEntryTypeIgnore
};

#pragma mark -
@class SparkAction, SparkTrigger;
@interface SETriggerEntry : NSObject <NSCopying> {
  @private
  struct _se_teFlags {
    unsigned int type:7;
    unsigned int enabled:1;
    unsigned int reserved:24;
  } se_teFlags;
  SparkAction *se_action;
  SparkTrigger *se_trigger;
}

+ (id)entryWithTrigger:(SparkTrigger *)aTrigger action:(SparkAction *)anAction;
- (id)initWithTrigger:(SparkTrigger *)aTrigger action:(SparkAction *)anAction;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;

- (NSString *)name;
- (void)setName:(NSString *)aName;

- (NSString *)categorie;
- (NSString *)actionDescription;
- (NSString *)triggerDescription;

- (int)type;
- (void)setType:(int)type;

- (SparkAction *)action;
- (void)setAction:(SparkAction *)action;

- (id)trigger;
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
