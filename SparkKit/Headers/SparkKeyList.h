//
//  SparkKeyList.h
//  Spark
//
//  Created by Fox on Thu Jan 08 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkObjectList.h>

/*!
    @class		SparkKeyList
	@abstract   Represents a HotKey List in SparkEditor. As it is a SparkLibraryObject, a list can
 				be wrote on disk for persistent Storage.
*/
@interface SparkKeyList : SparkObjectList <NSCoding, NSCopying> {
}

/*!
    @method     contentsLibrary
    @abstract   Returns the shared SparkKeyLibrary.
*/
- (SparkObjectsLibrary *)contentsLibrary;

- (void)didAddHotKey:(NSNotification *)aNotification;
- (void)didRemoveHotKey:(NSNotification *)aNotification;

@end