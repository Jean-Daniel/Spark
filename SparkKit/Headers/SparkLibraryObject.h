//
//  SparkLibraryObject.h
//
//  Created by Fox on Fri Jan 23 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

/*!
    @header 	SparkLibraryObject.
 	@abstract	SparkLibraryObject Declaration.
*/
#import <Cocoa/Cocoa.h>
#import <SparkKit/SparkSerialization.h>

/*!
    @class SparkLibraryObject
    @abstract   Abstract super class for all serializable Spark Objects.
    @discussion You never need intanciate a SparkLibraryObject directly. This is an Abstract class.
*/
@class SparkLibrary;
@interface SparkLibraryObject : NSObject <NSCoding, NSCopying, SparkLibraryObject> {
@private
  id _uid;
  NSImage *_icon;
  NSString *_name;
  SparkLibrary *_library;
}

/*!
    @method     loadUI
    @abstract   Determines if SparkKit run in UIMode. 
    @discussion Use to optimize Server loading and memory. You can determine if you need to load element or not.
    @result     Return NO in Daemon Context and YES in Editor Context.
*/
+ (BOOL)loadUI;

/*!
    @method     setLoadUI:
    @abstract   Use to set UIMode. Never use this function.
    @param      flag 
*/
+ (void)setLoadUI:(BOOL)flag;

/*!
    @method     initWithName:
    @abstract   Create a new SparkObject with an new uniq ID.
    @param      name The name of the new SparkObject.
    @result     A new created SparkObject.
*/
- (id)initWithName:(NSString *)name;
/*!
    @method     initWithName:icon:
    @abstract   Create a new SparkObject with an new uniq ID.
    @param      name (description)
    @param      icon (description)
    @result     A new created SparkObject.
*/
- (id)initWithName:(NSString *)name icon:(NSImage *)icon;

- (NSMutableDictionary *)propertyList;
- (id)initFromPropertyList:(NSDictionary *)plist;

/*!
    @method     object
    @abstract   (description)
    @result     A new Empty object with an unique ID.
*/
+ (id)object;
/*!
    @method     objectWithName:
    @abstract   (description)
    @param      name (description)
    @result     A new object with an unique ID.
*/
+ (id)objectWithName:(NSString *)name;
/*!
    @method     objectWithName:icon:
    @abstract   (description)
    @param      name (description)
    @param      icon (description)
    @result     A new object with an unique ID.
*/
+ (id)objectWithName:(NSString *)name icon:(NSImage *)icon;

/*!
    @method     objectFromPropertyList:
    @abstract   Create a new SparkObject by unserializing plist.
    @param      plist A serialized form of SparkObject. <i>plist</i> contains all keys/values pairs added into propertyList method.
    @result     A new deserialized SparkLibraryObject.
*/
+ (id)objectFromPropertyList:(NSDictionary *)plist;

/*!
    @method     uid
    @abstract   Returns the UID of this object. Uid of an object is set on creation and shouldn't be changed. 
*/
- (id)uid;
- (void)setUid:(id)uid;

/*!
    @method     name
    @abstract   Returns the name for this object.
*/
- (NSString *)name;
/*!
    @method     setName:
    @abstract   Sets the name for this object.
    @param      name The Name to set.
*/
- (void)setName:(NSString *)name;

/*!
    @method     icon
    @abstract   Returns the icon for this object.
*/
- (NSImage *)icon;
/*!
    @method     setIcon:
    @abstract   Sets the icon for this object.
    @param      icon The icon to set.
*/
- (void)setIcon:(NSImage *)icon;


/*!
    @method     isEqualToLibraryObject:
    @abstract   Return YES if <i>object</i> represents the same object than the receiver, wherever the values
 				in the two objects are equal or not.
    @param      object The object to compare.
    @result     Return YES if the receiver respresents the same object than <i>object</i>.
*/
- (BOOL)isEqualToLibraryObject:(SparkLibraryObject *)object;
@end
