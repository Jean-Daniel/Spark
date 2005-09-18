//
//  SparkSerialization.h
//  SparkKit
//
//  Created by Grayfox on 16/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SparkLibrary;
@protocol SparkSerialization <NSObject>

/*!
	@method     initFromPropertyList:
	@abstract   Create a new object by unserializing plist.
	@param      plist A serialized form of an object. <i>plist</i> contains all keys/values pairs added into propertyList method.
	@result     A new deserialized object.
 */
- (id)initFromPropertyList:(NSDictionary *)plist;

/*!
    @method     propertyList
    @abstract   (brief description)
    @result     (description)
*/
- (NSMutableDictionary *)propertyList;

@end

@protocol SparkLibraryObject <SparkSerialization>

/*!
	@method     uid
	@abstract   Returns a <i>unsigned</i> representing an uniq ID.
 */
- (id)uid;
/*!
	@method     setUid:
	@abstract   Don't call this method directly. This method is called by Library.
	@param      uid (description)
 */
- (void)setUid:(id)uid;

/*!
    @method     library
    @abstract   Returns the receiver Library.
*/
- (SparkLibrary *)library;
/*!
    @method     setLibrary:
    @abstract   Sets the receiver Library. Don't call this method. It's called when receiver is added in a Library.
    @param      aLibrary The Library that contains the receiver.
*/
- (void)setLibrary:(SparkLibrary *)aLibrary;
@end

id SparkDeserializeObject(NSDictionary *plist);
NSDictionary *SparkSerializeObject(NSObject<SparkSerialization> *object);
