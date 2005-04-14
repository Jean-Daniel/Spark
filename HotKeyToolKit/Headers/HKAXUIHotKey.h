/*
 *  HKAXUIHotKey.h
 *  HotKeyToolKit
 *
 *  Created by Grayfox on 10/10/04.
 *  Copyright 2004 Shadow Lab. All rights reserved.
 *
 */

#include <HotKeyToolKit/HKHotKey.h>

@interface HKHotKey (AXUIExtension)

/*!
	@method     sendHotKeyToApplicationWithSignature:bundleId:
	@abstract   Perform the receiver HotKey on the application specified by <i>signature</i> or <i>bundleId</i>.
	@param      signature The target application process signature (creator) or <i>kHKActiveApplication</i> to send event to front application ,
				or <i>kHKSystemWide</i> to send System Wide event, or <i>kHKUnknowCreator</i> if you don't know it. In this case, you must 
				provide a Bundle Identifier.
    @param      bundleId The Bundle identifier of the target process.
	@result		An AXError code.
 */
- (AXError)sendHotKeyToApplicationWithSignature:(OSType)signature bundleId:(NSString *)bundleId;

@end