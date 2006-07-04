//
//  Extension.m
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/Extension.h>

/* String Extension */
@implementation NSString (Spark_Extension)

- (NSString *)stringByTrimmingWhitespaceAndNewline {
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
