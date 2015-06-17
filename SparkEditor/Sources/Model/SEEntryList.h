/*
 *  SEEntryList.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkList.h>

@class SELibraryDocument;
@class SparkApplication, SparkList;
@interface SEEntryList : NSObject {
  @private
	SparkList *se_list;
	NSMutableArray *se_snapshot;
  SparkApplication *se_application;
	
	struct _se_selFlags {
		unsigned int dirty:1;
		unsigned int group:8;
		unsigned int specific:1;
		unsigned int isVirtual:1;
		unsigned int separator:1;
		unsigned int reserved:21;
	} se_selFlags;
}

+ (SEEntryList *)separatorList;

- (id)init;
- (id)initWithList:(SparkList *)aList;
- (id)initWithName:(NSString *)name icon:(NSImage *)icon;

- (SparkList *)sparkList;

- (void)snapshot;

- (void)setNeedsReload:(BOOL)flag;
- (void)setSpecificFilter:(BOOL)flag;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)icon;

- (NSString *)name;
- (void)setName:(NSString *)aName;

/* Editor facilities */
- (UInt8)group;
- (void)setGroup:(UInt8)group;

- (BOOL)isEditable;

- (void)setDocument:(SELibraryDocument *)aDocument;
- (void)setApplication:(SparkApplication *)anApplication;

@property(nonatomic, copy) SparkListFilter filter;

@end
