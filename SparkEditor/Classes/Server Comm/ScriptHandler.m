//
//  ScriptHandler.m
//  Short-Cut
//
//  Created by Fox on Wed Dec 10 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "ScriptHandler.h"
#import "ServerController.h"
#import <SparkKit/SparkKit.h>

NSString* const kSPServerStatChangeNotification = @"Server State Change";

@implementation Spark (AppleScriptExtension)

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
  return [key isEqualToString:@"serverState"]
  || [key isEqualToString:@"trapping"];
//    || [key isEqualToString:@"hotKeys"]
//    || [key isEqualToString:@"keyLists"];
}

- (NSString *)sparkDaemonMenu {
  if (kSparkDaemonStarted == serverState) {
    return NSLocalizedString(@"DEACTIVE_SPARK_MENU",
                             @"Spark Daemon Menu Title * Desactive *");
  } else {
    return NSLocalizedString(@"ACTIVE_SPARK_MENU",
                             @"Spark Daemon Menu Title * Active *");
  }
}
- (void)setSparkDaemonMenu:(NSString *)newSparkDaemonMenu {}

- (DaemonStatus)serverState {
  return serverState;
}
- (void)setServerState:(DaemonStatus)state {
  if (kSparkDaemonError == state) {
    DLog(@"Error while starting daemon");
    state = kSparkDaemonStopped;
  }
  serverState = state;
  [[NSNotificationCenter defaultCenter] postNotificationName:kSPServerStatChangeNotification object:self];
  [self setSparkDaemonMenu:nil];
}

- (BOOL)isTrapping {
  id window = [NSApp keyWindow];
  if (window && [window respondsToSelector:@selector(isTrapping)]) {
    return [window isTrapping];
  }
  return NO;
}

#pragma mark -
//- (id)coerceValue:(id)value forKey:(NSString *)key {
//  ShadowTrace();
//  return nil;
//}
//
//- (id)valueAtIndex:(unsigned)index inPropertyWithKey:(NSString *)key {
//  ShadowTrace();
//  id lib = nil;
//  if ([key isEqualToString:@"hotKeys"]) {
//    lib = [SparkKeyLibrary sharedLibrary];
//  } else if ([key isEqualToString:@"keyLists"]) {
//    lib = [SparkListLibrary sharedLibrary];
//  }
//  return [[lib objects] objectAtIndex:index];
//}
//
//- (id)valueWithName:(NSString *)name inPropertyWithKey:(NSString *)key {
//  ShadowTrace();
//  id lib = nil;
//  if ([key isEqualToString:@"hotKeys"]) {
//    lib = [SparkKeyLibrary sharedLibrary];
//  } else if ([key isEqualToString:@"keyLists"]) {
//    lib = [SparkListLibrary sharedLibrary];
//  }
//  id objs = [lib objectEnumerator];
//  id obj;
//  while (obj = [objs nextObject]) {
//    if ([[obj name] isEqualToString:name]) {
//      return obj;
//    }
//  }
//  return nil;
//}
//
//- (id)valueWithUniqueID:(id)uniqueID inPropertyWithKey:(NSString *)key {
//  ShadowTrace();
//  id lib = nil;
//  if ([key isEqualToString:@"hotKeys"]) {
//    lib = [SparkKeyLibrary sharedLibrary];
//  } else if ([key isEqualToString:@"keyLists"]) {
//    lib = [SparkListLibrary sharedLibrary];
//  }
//  return [lib objectWithId:uniqueID];
//}
//
//#pragma mark -
//- (NSArray *)hotKeys {
//  ShadowTrace();
//  return [[SparkKeyLibrary sharedLibrary] objects];
//}
//
//- (int)countOfHotKeys {
//  ShadowTrace();
//  return [[self hotKeys] count];
//}
//
//- (id)objectInHotKeysAtIndex:(int)index {
//  ShadowTrace();
//  return [[self hotKeys] objectAtIndex:index];
//}
//
//- (NSArray *)keyLists {
//  ShadowTrace();
//  return [[SparkListLibrary sharedLibrary] objects];
//}
//
@end

#pragma mark -
@implementation NSApplication (SparkScriptSuite)

- (void)handleHelpScriptCommand:(NSScriptCommand *)scriptCommand {
  ShadowTrace();
  NSString *page = [[scriptCommand arguments] objectForKey:@"Page"];
  if (page) {
    [[self delegate] showPlugInHelpPage:page];
  } else {
    [[self delegate] showPlugInHelp:nil];
  }
}

@end

//@implementation SparkHotKey (ScriptingObjectSpecifier)
//
//- (NSScriptObjectSpecifier *)objectSpecifier {
//  ShadowTrace();
//  id specifier = [[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:nil
//                                                             containerSpecifier:nil
//                                                                            key:@"hotKeys"
//                                                                       uniqueID:SKUInt([self uid])];
//  DLog(@"Specifier: %@", specifier);
//  return [specifier autorelease];
//}
//
//@end
