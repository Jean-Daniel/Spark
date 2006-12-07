/*
 *  SparkObject.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

/*!
@header 	SparkObject.
 @abstract	SparkObject Declaration.
 */

#import <SparkKit/SparkKit.h>

/*!
@class SparkObject
@abstract   Abstract super class for all serializable Spark Objects.
@discussion You never need intanciate a SparkObject directly. This is an Abstract class.
*/
@class SparkLibrary;
@interface SparkObject : NSObject <NSCoding, NSCopying> {
  @private
  UInt32 sp_uid;
  NSImage *sp_icon;
  NSString *sp_name;
  SparkLibrary *sp_library;
}

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
@method     initWithName:
   @abstract   Create a new SparkObject with an new uniq ID.
   @param      name The name of the new SparkObject.
   @result     A new created SparkObject.
   */
- (id)initWithName:(NSString *)name;
  /*!
    @method     initWithName:icon:
   @abstract   Create a new SparkObject with an new uniq ID.
   @discussion Designated initializer.
   @param      name (description)
   @param      icon (description)
   @result     A new created SparkObject.
   */
- (id)initWithName:(NSString *)name icon:(NSImage *)icon;

#pragma mark Serialization Support
  /*!
  @method
   @abstract plist
   @result Returns YES if ok.
   */
- (BOOL)serialize:(NSMutableDictionary *)plist;
  /*!
  @method
   @abstract Create a new object by unserializing plist.
   @param plist A serialized form of an object. <i>plist</i> contains all keys/values pairs added into propertyList method.
   @result A new deserialized object.
   */
- (id)initWithSerializedValues:(NSDictionary *)plist;

  /*!
  @method
   @abstract   Returns the UID of this object. Uid of an object is set at creation time and shouldn't be changed. 
   */
- (UInt32)uid;

  /*!
  @method
   @abstract   Returns the name for this object.
   */
- (NSString *)name;
  /*!
  @method
   @abstract   Sets the name for this object.
   @param      name The Name to set.
   */
- (void)setName:(NSString *)name;

  /*!
  @method
   @abstract   Returns the icon for this object.
   */
- (NSImage *)icon;
  /*!
  @method
   @abstract   Sets the icon for this object.
   @param      icon The icon to set.
   */
- (void)setIcon:(NSImage *)icon;

  /*!
  @method
   @abstract   Allows to not save the icon in SparkLibrary.
   @result    Returns YES by default.
   */
- (BOOL)shouldSaveIcon;

  /*!
    @method     isEqualToLibraryObject:
   @abstract   Return YES if <i>object</i> represents the same object than the receiver, wherever the values
   in the two objects are equal or not.
   @param      object The object to compare.
   @result     Return YES if the receiver respresents the same object than <i>object</i>.
   */
- (BOOL)isEqualToLibraryObject:(SparkObject *)object;

#pragma mark Internal Methods
  /*!
  @method
   @abstract Don't call this method directly. This method is called by Library.
   @param uid (description)
   */
- (void)setUID:(UInt32)uid;
  /*!
  @method
   @abstract Returns the receiver Library.
   */
- (SparkLibrary *)library;
  /*!
  @method
   @abstract Sets the receiver Library. Don't call this method. It's called when receiver is added in a Library.
   @param aLibrary The Library that contains the receiver.
   */
- (void)setLibrary:(SparkLibrary *)aLibrary;

@end
