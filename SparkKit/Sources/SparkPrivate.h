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

- (BOOL)isPermanent;

  /*!
  @method     setCategorie:
   @abstract   Sets the categorie for this Action.
   @param      categorie Action categorie.
   */
- (void)setCategorie:(NSString *)categorie;

- (SparkAlert *)hotKeyShouldExecuteAction:(SparkHotKey *)hotkey;

@end

@interface SparkLibrary (SparkLibraryPrivate)
- (SparkApplication *)frontApplication;
@end

@interface SparkLibrary (SparkPreferences)

- (NSMutableDictionary *)preferences;
- (void)setPreferences:(NSDictionary *)preferences;

@end
