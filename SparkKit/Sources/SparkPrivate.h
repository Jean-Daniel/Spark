/*
 *  SparkPrivate.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkActionPlugIn.h>

@interface SparkActionPlugIn (Private)

/* Some kind of hack to resolve binding cyclic memory problem. 
- releaseViewOwnership says to the receiver that it no longer need retain
  the view because something else retained it. So SparkActionPlugin instance release
  the view and breaks the retain cycle. */
- (void)releaseViewOwnership;
- (void)setHotKeyTrap:(NSView *)trap;
- (void)setSparkAction:(SparkAction *)anAction edit:(BOOL)flag;

/* Built-in plugin support */

/* Returns default value */
+ (BOOL)isEnabled;

+ (NSString *)identifier;

/* Returns the version string */
+ (NSString *)versionString;

@end

@class SparkHotKey, SparkTrigger;
@interface SparkAction (Private)

+ (void)setCurrentTrigger:(SparkTrigger *)aTrigger;

- (id)duplicate;

- (BOOL)isInvalid;
- (void)setInvalid:(BOOL)flag;

- (BOOL)isPersistent;

  /*!
  @method     setCategorie:
   @abstract   Sets the categorie for this Action.
   @param      categorie Action categorie.
   */
- (void)setCategorie:(NSString *)categorie;

- (SparkAlert *)hotKeyShouldExecuteAction:(SparkHotKey *)hotkey;

@end

@interface SparkObject (Private)
/*!
@method
 @abstract Don't call this method directly. This method is called by Library.
 @param uid (description)
 */
- (void)setUID:(SparkUID)uid;
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

@interface SparkLibrary (SparkLibraryApplication)
- (SparkApplication *)frontApplication;
- (SparkApplication *)applicationForProcess:(ProcessSerialNumber *)psn;
@end

@interface SparkLibrary (SparkPreferences)

- (NSMutableDictionary *)preferences;
- (void)setPreferences:(NSDictionary *)preferences;

@end

#import WBHEADER(WBApplication.h)
#import WBHEADER(WBAliasedApplication.h)

@interface WBApplication (SparkSerialization)

- (BOOL)serialize:(NSMutableDictionary *)plist;
- (id)initWithSerializedValues:(NSDictionary *)plist;

@end

@interface WBAliasedApplication (SparkSerialization)

- (BOOL)serialize:(NSMutableDictionary *)plist;
- (id)initWithSerializedValues:(NSDictionary *)plist;

@end
