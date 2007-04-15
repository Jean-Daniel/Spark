/*
 *  HKKeyboardUtils.h
 *  HotKeyToolKit
 *
 *  Created by Shadow Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */
/*!
    @header		HKKeyboardUtils
    @abstract   Abstract layer to access KeyMap on KCHR Keyboard or uchr Keyboard.
*/
#include <CoreServices/CoreServices.h>
#import <HotKeyToolKit/HKBase.h>

typedef struct HKKeyMapContext HKKeyMapContext;
typedef UniChar (*HKBaseCharacterForKeyCodeFunction)(void *ctxt, HKKeycode keycode);
typedef UniChar (*HKCharacterForKeyCodeFunction)(void *ctxt, HKKeycode keycode, HKModifier modifier);
typedef NSUInteger (*HKKeycodesForCharacterFunction)(void *ctxt, UniChar character, HKKeycode *keys, HKModifier *modifiers, NSUInteger maxsize);
typedef void (*HKContextDealloc)(HKKeyMapContext *ctxt);

struct HKKeyMapContext {
  void *data;
  HKContextDealloc dealloc;
  HKBaseCharacterForKeyCodeFunction baseMap;
  HKCharacterForKeyCodeFunction fullMap;
  HKKeycodesForCharacterFunction reverseMap;
};

HK_PRIVATE
OSStatus HKKeyMapContextWithUchrData(const UCKeyboardLayout *layout, Boolean reverse, HKKeyMapContext *ctxt);

#if !__LP64__
HK_PRIVATE
OSStatus HKKeyMapContextWithKCHRData(const void *layout, Boolean reverse, HKKeyMapContext *ctxt);
#endif /* __LP64__ */
