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
@abstract   SparkAction is the class that represent action used in Spark.

@discussion Subclass must override methods:
<ul style="list-style:none">
<li>-initWithSerializedValues:</li>
<li>-serialize:</li>
<li>-actionDidLoad (optional)</li>
<li>-performAction</li>
</ul>
*/
SPARK_OBJC_EXPORT
@interface SparkAction : SparkObject <NSCopying, NSCoding>

+ (BOOL)currentEventIsARepeat;
+ (NSTimeInterval)currentEventTime;

/* Designated initializer */
- (instancetype)init;

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
- (instancetype)initWithSerializedValues:(NSDictionary *)plist;

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
   @discussion Subclasses must override this method.
   @result     Returns <i>nil</i> if this SparkAction is successfully executed.
   */
- (SparkAlert *)performAction;

/*! the receiver version. If nothing specified, use the class version. */
@property (nonatomic) NSUInteger version;

/*! Returns the receiver categorie. */
@property(nonatomic, readonly) NSString *category;

/*! Returns the receiver description. This description can be generated at load time. */
@property(nonatomic, copy) NSString *actionDescription;

#pragma mark -
#pragma mark Advanced
  /*!
  @property
   @abstract   Returns the time interval between two events repetition.
   @result     value <= 0 to disable auto repeate, <em>SparkGetDefaultKeyRepeatInterval()</em> to use system defined repeat interval.
   @discussion The default implementation returns 0. An action can override this method to enable auto-repeat.
   */
@property (nonatomic, readonly) NSTimeInterval repeatInterval;
@property (nonatomic, readonly) NSTimeInterval initialRepeatInterval;

@property (nonatomic, readonly) BOOL performOnKeyUp;

@property (nonatomic, readonly) BOOL needsToBeRunOnMainThread;
@property (nonatomic, readonly) BOOL supportsConcurrentRequests;

// return a object uses to determine if two actions can be executed concurrently.
@property (nonatomic, readonly) id lock;

@end
