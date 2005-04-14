//
//  Extensions.h
//  Spark Editor
//
//  Created by Fox on 02/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>

@interface NSArrayController (SparkExtension)

- (NSEnumerator *)objectEnumerator;
- (id)objectAtIndex:(unsigned)rowIndex;
- (id)selectedObject;
- (BOOL)setSelectedObject:(id)object;

- (void)deleteSelection;
- (void)removeAllObjects;

@end

@interface KVBSparkObjectList : SparkObjectList {
}

- (void)insertObject:(id)object inObjectsAtIndex:(unsigned)index;
- (void)removeObjectFromObjectsAtIndex:(unsigned)index;
- (void)replaceObjectInObjectsAtIndex:(unsigned)index withObject:(id)object;

@end

@interface SparkLibraryObject (DuplicateExtension)

- (id)duplicate;

@end

@interface NSTabView (Extension)
- (int)indexOfSelectedTabViewItem;
@end