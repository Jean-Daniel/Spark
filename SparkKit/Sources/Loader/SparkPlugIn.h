/*
 *  SparkPlugIn.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#import <SparkKit/SparkKit.h>

SPARK_EXPORT
NSString * const SparkPlugInDidChangeStatusNotification;

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
  NSString *sp_version;
  NSString *sp_identifier;
  
  struct _sp_spFlags {
    unsigned int disabled:1;
    unsigned int reserved:15;
  } sp_spFlags;
}

- (id)initWithBundle:(NSBundle *)bundle;

/* Designated */
- (id)initWithClass:(Class)cls identifier:(NSString *)identifier;

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

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

- (NSString *)version;
- (void)setVersion:(NSString *)version;

- (NSString *)identifier;
- (void)setIdentifier:(NSString *)anIdentifier;

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
;
@end
