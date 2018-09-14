//
//  SESparkDaemon.h
//  Spark
//
//  Created by Jean-Daniel on 25/11/2017.
//

#import <Foundation/Foundation.h>

@interface SESparkDaemon : NSObject

// shared instance
+ (nonnull SESparkDaemon *)sparkDaemon;

// Check if the user choosed to enable the SparkDaemon (which should install the Login Item)
@property (nonatomic, getter=isEnabled) BOOL enabled;

// Is the daemon running. If it is enabled, it should be running, unless something is wrong.
@property (nonatomic, getter=isRunning) BOOL runnning;

// Is the daemon active. See the SparkBuiltInAction for details.
@property (nonatomic, getter=isActive) BOOL active;

@end
