/*
 *  SEScriptHandler.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "Spark.h"

@interface SparkEditor (SEScriptHandler)

- (BOOL)isTrapping;

- (void)handleHelpScriptCommand:(NSScriptCommand *)scriptCommand;

@end
