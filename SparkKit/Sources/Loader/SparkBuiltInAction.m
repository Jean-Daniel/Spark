//
//  SparkBuiltInAction.m
//  SparkKit
//
//  Created by Grayfox on 06/11/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

#import <SparkKit/SparkBuiltInAction.h>

#import <ShadowKit/SKAppKitExtensions.h>

@implementation SparkBuiltInActionPlugin

+ (Class)actionClass {
  return [SparkBuiltInAction class];
}

+ (NSString *)plugInName {
  return @"Spark";
}

+ (NSImage *)plugInIcon {
  return [NSImage imageNamed:@"spark" inBundle:SKCurrentBundle()];
}

+ (NSString *)helpFile {
  return nil;
}

+ (NSString *)nibPath {
  return [SKCurrentBundle() pathForResource:@"SparkPlugin" ofType:@"nib"];
}

/* default status */
+ (BOOL)isEnabled {
  return NO;
}

+ (NSString *)identifier {
  return @"org.shadowlab.spark.plugin.spark";
}

/* Returns the version string */
+ (NSString *)versionString {
  return @"1.0";
}

@end

@implementation SparkBuiltInAction

@end

