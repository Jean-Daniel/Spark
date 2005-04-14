//
//  SparkActionList.h
//  SparkKit
//
//  Created by Fox on 01/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkObjectList.h>

/*!
	@class		SparkActionList
	@abstract   Represents a Action List in SparkEditor. As it is a SparkLibraryObject, a list can
				be wrote on disk for persistent Storage.
*/
@interface SparkActionList : SparkObjectList <NSCoding, NSCopying> {
}

/*!
	@method     contentsLibrary
	@abstract   Returns the shared SparkActionLibrary.
 */
- (SparkObjectsLibrary *)contentsLibrary;
@end

