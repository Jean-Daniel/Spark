//
//  SparkApplicationLibrary.h
//  SparkKit
//
//  Created by Grayfox on 16/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SparkKit/SparkKitBase.h>
#import <SparkKit/SparkObjectsLibrary.h>

SPARK_EXPORT NSString* const kSparkLibraryDidAddApplicationNotification;
SPARK_EXPORT NSString* const kSparkLibraryDidUpdateApplicationNotification;
SPARK_EXPORT NSString* const kSparkLibraryDidRemoveApplicationNotification;

@class SparkApplication;
@interface SparkApplicationLibrary : SparkObjectsLibrary {

}
+ (SparkApplication *)systemApplication;

- (SparkApplication *)applicationForProcess:(ProcessSerialNumber *)psn;
- (SparkApplication *)applicationWithIdentifier:(NSString *)identifier;

@end

SPARK_EXTERN_INLINE SparkApplication* SparkSystemApplication();