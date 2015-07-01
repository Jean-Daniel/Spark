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

@interface SparkActionPlugIn ()

/* Some kind of hack to resolve binding cyclic memory problem.
 - releaseViewOwnership says to the receiver that it no longer need retain
 the view because something else retained it. So SparkActionPlugIn instance release
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
@interface SparkAction ()

- (id)duplicate;

/*!
 @abstract   Action's category.
 */
@property(nonatomic, copy) NSString *category;

@property(nonatomic, getter=isInvalid) BOOL invalid;

@property(nonatomic, readonly, getter=isPersistent) BOOL persistent;

@end

@interface SparkObject ()

/*!
 @abstract Don't call this method directly. This method is called by Library.
 */
@property (nonatomic, setter=setUID:) SparkUID uid;

/*!
 @abstract Receiver Library.
 Don't call setter method. It's called when receiver is added in a Library.
 */
@property (nonatomic, assign) SparkLibrary *library;

@end

@interface SparkLibrary (SparkLibraryApplication)
- (SparkApplication *)frontmostApplication;
- (SparkApplication *)applicationWithProcessIdentifier:(pid_t)pid;
@end

@interface SparkLibrary (SparkPreferences)

- (NSMutableDictionary *)preferences;
- (void)setPreferences:(NSDictionary *)preferences;

@end

#import <WonderBox/WBApplication.h>

@interface WBApplication (SparkSerialization)

- (BOOL)serialize:(NSMutableDictionary *)plist;
- (id)initWithSerializedValues:(NSDictionary *)plist;

@end
