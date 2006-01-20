//
//  SparkAction.h
//  SparkKit
//
//  Created by Fox on 31/08/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

/*!
    @header SparkAction
 	@abstract SparkAction Declaration.
*/

#import <SparkKit/SparkKitBase.h>
#import <SparkKit/SparkLibraryObject.h>

@class SparkAlert;

SPARK_EXPORT
const int kSparkActionVersion_1_0;
#define kSparkActionCurrentVersion	kSparkActionVersion_1_0;

/*!
	@function	SparkGetDefaultKeyRepeatInterval
 	@abstract	Returns the system default time interval for repeat keys.
 				This default time can be changed by the user in «System Preferences».
 	@result		Returns the system default time interval for repeat keys.
 */
SPARK_EXTERN_INLINE
NSTimeInterval SparkGetDefaultKeyRepeatInterval();

/*!
	@class 		SparkAction
	@abstract   SparkAction is the class that represent action used in Spark.

	@discussion Subclass must override methods:
		<ul style="list-style:none">
			<li>-initFromPropertyList:</li>
			<li>-propertyList</li>
			<li>-check (optional)</li>
			<li>-execute</li>
		<ul>
*/
@interface SparkAction : SparkLibraryObject <NSCopying, NSCoding, SparkSerialization> {
  @private
  int sk_version;
  struct _sk_saflags {
    unsigned int invalid:1;
    unsigned int custom:1;
    unsigned int :14; /* Use two BOOL before so 14 to keep binary compatibility */
  } sk_saflags;
  NSString *sk_categorie, *sk_shortDesc;
}

/*!
	@method     initFromPropertyList:
	@abstract   Required! Subclasses must always call parent method.
	@param      plist A dictionary containing every keys/values you added into <i>-propertyList</i> method.
	@result     A deserialized <i>SparkAction</i>.
 */
- (id)initFromPropertyList:(NSDictionary *)plist;

/*!
	@method     propertyList
	@abstract   Required! Serialization method. This method must always call super method before adding its own value.
	@discussion This method convert an action into serializable representation so you must only add PropertyList Objects
				into the return Dictionary.
	@result     A propertyList representation for this Action.
 */
- (NSMutableDictionary *)propertyList;

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
	@method     shortDescription
	@abstract   Returns the short Description for this Action.
 */
- (NSString *)shortDescription;
/*!
	@method     setShortDescription:
	@abstract   Sets the short description for this Action.
	@param      desc The short description.
 */
- (void)setShortDescription:(NSString *)desc;

/*!
    @method     repeatInterval
    @abstract   Returns the time interval between two events repetition.
    @result     0 to disable auto repeate, <em>SparkGetDefaultKeyRepeatInterval()</em> to use system defined repeat interval.
*/
- (NSTimeInterval)repeatInterval;

@end
