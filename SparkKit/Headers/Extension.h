//
//  Extension.h
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SparkKit/SparkAlert.h>

void SparkLaunchEditor();
void SparkDisplayAlerts(NSArray *items);

@interface NSString (Spark_Extension)

- (NSString *)stringByTrimmingWhitespaceAndNewline;

@end
