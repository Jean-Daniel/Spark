/*
 *  SparkApplication.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkObject.h>

SPARK_OBJC_EXPORT
@interface SparkApplication : SparkObject

+ (SparkApplication *)systemApplication;

- (instancetype)initWithURL:(NSURL *)anURL;

@property(nonatomic, retain) NSURL *URL;

@property(nonatomic, readonly) NSString *bundleIdentifier;

@property(nonatomic, getter=isEnabled) BOOL enabled;

@property(nonatomic, readonly, getter=isEditable) BOOL editable;

@end

SPARK_EXPORT
NSString * const SparkApplicationDidChangeEnabledNotification;
