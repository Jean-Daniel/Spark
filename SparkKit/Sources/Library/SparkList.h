/*
 *  SparkList.h
 *  SparkKit
 *
 *  Created by Grayfox on 30/07/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkObject.h>

@class SparkObjectsLibrary; 
@interface SparkList : SparkObject {
  @private
  NSMutableArray *sp_entries;
  SparkObjectsLibrary *sp_lib; /* weak reference */
}

- (void)setLibrary:(SparkObjectsLibrary *)library;

/* Special initializer */
- (id)initWithLibrary:(SparkObjectsLibrary *)library
     serializedValues:(NSDictionary *)plist;

@end
