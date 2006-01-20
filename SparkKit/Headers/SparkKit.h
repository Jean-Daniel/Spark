//
//  SparkKit.h
//  Spark
//
//  Created by Fox on Sat Nov 29 2003.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#ifndef __SPARK_KIT__
#define __SPARK_KIT__

#ifdef __OBJC__

#import <SparkKit/SparkKitBase.h>
#import <SparkKit/SparkConstantes.h>

#import <SparkKit/SparkAction.h>
#import <SparkKit/SparkActionPlugIn.h>
#import <SparkKit/SparkAlert.h>
#import <SparkKit/SparkMultipleAlerts.h>

#import <SparkKit/Spark_Private.h>

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkPlugInLoader.h>
#import <SparkKit/SparkActionLoader.h>

#import <SparkKit/SparkSerialization.h>
#import <SparkKit/SparkLibraryObject.h>
#import <SparkKit/SparkHotKey.h>
#import <SparkKit/SparkApplication.h>

#import <SparkKit/SparkObjectList.h>
#import <SparkKit/SparkKeyList.h>
#import <SparkKit/SparkActionList.h>
#import <SparkKit/SparkApplicationList.h>

#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkObjectsLibrary.h>
#import <SparkKit/SparkKeyLibrary.h>
#import <SparkKit/SparkListLibrary.h>
#import <SparkKit/SparkActionLibrary.h>
#import <SparkKit/SparkApplicationLibrary.h>

#import <SparkKit/Extension.h>
#import <SparkKit/SparkShadow.h>
#import <SparkKit/SparkShadow_Private.h>

#else

#include <SparkKit/SparkKitBase.h>
#include <SparkKit/SparkConstantes.h>
#include <SparkKit/SparkShadow.h>
#include <SparkKit/SparkShadow_Private.h>

#endif /* __OBJC__ */

#endif /* __SPARK_KIT__ */