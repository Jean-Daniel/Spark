//
//  SparkKeyLibrary.h
//  Spark
//
//  Created by Fox on Mon Feb 09 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKitBase.h>
#import <SparkKit/SparkObjectsLibrary.h>

@class SparkHotKey, SparkAction, SparkApplication, SparkApplicationList;
@interface SparkKeyLibrary : SparkObjectsLibrary {
}

//+ (SparkKeyLibrary *)sharedLibrary;

- (NSArray *)keysWithKeycode:(unsigned short)keycode modifier:(int)modifier;
- (SparkHotKey *)activeKeyWithKeycode:(unsigned short)keycode modifier:(int)modifier;

- (NSSet *)keysUsingAction:(SparkAction *)action;
- (NSSet *)keysUsingActions:(NSSet *)actionsUids;
- (NSSet *)keysUsingApplication:(SparkApplication *)application;
- (NSSet *)keysUsingApplications:(NSSet *)applicationsUids;
- (NSSet *)keysUsingApplicationList:(SparkApplicationList *)list;
- (NSSet *)keysUsingApplicationLists:(NSSet *)listsUids;
@end

SPARK_EXPORT NSString* const kSparkLibraryDidAddKeyNotification;
SPARK_EXPORT NSString* const kSparkLibraryDidUpdateKeyNotification;
SPARK_EXPORT NSString* const kSparkLibraryDidRemoveKeyNotification;