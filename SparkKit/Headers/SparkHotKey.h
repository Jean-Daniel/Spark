/*
 *  HotKey.h
 *  Short-Cut
 *
 *  Created by Fox on Sat Nov 29 2003.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 */

/*!
	@header 	SparkHotKey
	@abstract   Define a HotKey.
 */

#import <SparkKit/SparkKitBase.h>
#import <SparkKit/SparkLibraryObject.h>

typedef enum {
  kSparkDisableAllSingleKey,
  kSparkEnableSingleFunctionKey,
  kSparkEnableAllSingleKey,
} SparkFilterMode;

SPARK_EXPORT
SparkFilterMode SparkKeyStrokeFilterMode;

@class HKHotKey, SparkAction, SparkAlert, SparkApplication, SparkApplicationList, SparkApplicationToActionMap;
#pragma mark -
/*!
    @class 		SparkHotKey
    @abstract   SparkHotKey is the class that represent hotKeys used in Spark.
*/
@interface SparkHotKey : SparkLibraryObject <NSCopying, SparkSerialization> {
@private
  id _target;
  SEL _action;
  BOOL _active; 
  HKHotKey *_hotkey;
  NSString *_comment;
  SparkApplicationToActionMap *_actions;
}

#pragma mark -
#pragma mark Convenients Constructors.
/*!
	@method     hotKey
	@abstract   A new created SparkHotKey.
 */
+ (id)hotKey;

/*!
	@method     hotKeyWithName:
	@abstract   Create a new SparkHotKey with an new uniq ID.
 	@param		name The name of the new SparkHotKey.
 	@result		A new created SparkHotKey.
 */
+ (id)hotKeyWithName:(NSString *)name;

/*!
    @method     hotKeyFromPropertyList:
	@abstract   (description)
	@param      plist A dictionary containing every keys/values you added into propertyList method.
	@result     A deserialized HotKey.
 */
+ (id)hotKeyFromPropertyList:(id)plist;

#pragma mark Methods from Superclass
- (id)init;

/*!
	@method     initFromPropertyList:
	@abstract   Required! Subclasses must always call parent method.
 	@param      plist A dictionary containing every keys/values you added into <i>-propertyList</i> method.
	@result     A deserialized HotKey.
*/
- (id)initFromPropertyList:(NSDictionary *)plist;

/*!
    @method     propertyList
    @abstract   Required! Serialization method. This method must always call super method before adding its own value.
    @discussion This method convert an hotKey into serializable representation so you must only add PropertyList Objects
 				into the return Dictionary.
    @result     A propertyList representation for this HotKey.
*/
- (NSMutableDictionary *)propertyList;

#pragma mark Accessors
- (BOOL)isActive;
- (void)setActive:(BOOL)flag;

/*!
	@method     comment
	@abstract   Returns the comment for this Action.
 */
- (NSString *)comment;
/*!
	@method     setComment:
	@abstract   Sets the comment for this Action.
	@param      aComment A comment.
 */
- (void)setComment:(NSString *)aComment;

/*!
    @method     isInvalid
    @abstract   (brief description)
    @result     Returns NO if receiver is valid and all this actions are valid too.
*/
- (BOOL)isInvalid;

@end

#pragma mark -
@interface SparkHotKey (MutlipleActionsSupport)

- (SparkAlert *)execute;
- (SparkAction *)currentAction;

- (SparkAction *)defaultAction;
- (void)setDefaultAction:(SparkAction *)anAction;

- (void)setAction:(SparkAction *)anAction forApplication:(SparkApplication *)application;
- (void)setAction:(SparkAction *)anAction forApplicationList:(SparkApplicationList *)list;

- (BOOL)hasManyActions;
- (void)removeAllActions;

- (SparkApplicationToActionMap *)map;

- (NSSet *)listsUids;
- (NSSet *)actionsUids;
- (NSSet *)applicationsUids;

#pragma mark UID Update
- (void)updateListUid:(NSArray *)uids;
- (void)updateActionUid:(NSArray *)uids;
- (void)updateApplicationUid:(NSArray *)uids;

@end

#pragma mark -
@interface SparkHotKey (Forwarding)

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
+ (NSMethodSignature *)instanceMethodSignatureForSelector:(SEL)aSelector;

- (void)forwardInvocation:(NSInvocation *)anInvocation;

- (BOOL)respondsToSelector:(SEL)aSelector;
+ (BOOL)instancesRespondToSelector:(SEL)aSelector;

- (BOOL)isKindOfClass:(Class)aClass;
+ (BOOL)isSubclassOfClass:(Class)aClass;

- (id)valueForUndefinedKey:(NSString *)key;

@end

#pragma mark -
@interface SparkHotKey (HKHotKeyForwarding)

- (BOOL)isValid;

- (id)target;
- (void)setTarget:(id)anObject;

- (SEL)action;
- (void)setAction:(SEL)aSelector;

- (unsigned int)modifier;
- (void)setModifier:(unsigned int)modifier;

- (unsigned short)keycode; 
- (void)setKeycode:(unsigned short)keycode;

- (unichar)character;
- (void)setCharacter:(unichar)character;

- (void)setKeycode:(unsigned short)keycode andCharacter:(unichar)character;

- (BOOL)isRegistred;
- (BOOL)setRegistred:(BOOL)flag;

- (NSTimeInterval)keyRepeat;
- (void)setKeyRepeat:(NSTimeInterval)interval;

- (NSString *)shortCut;

- (AXError)sendHotKeyToApplicationWithSignature:(OSType)sign bundleId:(NSString *)bundleId;

@end

#pragma mark -
@interface SparkApplicationToActionMap : NSObject <SparkSerialization> {
  SparkLibrary *_library;
  NSMutableDictionary *_listMap;
  NSMutableDictionary *_simpleMap;
}

- (unsigned)count;

- (NSSet *)actions;
- (NSSet *)actionsUids;
- (NSSet *)applications;
- (NSSet *)applicationsUids;
- (NSSet *)lists;
- (NSSet *)listsUids;

- (SparkAction *)actionForFrontProcess;
/*!
    @method     actionForApplication:
    @abstract   Method use to determine what action use for a specified Application.
 				This method looks into all applications, and then, if no one correspond, it looks into lists.
    @param      application An application.
    @result     An action bound to a specified application, or to a list containing this application.
*/
- (SparkAction *)actionForApplication:(SparkApplication *)application;

- (SparkAction *)actionForEntry:(id)entry;

- (void)setAction:(SparkAction *)anAction forApplication:(SparkApplication *)application;
- (void)setAction:(SparkAction *)anAction forApplicationList:(SparkApplicationList *)list;

- (void)removeAllActions;
- (void)removeAction:(SparkAction *)action;
- (void)removeApplication:(SparkApplication *)application;
- (void)removeApplicationList:(SparkApplicationList *)list;

- (SparkLibrary *)library;
- (void)setLibrary:(SparkLibrary *)aLibrary;

#pragma mark UID Update
- (void)updateListUid:(id)uid newUid:(id)newUid;
- (void)updateActionUid:(id)uid newUid:(id)newUid;
- (void)updateApplicationUid:(id)uid newUid:(id)newUid;

@end