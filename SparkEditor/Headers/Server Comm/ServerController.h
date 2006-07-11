//
//  ServerController.h
//  Spark
//
//  Created by Fox on Sun Dec 14 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SEScriptHandler.h"

extern NSString * const kSparkListDidChangeNotification;
extern NSString * const kSparkActionDidChangeNotification;
extern NSString * const kSparkHotKeyDidChangeNotification;
extern NSString * const kSparkApplicationDidChangeNotification;

extern NSString * const kSparkHotKeyStateDidChangeNotification;

@interface ServerController : NSObject {

}

+ (ServerController *)sharedController;

- (void)checkRunningDaemon;
- (void)registerNotification;

+ (void)start;
+ (DaemonStatus)serverState;

- (id)serverProxy;
- (void)startServer;
- (void)shutDownServer;

@end
