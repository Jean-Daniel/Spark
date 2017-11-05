/*
 *  SparkKit.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#if !defined(__SPARKKIT_H)
#define __SPARKKIT_H 1

#import <Foundation/Foundation.h>

#import <SparkKit/SparkDefine.h>
#import <SparkKit/SparkTypes.h>

#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkFunctions.h>
#import <SparkKit/SparkPreferences.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionPlugIn.h>

#import <SparkKit/SparkPluginView.h>
#import <SparkKit/SparkMultipleAlerts.h>

#pragma mark -
#pragma mark Constants

SPARK_EXPORT NSString * const kSparkErrorDomain;

SPARK_EXPORT NSString * const kSparkFolderName;

SPARK_EXPORT NSString * const kSparkKitBundleIdentifier;
SPARK_EXPORT NSString * const kSparkEditorBundleIdentifier;
SPARK_EXPORT NSString * const kSparkDaemonBundleIdentifier;

/* Globals Notifications */
SPARK_EXPORT NSString * const SparkWillSetActiveLibraryNotification;
SPARK_EXPORT NSString * const SparkDidSetActiveLibraryNotification;

SPARK_EXPORT NSBundle *SparkKitBundle(void);

SPARK_EXPORT
const OSType kSparkEditorSignature SPARK_DEPRECATED("Bundle identifier");

SPARK_EXPORT
const OSType kSparkDaemonSignature SPARK_DEPRECATED("Bundle identifier");

/* Misc Apple event helpers */

/* Use this constant to send events to the finder.
It will allows to easily replace the Finder by another application */
SPARK_EXPORT
NSString * kSparkFinderBundleIdentifier;

#endif /* __SPARKKIT_H */
