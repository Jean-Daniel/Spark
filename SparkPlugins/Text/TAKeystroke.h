//
//  TAKeystroke.h
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 17/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <HotKeyToolKit/HotKeyToolKit.h>

@interface TAKeystroke : NSObject <NSCoding>

- (instancetype)initWithKeycode:(HKKeycode)keycode character:(UniChar)character modifier:(HKModifier)modifier;
- (instancetype)initFromRawKey:(UInt64)rawKey;

- (void)sendKeystroke:(CGEventSourceRef)src latency:(useconds_t)latency;

@property(nonatomic, readonly) NSString *shortcut;

@property(nonatomic, readonly) uint64_t rawKey;

@end
