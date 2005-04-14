//
//  SparkListLibrary.h
//  Spark
//
//  Created by Fox on Mon Feb 09 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
#import <SparkKit/SparkKitBase.h>
#import <SparkKit/SparkObjectsLibrary.h>

@interface SparkListLibrary : SparkObjectsLibrary {
}

- (NSArray *)listsWithContentType:(Class)contentType;
- (NSArray *)listsWithName:(NSString *)name contentType:(Class)contentType;

@end

SPARK_EXPORT NSString* const kSparkLibraryDidAddListNotification;
SPARK_EXPORT NSString* const kSparkLibraryDidRemoveListNotification;