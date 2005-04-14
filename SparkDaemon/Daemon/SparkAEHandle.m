//
//  SparkAEHandle.m
//  SparkServer
//
//  Created by Fox on 21/08/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "SparkAEHandle.h"
#import <SparkKit/SparkKit.h>

@implementation SparkHotKey (AppleScriptAddition)

- (NSScriptObjectSpecifier *)objectSpecifier {
  ShadowTrace();
  NSScriptObjectSpecifier *result = nil;
  result = [[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:nil
                                                       containerSpecifier:nil
                                                                      key:@"hotkeys"
                                                                 uniqueID:[self uid]];
  return [result autorelease];
}

- (void)handleInvokeHotKeyScriptCommand:(NSScriptCommand *)sender {
  ShadowTrace();
  DLog(@"Command: %@", [sender directParameter]);
  [self invoke];
}

@end

@implementation NSApplication (SparkAEHandle)

+ (id)coerceObject:(id)object toClass:(Class)class {
  ShadowTrace();
  return nil;
}

- (id)coerceValue:(id)value forKey:(NSString *)key {
  ShadowTrace();
  return nil;
}

- (id)valueAtIndex:(unsigned)index inPropertyWithKey:(NSString *)key {
  ShadowTrace();
  return nil;
}

- (id)valueWithName:(NSString *)name inPropertyWithKey:(NSString *)key {
  ShadowTrace();
  return nil;
}

- (id)WithUniqueID:(NSString *)name inPropertyWithKey:(NSString *)key {
  ShadowTrace();
  return nil;
}

- (id)valueInHotKeysWithName:(id)name {
  ShadowTrace();
  id keys = [SparkDefaultKeyLibrary() objectEnumerator];
  id key;
  while (key = [keys nextObject]) {
    if ([[key name] isEqualToString:name]) {
      return key;
    }
  }
  return nil;
}

- (id)valueInHotKeysWithUniqueID:(id)uid {
  ShadowTrace();
  DLog(@"UID: %@", uid);
  return [SparkDefaultKeyLibrary() objectWithId:uid];
}

#pragma mark -
- (NSArray *)hotkeys {
  ShadowTrace();
  return [SparkDefaultKeyLibrary() objects];
}

- (int)countOfHotkeys {
  ShadowTrace();
  return [[self hotkeys] count];
}

- (id)objectInHotkeysAtIndex:(int)index {
  ShadowTrace();
  return [[self hotkeys] objectAtIndex:index];
}

@end
