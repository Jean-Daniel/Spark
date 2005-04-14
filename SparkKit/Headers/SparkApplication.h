//
//  SparkApplication.h
//  SparkKit
//
//  Created by Grayfox on 16/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SparkKit/SparkLibraryObject.h>

@class SKApplication;
@interface SparkApplication : SparkLibraryObject <SparkSerialization> {
  SKApplication *_application;
}

- (id)initWithPath:(NSString *)path;

- (NSString *)path;
- (void)setPath:(NSString *)path;

- (NSString *)identifier;

- (NSString *)signature;
- (void)setSignature:(NSString *)signature;
- (NSString *)bundleIdentifier;
- (void)setBundleIdentifier:(NSString *)identifier;

@end

@interface _SparkSystemApplication : SparkApplication {
}
+ (id)application;
@end