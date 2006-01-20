//
//  SparkActionLibrary.h
//  SparkKit
//
//  Created by Fox on 01/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKitBase.h>
#import <SparkKit/SparkObjectsLibrary.h>

@class SparkAction;
@interface SparkActionLibrary : SparkObjectsLibrary {

}
+ (SparkAction *)ignoreAction;

//+ (SparkActionLibrary *)sharedLibrary;

- (NSArray *)customActions;

@end

SPARK_EXPORT NSString* const kSparkLibraryDidAddActionNotification;
SPARK_EXPORT NSString* const kSparkLibraryDidUpdateActionNotification;
SPARK_EXPORT NSString* const kSparkLibraryDidRemoveActionNotification;

SPARK_EXTERN_INLINE SparkAction* SparkIgnoreAction();
