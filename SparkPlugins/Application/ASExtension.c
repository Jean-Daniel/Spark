/*
 *  ASExtension.c
 *  Spark
 *
 *  Created by Fox on Thu Dec 18 2003.
 *  Copyright (c) 2004 Shadow Lab. All rights reserved.
 *
 */

#include "ASExtension.h"
#include <SparkKit/SparkKit.h>
#include <ShadowKit/SKAEFunctions.h>

OSStatus QuitApplication(ProcessSerialNumber *psn) {
  return SKAESendSimpleEventToProcess(psn, kCoreEventClass, kAEQuitApplication);
}

OSErr KillApplication(ProcessSerialNumber *psn) {
  return KillProcess(psn);
}
