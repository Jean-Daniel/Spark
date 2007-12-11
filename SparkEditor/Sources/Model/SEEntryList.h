/*
 *  SEEntryList.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkList.h>

@class SparkApplication;
@class SELibraryDocument;
@interface SEEntryList : SparkList {
  @private
	SELibraryDocument *se_document;
  SparkApplication *se_application;
}

- (void)setDocument:(SELibraryDocument *)aDocument;

- (BOOL)isEditable;

- (void)applicationDidChange:(NSNotification *)aNotification;

@end

SK_PRIVATE
NSString * const SEEntryListDidChangeNameNotification;

//@interface SEUserEntryList : SEEntryList {
//  @private
//  SparkList *se_list;
//}
//
//- (id)initWithList:(SparkList *)aList;
//
//- (SparkList *)list;
//
//@end
