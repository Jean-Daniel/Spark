//
//  ServerProtocol.m
//  Spark Server
//
//  Created by Fox on Tue Jan 20 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "SparkDaemon.h"

#import <SparkKit/SparkTrigger.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectSet.h>

@implementation SparkDaemon (SparkServerProtocol)

//- (void)addObject:(id)plist intoLibrary:(SparkObjectsLibrary *)library {
//  NSParameterAssert(plist != nil);
//  NSParameterAssert(library != nil);
//  @try {
//    id object = nil;
//    if (object = SparkDeserializeObject(plist)) {
//      [library addObject:object];
//    } else {
//      DLog(@"Error while deserializing object: %@", plist);
//    }
//  }
//  @catch (id exception) {
//    SKLogException(exception);
//  }  
//}
//- (void)updateObject:(id)plist intoLibrary:(SparkObjectsLibrary *)library {
//  NSParameterAssert(plist != nil);
//  NSParameterAssert(library != nil);
//  @try {
//    id object;
//    if (object = SparkDeserializeObject(plist)) {
//      [library updateObject:object];
//    } else {
//      DLog(@"Error while deserializing object: %@", plist);
//    }
//  }
//  @catch (id exception) {
//    SKLogException(exception);
//  }
//}
//- (void)removeObjectWithUid:(unsigned)uid fromLibrary:(SparkObjectsLibrary *)library {
//  NSParameterAssert(library != nil);
//  @try {
//    id object;
//    if (object = [library objectWithId:SKUInt(uid)]) {
//      [library removeObject:object];
//    }
//  }
//  @catch (id exception) {
//    SKLogException(exception);
//  }
//}

//#pragma mark List
//- (void)addList:(id)plist {
//  ShadowTrace();
//  [self addObject:plist intoLibrary:SparkDefaultListLibrary()];
//}
//- (void)updateList:(id)plist {
//  ShadowTrace();
//  [self updateObject:plist intoLibrary:SparkDefaultListLibrary()];
//}
//- (void)removeList:(unsigned)uid {
//  ShadowTrace();
//  [self removeObjectWithUid:uid fromLibrary:SparkDefaultListLibrary()];
//}
//
//#pragma mark Action
//- (void)addAction:(id)plist {
//  ShadowTrace();
//  [self addObject:plist intoLibrary:SparkDefaultActionLibrary()];
//}
//- (void)updateAction:(id)plist {
//  ShadowTrace();
//  [self updateObject:plist intoLibrary:SparkDefaultActionLibrary()];
//}
//- (void)removeAction:(unsigned)uid {
//  ShadowTrace();
//  [self removeObjectWithUid:uid fromLibrary:SparkDefaultActionLibrary()];
//}
//
//#pragma mark Application
//- (void)addApplication:(id)plist {
//  ShadowTrace();
//  [self addObject:plist intoLibrary:SparkDefaultApplicationLibrary()];
//}
//- (void)updateApplication:(id)plist {
//  ShadowTrace();
//  [self updateObject:plist intoLibrary:SparkDefaultApplicationLibrary()];
//}
//- (void)removeApplication:(unsigned)uid {
//  ShadowTrace();
//  [self removeObjectWithUid:uid fromLibrary:SparkDefaultApplicationLibrary()];
//}

//#pragma mark HotKey
//- (void)addHotKey:(id)plist {
//  ShadowTrace();
//  @try {
//    id key = SparkDeserializeObject(plist);
//    if (nil != key) {
//      [self addKey:key];
//    } else {
//      DLog(@"Unable to load key: %@", plist);
//    }
//  }
//  @catch (id exception) {
//    SKLogException(exception);
//  }
//}
//- (void)updateHotKey:(id)plist {
//  ShadowTrace();
//  @try {
//    id key = SparkDeserializeObject(plist);
//    if (nil != key) {
//      [self updateKey:key];
//    } else {
//      DLog(@"Unable to load object: %@", plist);
//    }
//  }
//  @catch (id exception) {
//    SKLogException(exception);
//  }
//}
//- (void)removeHotKey:(unsigned)keyUid {
//  ShadowTrace();
//  @try {
//    id key;
//    if (key = [SparkDefaultKeyLibrary() objectWithId:SKUInt(keyUid)]) {
//      [self removeKey:key];
//    }
//  }
//  @catch (id exception) {
//    SKLogException(exception);
//  }
//}

//- (BOOL)setActive:(BOOL)flag forHotKey:(UInt32)keyUid {
//  ShadowTrace();
//  @try {
//    id key;
//    if (key = [SparkSharedTriggerLibrary() objectWithUID:keyUid]) {
//      BOOL result = [key setRegistred:flag];
//      return result;
//    }
//  }
//  @catch (id exception) {
//    SKLogException(exception);
//  }
//  return NO;
//}

- (void)updateTrigger:(UInt32)uid enabled:(BOOL)flag {
  @try {
    SparkTrigger *trigger;
    if ((trigger = [SparkSharedTriggerSet() objectForUID:uid]) && XOR(flag, [trigger isEnabled])) {
      [trigger setEnabled:flag];
      [trigger setRegistred:flag];
    }
  } @catch (id exception) {
    SKLogException(exception);
  }
}

#pragma mark -
#pragma mark Shutdown
- (void)shutdown {
  ShadowTrace();
  [self terminate];
}

#pragma mark Trigger Status
- (void)enableTrigger:(UInt32)uid {
  ShadowTrace();
  [self updateTrigger:uid enabled:YES];
}

- (void)disableTrigger:(UInt32)uid {
  ShadowTrace();
  [self updateTrigger:uid enabled:NO];
}

#pragma mark Entries Management
- (void)addEntry:(SparkEntry *)entry {
}
- (void)removeEntryAtIndex:(UInt32)idx {
}

#pragma mark Objects Management
- (void)addObject:(id)plist type:(OSType)type {
}
- (void)updateObject:(id)plist type:(OSType)type {
}
- (void)removeObject:(UInt32)uid type:(OSType)type {
}

@end
