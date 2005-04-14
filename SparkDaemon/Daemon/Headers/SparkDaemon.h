//
//  ServerController.h
//  Spark
//
//  Created by Fox on Thu Dec 11 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SparkServerProtocol.h"
#import <HotKeyToolKit/HotKeyToolKit.h>

@class SparkHotKey, SparkKeyLibrary, SparkActionLibrary;

@interface SparkDaemon : NSObject {
}

- (BOOL)setPlugInPath;

- (void)loadKeys;
- (void)checkActions;

- (void)addKey:(SparkHotKey *)key;
- (void)updateKey:(SparkHotKey *)key;
- (void)removeKey:(SparkHotKey *)key;

- (BOOL)connect;
- (void)run;
- (void)terminate;

@end

@interface SparkDaemon (SparkServerProtocol) <SparkServer>

- (void)shutDown;

- (void)addList:(id)plist;
- (void)updateList:(id)plist;
- (void)removeList:(unsigned)uid;

- (void)addAction:(id)plist;
- (void)updateAction:(id)plist;
- (void)removeAction:(unsigned)uid;

- (void)addApplication:(id)plist;
- (void)updateApplication:(id)plist;
- (void)removeApplication:(unsigned)uid;

- (void)addHotKey:(id)plist;
- (void)updateHotKey:(id)plist;
- (void)removeHotKey:(unsigned)uid;
- (BOOL)setActive:(BOOL)flag forHotKey:(unsigned)keyUid;

@end
