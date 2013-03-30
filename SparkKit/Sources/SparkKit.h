/*
 *  SparkKit.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#if !defined(__SPARKKIT_H)
#define __SPARKKIT_H 1

#import <SparkKit/SparkDefine.h>

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
