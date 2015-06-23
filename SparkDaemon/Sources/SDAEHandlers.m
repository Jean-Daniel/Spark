/*
 *  AEScript.c
 *  SparkServer
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006 Shadow Lab. All rights reserved.
 */

#include "SDAEHandlers.h"

#include <SparkKit/SparkKit.h>

#include <WonderBox/WBAEFunctions.h>

OSStatus SDGetEditorIsTrapping(Boolean *trapping) {
  if (!trapping)
    return paramErr;
  *trapping = FALSE;

  OSStatus err = noErr;
  NSRunningApplication *front = [NSWorkspace sharedWorkspace].frontmostApplication;

  /* If Spark Editor is the front process, send apple event */
  if ([front.bundleIdentifier isEqual:kSparkEditorBundleIdentifier]) {
    AEDesc reply = WBAEEmptyDesc();
    AEDesc theEvent = WBAEEmptyDesc();
    
    err = WBAECreateEventWithTargetProcessIdentifier(front.processIdentifier, kAECoreSuite, kAEGetData, &theEvent);
    require_noerr(err, bail);
    
    err = WBAEAddPropertyObjectSpecifier(&theEvent, keyDirectObject, typeProperty, kSparkEditorIsTrapping, NULL);
    require_noerr(err, fevent);
    
//    err = WBAESetStandardAttributes(&theEvent);
//    require_noerr(err, fevent);

    /* Timeout: 500 ms ?? */
    err = WBAESendEvent(&theEvent, kAEWaitReply, 500, &reply);
    require_noerr(err, fevent);
    
    err = WBAEGetBooleanFromAppleEvent(&reply, keyDirectObject, trapping);
    /* Release Apple event descriptor */
fevent:
      WBAEDisposeDesc(&theEvent);
    WBAEDisposeDesc(&reply);
  }
  
bail:
  return err;
}
