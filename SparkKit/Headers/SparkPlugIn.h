//
//  PlugIns.h
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
#import <Foundation/Foundation.h>

/*!
    @class 		SparkPlugIn
    @abstract   Represent a Spark Plugin Bundle.
*/
@interface SparkPlugIn : NSObject {
  NSString *_name;
  NSString *_path;
  NSImage  *_icon;
  NSString *_bundleId;
  Class    _plugInClass;
}

- (id)initWithBundle:(NSBundle *)bundle;
- (id)initWithName:(NSString *)name icon:(NSImage *)icon class:(Class)class;

+ (id)plugInWithBundle:(NSBundle *)bundle;
+ (id)plugInWithName:(NSString *)name icon:(NSImage *)icon class:(Class)class;

/*!
    @method     name
    @abstract   Returns the localized name of this Plugin.
*/
- (NSString *)name;
/*!
    @method     setName:
    @abstract   Sets the name of this plugin.
    @param      name The name to set.
*/
- (void)setName:(NSString *)name;

/*!
    @method     path
    @abstract   Returns the path for this plugin Bundle.
*/
- (NSString *)path;
/*!
    @method     setPath:
    @abstract   Sets the path for this plugin.
    @param      path The path to set.
*/
- (void)setPath:(NSString *)path;

/*!
    @method     icon
    @abstract   Returns the icon for this plugin.
*/
- (NSImage *)icon;
- (void)setIcon:(NSImage *)newIcon;

- (NSString *)bundleIdentifier;
- (void)setBundleIdentifier:(NSString *)anIdentifier;
/*!
    @method     principalClass
    @abstract   Returns the plugin principal class.
*/
- (Class)principalClass;

/*!
    @method     actionClass
    @abstract   Return the Action Class provided by this plugin.
*/
- (Class)actionClass;
@end
