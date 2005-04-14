//
//  SparkObjectList.h
//  SparkKit
//
//  Created by Fox on 01/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkLibraryObject.h>

@class SparkObjectsLibrary;
@interface SparkObjectList : SparkLibraryObject <NSCoding, NSCopying> {
@private
  NSMutableArray *_objects;
}

+ (NSString *)defaultIconName;

#pragma mark -
+ (id)list;
+ (id)listWithName:(NSString *)name;
+ (id)listWithName:(NSString *)name icon:(NSImage *)icon;
+ (id)listFromPropertyList:(id)plist;

#pragma mark -
- (SparkObjectsLibrary *)contentsLibrary;
- (Class)contentType;
- (NSArray *)objects;
- (NSArray *)objectsUid;

- (unsigned)count;

- (unsigned)indexOfObject:(SparkLibraryObject *)object;
- (BOOL)containsObject:(SparkLibraryObject *)object;

- (void)addObject:(SparkLibraryObject *)object;
- (void)addObjects:(NSArray *)objects;
- (void)addObjectsWithUids:(NSArray *)uids;

- (void)insertObject:(SparkLibraryObject *)anObject atIndex:(unsigned)index;
- (void)replaceObjectAtIndex:(unsigned)index withObject:(SparkLibraryObject *)object;

- (void)removeObject:(SparkLibraryObject *)object;
- (void)removeObjects:(NSArray *)objects;
- (void)removeObjectAtIndex:(unsigned)index;

#pragma mark -
/*!
	@method     isEditable
	@abstract   Returns YES if the list is Editable, ie user can had HotKeys into this List.
	@result     Returns YES. Subclasses should override this method to returns NO.
 */
- (BOOL)isEditable;

/*!
    @method     isCustomizable
    @abstract   Returns YES if the list is Customizable, ie user can edit properties for this List.
    @result     Returns YES. Subclasses should override this method to returns NO.
*/
- (BOOL)isCustomizable;

@end
