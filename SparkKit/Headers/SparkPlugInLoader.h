//
//  SparkPlugInLoader.h
//  Spark
//
//  Created by Fox on Fri Dec 12 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKitBase.h>

SPARK_EXPORT NSString * const kSparkDidAddPlugInNotification;
SPARK_EXPORT NSString * const kSparkDidRemovePlugInNotification;

#warning Should extends SKPluginLoader
@interface SparkPlugInLoader : NSObject {
  id sk_plugIns;
  
  FNSubscriptionRef refs[4];
}

+ (id)sharedLoader;
+ (NSString *)buildInPath;
+ (void)setBuildInPath:(NSString *)newPath;

#pragma mark -
- (id)init;

#pragma mark -
+ (NSString *)extension;
+ (NSArray *)plugInPaths;
- (NSString *)extension;

#pragma mark -
- (NSArray *)plugIns;
- (id)plugInForClass:(Class)class;

#pragma mark -
#pragma mark Plugin Loader
- (void)discoverPlugIns;
- (NSDictionary *)plugInsAtPath:(NSString *)path;
- (id)loadPlugInBundle:(NSBundle *)bundle;

#pragma mark -
#pragma mark Plugin Folder Observer
- (void)subscribeFileNotification;
- (void)subscribeForPath:(NSString *)path;
- (void)unsubscribeAll;

- (void)plugInFolderChanged:(NSString *)folder;

@end
