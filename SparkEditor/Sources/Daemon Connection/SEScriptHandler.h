/*
 *  SEScriptHandler.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import "Spark.h"

SK_PRIVATE
NSString * const SEServerStatusDidChangeNotification;

@interface SparkEditor (SEScriptHandler)

- (BOOL)isTrapping;
- (SparkDaemonStatus)serverStatus;
- (void)setServerStatus:(SparkDaemonStatus)theStatus;

- (void)handleHelpScriptCommand:(NSScriptCommand *)scriptCommand;

@end
