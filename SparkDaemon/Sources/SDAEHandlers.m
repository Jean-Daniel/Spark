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
#include <WonderBox/WBProcessFunctions.h>

OSStatus SDGetEditorIsTrapping(Boolean *trapping) {
  if (!trapping)
    return paramErr;
  *trapping = FALSE;
  
  ProcessSerialNumber psn;
  OSStatus err = GetFrontProcess(&psn);
  require_noerr(err, bail);
  
  /* Check front process */
  ProcessInfoRec info = {};
  info.processInfoLength = (UInt32)sizeof(info);
  err = GetProcessInformation(&psn, &info);
  require_noerr(err, bail);
  
  /* If Spark Editor is the front process, send apple event */
  if (kSparkEditorSignature == info.processSignature) {
    AEDesc reply = WBAEEmptyDesc();
    AEDesc theEvent = WBAEEmptyDesc();
    
    err = WBAECreateEventWithTargetProcess(&psn, kAECoreSuite, kAEGetData, &theEvent);
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
