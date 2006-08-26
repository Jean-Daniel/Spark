/*
 *  SparkApplication.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkObject.h>

@class SKApplication;
@interface SparkApplication : SparkObject {
  @private
  SKApplication *sp_application;
}

- (id)initWithPath:(NSString *)path;

- (NSString *)path;
- (void)setPath:(NSString *)path;

//- (NSString *)identifier;

- (OSType)signature;
//- (void)setSignature:(NSString *)signature;
- (NSString *)bundleIdentifier;
//- (void)setBundleIdentifier:(NSString *)identifier;

@end
