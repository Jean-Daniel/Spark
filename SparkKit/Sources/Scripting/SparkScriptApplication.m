//
//  SparkScriptApplication.m
//  SparkKit
//
//  Created by Grayfox on 08/12/06.
//  Copyright 2006 Adamentium. All rights reserved.
//

#import <SparkKit/SparkLibrary.h>

@implementation NSApplication (SparkScriptApplication)

// plugins

- (SparkLibrary *)library {
  return SparkSharedLibrary();
}

@end
