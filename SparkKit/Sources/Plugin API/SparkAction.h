/*
 *  SparkAction.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */
/*!
@header SparkAction
 @abstract SparkAction Declaration.
 */

#import <SparkKit/SparkObject.h>

@class SparkAlert;

/*!
@function
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
<li>-actionDidLoad (optional)</li>
<li>-performAction</li>
<ul>
*/
SPARK_CLASS_EXPORT
@interface SparkAction : SparkObject <NSCopying, NSCoding> {
  @private
  UInt32 sp_version;
  struct _sp_saFlags {
    unsigned int invalid:1;
    unsigned int registred:1;
    unsigned int :14;
  } sp_saFlags;
  NSString *sp_categorie, *sp_description;
}

+ (BOOL)currentEventIsARepeat;
+ (NSTimeInterval)currentEventTime;

/* Designated initializer */
- (id)init;

  /* Load common properties from an other action */
- (void)setPropertiesFromAction:(SparkAction *)anAction;

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
  @method
   @abstract   Optional! Called when action are loaded.
   @discussion Subclasses should override this method to check if the action is valid.
   @result     Return <i>nil</i> if the action is valid.
   */
- (SparkAlert *)actionDidLoad;

  /*!
  @method
   @abstract   Required!
   @discussion Subclasses must overwrite this method.
   @result     Returns <i>nil</i> if this SparkAction is successfully executed.
   */
- (SparkAlert *)performAction;

  /*!
  @method
   @abstract   Returns the receiver version. If nothing specified, use the class version.
   */
- (UInt32)version;
  /*!
  @method
   @abstract   Sets the receiver version.
   @param      version Action version
   @discussion The version is automatically saved and restored.
   */
- (void)setVersion:(UInt32)version;

  /*!
  @method
   @abstract   Returns the receiver categorie.
   */
- (NSString *)categorie;

  /*!
  @method
   @abstract   Returns the receiver description.
   @discussion This description can be generated at load time.
   */
- (NSString *)actionDescription;
  /*!
  @method
   @abstract   Sets the receivers description.
   @param      desc A short description that explains what this action will do.
   */
- (void)setActionDescription:(NSString *)desc;

#pragma mark -
#pragma mark Advanced
  /*!
  @method
   @abstract   Returns the time interval between two events repetition.
   @result     value <= 0 to disable auto repeate, <em>SparkGetDefaultKeyRepeatInterval()</em> to use system defined repeat interval.
   @discussion The default implementation returns -1. An action can override this method to enable auto-repeat.
   */
- (NSTimeInterval)repeatInterval;

#pragma mark Unstable
/* return YES if this action is enabled for the current front application */
- (BOOL)isActive;
- (BOOL)isRegistred;

/*!
  @method
 @abstract You should not call this method directly.
 @discussion Subclasses can override this method to be notified about registration status change.
 Subclasses should call super in their implementation
*/
- (void)setRegistred:(BOOL)flag;

@end
