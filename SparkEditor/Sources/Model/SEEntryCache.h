/*
 *  SEEntryCache.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

SK_PRIVATE NSString * const SEEntryCacheDidReloadNotification;

SK_PRIVATE NSString * const SEEntryCacheDidAddEntryNotification;
SK_PRIVATE NSString * const SEEntryCacheDidUpdateEntryNotification;
SK_PRIVATE NSString * const SEEntryCacheDidRemoveEntryNotification;
SK_PRIVATE NSString * const SEEntryCacheDidChangeEntryEnabledNotification;

@class SELibraryDocument, SESparkEntrySet;
@interface SEEntryCache : NSObject {
  @private
  SESparkEntrySet *se_base;
  SESparkEntrySet *se_merge;
  SELibraryDocument *se_document;
}

- (id)initWithDocument:(SELibraryDocument *)aDocument;

- (void)reload;
- (void)refresh;

- (SESparkEntrySet *)base;
- (SESparkEntrySet *)entries;

@end
