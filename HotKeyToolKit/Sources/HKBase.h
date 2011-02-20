/*
 *  HKBase.h
 *  HotKeyToolKit
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2004 - 2011 Shadow Lab. All rights reserved.
 */

#if !defined(__HKBASE_H)
#define __HKBASE_H 1

#if !defined(HK_VISIBLE)
  #define HK_VISIBLE __attribute__((visibility("default")))
#endif

#if !defined(HK_HIDDEN)
  #define HK_HIDDEN __attribute__((visibility("hidden")))
#endif

#if !defined(HK_EXTERN)
  #if defined(__cplusplus)
    #define HK_EXTERN extern "C"
  #else
    #define HK_EXTERN extern
  #endif
#endif

#if !defined(HK_PRIVATE)
  #define HK_PRIVATE HK_EXTERN HK_HIDDEN
#endif

#if !defined(HK_EXPORT)
  #define HK_EXPORT HK_EXTERN HK_VISIBLE
#endif

#if !defined(HK_CXX_EXPORT)
  #define HK_CXX_PRIVATE HK_HIDDEN
  #define HK_CXX_EXPORT HK_VISIBLE
#endif

#if !defined(HK_OBJC_EXPORT)
  #if __LP64__
    #define HK_OBJC_PRIVATE HK_HIDDEN
    #define HK_OBJC_EXPORT HK_VISIBLE
  #else
    #define HK_OBJC_EXPORT
    #define HK_OBJC_PRIVATE
  #endif /* 64 bits runtime */
#endif

#if !defined(HK_INLINE)
  #if !defined(__NO_INLINE__)
    #define HK_INLINE static inline __attribute__((always_inline))
  #else
    #define HK_INLINE static inline
  #endif /* No inline */
#endif

// MARK: Base Types
#include <CoreServices/CoreServices.h>

typedef uint32_t HKModifier;
typedef CGKeyCode HKKeycode;

#endif /* __HKBASE_H */
