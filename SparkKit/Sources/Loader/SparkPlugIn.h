/*
 *  SparkPlugIn.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkKit.h>

SPARK_EXPORT
NSString * const SparkPlugInDidChangeStatusNotification;

@class SparkActionPlugIn;

/*!
    @abstract   Represent a Spark PlugIn Bundle.
*/
SPARK_OBJC_EXPORT
@interface SparkPlugIn : NSObject

- (instancetype)initWithBundle:(NSBundle *)bundle;

/* Designated */
- (instancetype)initWithClass:(Class)cls identifier:(NSString *)identifier NS_DESIGNATED_INITIALIZER;

/*! localized name of this PlugIn. */
@property(nonatomic, copy) NSString *name;

/*! plugin bundle URL. */
@property(nonatomic, retain) NSURL *URL;

/*! the icon for this plugin */
@property(nonatomic, copy) NSImage *icon;

@property(nonatomic, getter=isEnabled) BOOL enabled;

@property(nonatomic, copy) NSString *version;
@property(nonatomic, copy) NSString *identifier;

@property(nonatomic, readonly) NSURL *helpURL;
@property(nonatomic, readonly) NSURL *sdefURL;


@property(nonatomic, readonly) Class plugInClass;
/*! Action Class provided by this plugin. */
@property(nonatomic, readonly) Class actionClass;

/*!
  @method
 @abstract Returns a new plugin instance.
*/
- (__kindof SparkActionPlugIn *)instantiatePlugIn;

@end
