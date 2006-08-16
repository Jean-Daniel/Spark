/*
 *  SparkAction.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */
/*!
@header SparkAction
 @abstract SparkAction Declaration.
 */

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkObject.h>

@class SparkAlert;

enum {
  kSparkActionVersion_1_0 = 0x100,
  kSparkActionVersion_2_0 = 0x200
};
#define kSparkActionCurrentVersion	kSparkActionVersion_2_0;

/*!
@function SparkGetDefaultKeyRepeatInterval
 @abstract Returns the system default time interval for repeat keys.
 This default time can be changed by the user in «System Preferences».
 @result Returns the system default time interval for repeat keys.
 */
SPARK_EXPORT
NSTimeInterval SparkGetDefaultKeyRepeatInterval(void);

/*!
@class 		SparkAction
@abstract   SparkAction is the class that represent action used in Spark.

@discussion Subclass must override methods:
<ul style="list-style:none">
<li>-initWithSerializedValues:</li>
<li>-serialize:</li>
<li>-check (optional)</li>
<li>-execute</li>
<ul>
*/
@interface SparkAction : SparkObject <NSCopying, NSCoding> {
  @private
  int sp_version;
  struct _sp_saFlags {
    unsigned int invalid:1;
    unsigned int :15;
  } sp_saFlags;
  NSString *sp_categorie, *sp_description;
}

/*!
@method
 @abstract Required! Serialization method. This method MUST always call super method before adding its own value.
 @discussion This method convert an action into serializable representation so you must only add PropertyList Objects
 into <code>plist</code>.
 @param plist A Dictionary representation of this object. Add receivers properties into it.
 @result YES if ok.
 */
- (BOOL)serialize:(NSMutableDictionary *)plist;
  /*!
  @method
   @abstract Required! Create a new object by unserializing plist.
   @param plist A serialized form of an object. <i>plist</i> contains all keys/values pairs added into -serialize: method.
   @result A new deserialized object.
   */
- (id)initWithSerializedValues:(NSDictionary *)plist;

  /*!
  @method     check
   @abstract   Optional! Called just after a key were loaded.
   @discussion Subclasses should override this method to check if the action is valid.
   @result     Return nil if the action is valid and ready to be executed.
   */
- (SparkAlert *)check;

  /*!
  @method     execute
   @abstract   Required!
   @discussion Subclasses must overwrite this method.
   @result     <i>nil</i> if this SparkAction is executed whitout problem.
   */
- (SparkAlert *)execute;

  /*!
  @method     version
   @abstract   Returns the Action version. If nothing specified, use the class version.
   */
- (int)version;
  /*!
  @method     setVersion:
   @abstract   Sets the version for this Action.
   @param      newVersion Action version
   */
- (void)setVersion:(int)version;

  /*!
  @method     categorie
   @abstract   Returns the Action categorie.
   */
- (NSString *)categorie;
  /*!
  @method     setCategorie:
   @abstract   Sets the categorie for this Action.
   @param      categorie Action categorie.
   */
- (void)setCategorie:(NSString *)categorie;

  /*!
  @method
   @abstract   Returns the short Description for this Action.
   */
- (NSString *)actionDescription;
  /*!
  @method
   @abstract   Sets the short description for this Action.
   @param      desc The short description.
   */
- (void)setActionDescription:(NSString *)desc;

  /*!
  @method     repeatInterval
   @abstract   Returns the time interval between two events repetition.
   @result     0 to disable auto repeate, <em>SparkGetDefaultKeyRepeatInterval()</em> to use system defined repeat interval.
   */
- (NSTimeInterval)repeatInterval;

@end
