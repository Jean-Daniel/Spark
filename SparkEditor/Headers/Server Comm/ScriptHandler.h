//
//  ScriptHandler.h
//  Short-Cut
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "Spark.h"

extern NSString* const kSPServerStatChangeNotification;

@interface Spark (AppleScriptExtension)

- (DaemonStatus)serverState;
- (void)setServerState:(DaemonStatus)state;

@end
