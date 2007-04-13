/*
 *  SparkFunctions.h
 *  SparkKit
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
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
BOOL SparkEditorIsRunning(void);

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
/* delay: -1 for default value */
SPARK_EXPORT
void SparkNotificationDisplayIcon(IconRef icon, CGFloat delay);

SPARK_EXPORT
void SparkNotificationDisplayImage(NSImage *anImage, CGFloat delay);

/* See <HIServices/Icons.h> for possible values */
SPARK_EXPORT
void SparkNotificationDisplaySystemIcon(OSType icon, CGFloat delay);

/* Private notifications */
SPARK_EXPORT
void SparkNotificationDisplay(NSView *view, CGFloat delay);

#endif


#endif /* __SPARKFUNCTIONS_H */
