/*
 *  SEEntryList.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class SparkEntry;
@class SELibraryDocument;
@interface SEEntryList : NSObject {
  @private
  NSImage *se_icon;
  NSString *se_name;
  NSMutableArray *se_entries;
  SELibraryDocument *se_document;
  
  struct _se_elFlags {
    unsigned int group:8;
    unsigned int reserved:24;
  } se_elFlags;
}

- (id)initWithName:(NSString *)name icon:(NSImage *)icon;

- (NSString *)name;
- (void)setName:(NSString *)name;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)icon;

- (UInt8)group;
- (void)setGroup:(UInt8)group;

- (SELibraryDocument *)document;
- (void)setDocument:(SELibraryDocument *)aDocument;

- (BOOL)isEditable;

@end
