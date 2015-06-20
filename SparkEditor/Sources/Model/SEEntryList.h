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
@interface SEEntryList : NSObject

+ (SEEntryList *)separatorList;

- (instancetype)init;
- (instancetype)initWithList:(SparkList *)aList;
- (instancetype)initWithName:(NSString *)name icon:(NSImage *)icon;

@property(nonatomic, readonly) SparkList *sparkList;

- (void)snapshot;

- (void)setNeedsReload:(BOOL)flag;
- (void)setSpecificFilter:(BOOL)flag;

@property(nonatomic, copy) NSImage *icon;

@property(nonatomic, copy) NSString *name;

/* Editor facilities */
@property(nonatomic) uint8_t group;

@property(nonatomic, readonly, getter=isEditable) BOOL isEditable;

- (void)setDocument:(SELibraryDocument *)aDocument;
- (void)setApplication:(SparkApplication *)anApplication;

@property(nonatomic, copy) SparkListFilter filter;

@end
