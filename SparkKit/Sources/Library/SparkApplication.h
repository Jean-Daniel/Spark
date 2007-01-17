/*
 *  SparkApplication.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
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

- (OSType)signature;
- (NSString *)bundleIdentifier;

- (SKApplication *)application;

@end
