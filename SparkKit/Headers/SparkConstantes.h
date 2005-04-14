/*
 *  SparkConstantes.h
 *  SparkKit
 *
 *  Created by Fox on 17/08/04.
 *  Copyright 2004 Shadow Lab. All rights reserved.
 *
 */

#ifndef __SPARK_CONSTANTES__
#define __SPARK_CONSTANTES__

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#import <SparkKit/SparkKitBase.h>

SPARK_EXPORT NSString * const kSparkFolderName;

SPARK_EXPORT NSString * const kSparkHFSCreator;
SPARK_EXPORT NSString * const kSparkDaemonHFSCreator;
SPARK_EXPORT NSString * const kSparkBundleIdentifier;
SPARK_EXPORT NSString * const kSparkKitBundleIdentifier;
SPARK_EXPORT NSString * const kSparkDaemonBundleIdentifier;

#else 
#include <CoreFoundation/CoreFoundation.h>
#include <SparkKit/SparkKitBase.h>

SPARK_EXPORT CFStringRef const kSparkFolderName;

SPARK_EXPORT CFStringRef const kSparkHFSCreator;
SPARK_EXPORT CFStringRef const kSparkDaemonHFSCreator;
SPARK_EXPORT CFStringRef const kSparkBundleIdentifier;
SPARK_EXPORT CFStringRef const kSparkKitBundleIdentifier;
SPARK_EXPORT CFStringRef const kSparkDaemonBundleIdentifier;

#endif /* __OBJC__ */

SPARK_EXPORT const OSType kSparkHFSCreatorType;
SPARK_EXPORT const OSType kSparkDaemonHFSCreatorType;

#endif /* __SPARK_CONSTANTES__ */