/*
 *  SparkFunctions.h
 *  SparkKit
 *
 *  Created by Grayfox on 09/12/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 *
 */

#if !defined(__SPARKFUNCTIONS_H)
#define __SPARKFUNCTIONS_H 1

#include <SparkKit/SparkKit.h>

typedef enum {
  kSparkEditorContext,
  kSparkDaemonContext,
} SparkContext;

/*!
@function
 @result Returns current execution context.
 */
SPARK_EXPORT
SparkContext SparkGetCurrentContext(void);

SPARK_EXPORT
void SparkLaunchEditor(void);

#if defined(__OBJC__)

@class SparkAlert;

/*!
@function    SparkDisplayAlerts
 @abstract   Display alert dialog.
 @discussion Can be use in during a key execution to display an alert message. As Spark Daemon is 
 a background application, you cannot use NSAlert and other graphics objects.
 @param      alerts An Array of <code>SparkAlert</code>.
 */
SPARK_EXPORT
void SparkDisplayAlerts(NSArray *alerts);

SPARK_INLINE
void SparkDisplayAlert(SparkAlert *alert) {
  SparkDisplayAlerts([NSArray arrayWithObject:alert]);
}

#pragma mark Notification
SPARK_EXPORT
void SparkNotificationDisplayIcon(IconRef icon, float delay);

SPARK_EXPORT
void SparkNotificationDisplayImage(NSImage *anImage, float delay);

/* See <HIServices/Icons.h> for possible values */
SPARK_EXPORT
void SparkNotificationDisplaySystemIcon(OSType icon, float delay);

#endif


#endif /* __SPARKFUNCTIONS_H */