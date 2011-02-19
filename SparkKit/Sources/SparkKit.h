/*
 *  SparkKit.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#if !defined(__SPARKKIT_H)
#define __SPARKKIT_H 1

#pragma mark Base Macros

#if !defined(SPARK_VISIBLE)
  #define SPARK_VISIBLE __attribute__((visibility("default")))
#endif

#if !defined(SPARK_HIDDEN)
  #define SPARK_HIDDEN __attribute__((visibility("hidden")))
#endif

#if !defined(SPARK_EXTERN)
  #if defined(__cplusplus)
    #define SPARK_EXTERN extern "C"
  #else
    #define SPARK_EXTERN extern
  #endif
#endif

#if !defined(SPARK_PRIVATE)
  #define SPARK_PRIVATE SPARK_EXTERN SPARK_HIDDEN
#endif

#if !defined(SPARK_EXPORT)
  #define SPARK_EXPORT SPARK_EXTERN SPARK_VISIBLE
#endif

#if !defined(SPARK_CXX_EXPORT)
  #define SPARK_CXX_PRIVATE SPARK_HIDDEN
  #define SPARK_CXX_EXPORT SPARK_VISIBLE
#endif

#if !defined(SPARK_OBJC_EXPORT)
  #if __LP64__
    #define SPARK_OBJC_PRIVATE SPARK_HIDDEN
    #define SPARK_OBJC_EXPORT SPARK_VISIBLE
  #else
    #define SPARK_OBJC_EXPORT
    #define SPARK_OBJC_PRIVATE
  #endif /* 64 bits runtime */
#endif

#if !defined(SPARK_INLINE)
  #if !defined(__NO_INLINE__)
    #define SPARK_INLINE static inline __attribute__((always_inline))
  #else
    #define SPARK_INLINE static inline
  #endif /* No inline */
#endif

#pragma mark -
#pragma mark Constants
#if defined(__OBJC__)
SPARK_EXPORT NSString * const kSparkErrorDomain;

SPARK_EXPORT NSString * const kSparkFolderName;

SPARK_EXPORT NSString * const kSparkKitBundleIdentifier;
SPARK_EXPORT NSString * const kSparkDaemonBundleIdentifier;

/* Globals Notifications */
SPARK_EXPORT NSString * const SparkWillSetActiveLibraryNotification;
SPARK_EXPORT NSString * const SparkDidSetActiveLibraryNotification;

#define kSparkKitBundle [NSBundle bundleWithIdentifier:kSparkKitBundleIdentifier]

#else 
SPARK_EXPORT CFStringRef const kSparkFolderName;

SPARK_EXPORT CFStringRef const kSparkKitBundleIdentifier;
SPARK_EXPORT CFStringRef const kSparkDaemonBundleIdentifier;
#endif /* __OBJC__ */

SPARK_EXPORT
const OSType kSparkEditorSignature;
SPARK_EXPORT
const OSType kSparkDaemonSignature;

typedef uint32_t SparkUID;

/* Misc Apple event helpers */

/* Use this constant to send events to the finder.
It will allows to easily replace the Finder by another application */
SPARK_EXPORT
OSType kSparkFinderSignature;

#endif /* __SPARKKIT_H */
