/*
 *  SparkPlugIn.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

/*!
    @class 		SparkPlugIn
    @abstract   Represent a Spark Plugin Bundle.
*/
@interface SparkPlugIn : NSObject {
  @private
  Class sp_class;
  NSNib *sp_nib;
  NSString *sp_name;
  NSString *sp_path;
  NSImage  *sp_icon;
  NSString *sp_bundle;
}

- (id)initWithBundle:(NSBundle *)bundle;

+ (id)plugInWithBundle:(NSBundle *)bundle;

/*!
  @method
 @abstract   Returns the localized name of this Plugin.
*/
- (NSString *)name;
/*!
  @method
 @abstract   Sets the name of this plugin.
 @param      name The name to set.
*/
- (void)setName:(NSString *)name;

/*!
  @method
 @abstract   Returns the path for this plugin Bundle.
*/
- (NSString *)path;
/*!
  @method
 @abstract   Sets the path for this plugin.
 @param      path The path to set.
*/
- (void)setPath:(NSString *)path;

/*!
  @method
 @abstract   Returns the icon for this plugin.
*/
- (NSImage *)icon;
- (void)setIcon:(NSImage *)newIcon;

- (NSString *)bundleIdentifier;
- (void)setBundleIdentifier:(NSString *)anIdentifier;

- (NSURL *)helpURL;

/*!
  @method
 @abstract Returns the Action Class provided by this plugin.
*/
- (Class)actionClass;
/*!
  @method
 @abstract Returns a new plugin instance.
*/
- (id)instantiatePlugin;

@end

@interface SparkPlugIn (SparkBuiltInPlugIn)
- (id)initWithClass:(Class)cls;
@end
