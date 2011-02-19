/*
 *  SparkObject.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
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
SPARK_OBJC_EXPORT
@interface SparkObject : NSObject <NSCoding, NSCopying> {
  @private
  SparkUID sp_uid;
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
- (SparkUID)uid;

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
   @abstract Gets the name of a Spark Object.
   @result Returns the icon for this object.
   */
- (NSImage *)icon;
  /*!
  @method
   @abstract   Sets the icon of a Spark Object.
   @param      icon The icon to set.
   */
- (void)setIcon:(NSImage *)icon;

/*!
  @method
 @result Returns YES if the receiver has an icon, returns NO if the icon is not loaded.
 @discussion This method allows to determine if an object has already loaded an icon.
*/
- (BOOL)hasIcon;
  /*!
  @method
   @abstract  Returns NO to prevent Spark to save this object icon in the Library file.
   @result    Returns YES by default.
   @discussion If the receiver uses a static icon (for example an icon build from the action resources), 
   you should not save it and you should load it lazily (in the -icon call).
   */
- (BOOL)shouldSaveIcon;

/*!
  @abstract Object Icon not found in icon cache.
 @result Returns the receiver icon.
 @discussion This method is called when the object icon cannot be found in the icon cache.
 It lets a chance to the object to regenerate it.
*/
- (NSImage *)iconCacheMiss;

- (id)representation;
- (void)setRepresentation:(NSString *)rep;

@end
