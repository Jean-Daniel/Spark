//
//  SEScriptHandler.h
//  Short-Cut
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "Spark.h"

SK_PRIVATE
NSString * const SEServerStatusDidChangeNotification;

@interface SparkEditor (SEScriptHandler)

- (BOOL)isTrapping;
- (SparkDaemonStatus)serverStatus;
- (void)setServerStatus:(SparkDaemonStatus)theStatus;

- (void)handleHelpScriptCommand:(NSScriptCommand *)scriptCommand;

@end
