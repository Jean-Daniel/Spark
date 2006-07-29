/*
 *  SparkKit.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright © 2004 - 2006 Shadow Lab. All rights reserved.
 *
 */

#if !defined(__SPARKKIT_H)
#define __SPARKKIT_H 1

#if defined(__OBJC__)
#import <Cocoa/Cocoa.h>
#else
#include <ApplicationServices/ApplicationServices.h>
#endif

#pragma mark Base Macros

#if defined(__cplusplus)
#if defined (__GNUC__) && (__GNUC__ >= 4)
#define SPARK_EXPORT extern "C" __attribute__((visibility("default")))
#else
#define SPARK_EXPORT extern "C"
#endif
#define __inline__ inline
#endif

#if !defined(SPARK_EXPORT)
#if defined (__GNUC__) && (__GNUC__ >= 4)
#define SPARK_EXPORT extern __attribute__((visibility("default")))
#else
#define SPARK_EXPORT extern
#endif
#endif

#if !defined(SPARK_INLINE)
#if defined (__GNUC__) && (__GNUC__ >= 4) && !defined(DEBUG)
#define SPARK_INLINE static __inline__ __attribute__((always_inline))
#else
#define SPARK_INLINE static __inline__
#endif
#endif

#if !defined(SPARK_PRIVATE)
#if defined (__GNUC__) && (__GNUC__ >= 4) && !defined(DEBUG)
#define SPARK_PRIVATE __private_extern__ __attribute__((visibility("hidden")))
#else
#define SPARK_PRIVATE __private_extern__
#endif
#endif

#if !defined(SPARK_EXTERN_INLINE)
#define SPARK_EXTERN_INLINE extern __inline__
#endif

#pragma mark -
#pragma mark Constants
#if defined(__OBJC__)
SPARK_EXPORT NSString * const kSparkFolderName;

SPARK_EXPORT NSString * const kSparkHFSCreator;
SPARK_EXPORT NSString * const kSparkDaemonHFSCreator;
SPARK_EXPORT NSString * const kSparkBundleIdentifier;
SPARK_EXPORT NSString * const kSparkKitBundleIdentifier;
SPARK_EXPORT NSString * const kSparkDaemonBundleIdentifier;
#else 
SPARK_EXPORT CFStringRef const kSparkFolderName;

SPARK_EXPORT CFStringRef const kSparkHFSCreator;
SPARK_EXPORT CFStringRef const kSparkDaemonHFSCreator;
SPARK_EXPORT CFStringRef const kSparkBundleIdentifier;
SPARK_EXPORT CFStringRef const kSparkKitBundleIdentifier;
SPARK_EXPORT CFStringRef const kSparkDaemonBundleIdentifier;
#endif /* __OBJC__ */

SPARK_EXPORT
const OSType kSparkHFSCreatorType;
SPARK_EXPORT
const OSType kSparkDaemonHFSCreatorType;

#endif /* __SPARKKIT_H */
