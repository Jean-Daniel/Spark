/*
 *  SEEntryCache.h
 *  Spark Editor
 *
 *  Created by Grayfox on 16/01/07.
 *  Copyright 2007 Shadow Lab. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@interface SEEntryCache : NSObject {
  @private
  CFMutableSetRef se_entries;
}

@end
