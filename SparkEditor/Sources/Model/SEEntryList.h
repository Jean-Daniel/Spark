/*
 *  SEEntryList.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkList.h>

@class SparkPlugIn;
@class SELibraryDocument;
@interface SEEntryList : SparkList {
  @private
  SparkPlugIn *se_kind;
  SELibraryDocument *se_document;
}

- (id)initWithDocument:(SELibraryDocument *)aDocument kind:(SparkPlugIn *)kind;


- (SparkPlugIn *)kind;
- (SELibraryDocument *)document;

@end
