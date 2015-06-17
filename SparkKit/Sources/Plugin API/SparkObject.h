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
@abstract   Abstract super class for all serializable Spark Objects.
@discussion You never need intanciate a SparkObject directly. This is an Abstract class.
*/
@class SparkLibrary;
SPARK_OBJC_EXPORT
@interface SparkObject : NSObject <NSCopying>

/*!
@method     object
 @result     A new Empty object with an unique ID.
 */
+ (instancetype)object;
  /*!
  @method     objectWithName:
   @result     A new object with an unique ID.
   */
+ (instancetype)objectWithName:(NSString *)name;
  /*!
    @method     objectWithName:icon:
   @result     A new object with an unique ID.
   */
+ (instancetype)objectWithName:(NSString *)name icon:(NSImage *)icon;

  /*!
@method     initWithName:
   @abstract   Create a new SparkObject with an new uniq ID.
   @param      name The name of the new SparkObject.
   @result     A new created SparkObject.
   */
- (instancetype)initWithName:(NSString *)name;
  /*!
    @method     initWithName:icon:
   @abstract   Create a new SparkObject with an new uniq ID.
   @discussion Designated initializer.
   @result     A new created SparkObject.
   */
- (instancetype)initWithName:(NSString *)name icon:(NSImage *)icon NS_DESIGNATED_INITIALIZER;

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
- (instancetype)initWithSerializedValues:(NSDictionary *)plist NS_DESIGNATED_INITIALIZER;

  /*!
  @property
   @abstract   Returns the UID of this object. Uid of an object is set at creation time and shouldn't be changed.
   */
@property (nonatomic, readonly) SparkUID uid;

  /*!
  @property
   @abstract   The name for this object.
   */
@property (nonatomic, copy) NSString *name;

  /*!
  @property
   @abstract Icon of a Spark Object.
   */
@property (nonatomic, copy) NSImage *icon;

/*!
 @result Returns YES if the receiver has an icon, returns NO if the icon is not loaded.
 @discussion This method allows to determine if an object has already loaded an icon.
 */
@property (nonatomic, readonly) BOOL hasIcon;

  /*!
   @abstract  Returns NO to prevent Spark to save this object icon in the Library file.
   @result    Returns YES by default.
   @discussion If the receiver uses a static icon (for example an icon build from the action resources), 
   you should not save it and you should load it lazily (in the -icon call).
   */
@property (nonatomic, readonly) BOOL shouldSaveIcon;

/*!
  @abstract Object Icon not found in icon cache.
 @result Returns the receiver icon.
 @discussion This method is called when the object icon cannot be found in the icon cache.
 It lets a chance to the object to regenerate it.
*/
@property (nonatomic, readonly) NSImage *iconCacheMiss;

/* To be documented ? */
- (id)representation;
- (void)setRepresentation:(NSString *)rep;

@end

@interface SparkObject () <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end
