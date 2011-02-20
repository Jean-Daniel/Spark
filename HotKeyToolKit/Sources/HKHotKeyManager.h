/*
 *  HKHotKeyManager.h
 *  HotKeyToolKit
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2004 - 2011 Shadow Lab. All rights reserved.
 */
/*!
 @header HKHotKeyManager
 */
#import <Foundation/Foundation.h>
#import <HotKeyToolKit/HKBase.h>

@class HKHotKey;

/*!
 @class 		HKHotKeyManager
 @abstract   HotKeyManager is used to register and unregister HKHotKey. It dispatch Global HotKey event.
 */
HK_OBJC_EXPORT
@interface HKHotKeyManager : NSObject {
@private
  void *hk_handler; /* EventHandlerRef */
  NSMapTable *hk_refs;
  NSMapTable *hk_keys;
  /* temp */
  void *hk_event; // EventRef
}

/*!
 @method     sharedManager
 @abstract   Returns the shared HKHotKeyManager instance.
 */
+ (HKHotKeyManager *)sharedManager;

/*!
 @method     registerHotKey:
 @abstract   Try to register an HKHotKey as Gloab System HotKey.
 @param		key The HKHotKey you want to register
 @result		YES if the key is succesfully registred.
 */
- (BOOL)registerHotKey:(HKHotKey *)key;
/*!
 @method     unregisterHotKey:
 @abstract   Try to unregister an HKHotKey as System HotKey.
 @param		key The HKHotKey you want to unregister
 @result		Returns YES if the key is succesfully unregistred.
 */
- (BOOL)unregisterHotKey:(HKHotKey *)key;

/*!
 @method     unregisterAll
 @abstract   Unregister all registred keys.
 */
- (void)unregisterAll;

/* Protected */
- (NSTimeInterval)currentEventTime;
- (void)hotKeyPressed:(HKHotKey *)key;
- (void)hotKeyReleased:(HKHotKey *)key;

@end

/*!
 @function
 @abstract   Use to define if a Shortcut is valid (not already used,…)
 @discussion You can customize this function result by providing a HKHotKeyFilter to the Manager (see setShortcutFilter).
 @param      code a Virtual Keycode.
 @param      modifier the modifier keys.
 @result     Returns YES if the keystrock is valid.
 */
HK_EXPORT
BOOL HKHotKeyCheckKeyCodeAndModifier(HKKeycode code, HKModifier modifier);

/* Debugging purpose */
HK_EXPORT BOOL HKTraceHotKeyEvents;
