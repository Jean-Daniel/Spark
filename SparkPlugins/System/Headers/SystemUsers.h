//
//  SystemUsers.h
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 03/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#ifndef Spark_Plugins_SystemUsers_h
#define Spark_Plugins_SystemUsers_h

#import <OpenDirectory/OpenDirectory.h>

extern
CFTypeRef WBODRecordCopyFirstValue(ODRecordRef record, ODAttributeType attribute);
extern
CFDictionaryRef WBODRecordCopyAttributes(ODRecordRef record, CFArrayRef attributes);

extern
CFArrayRef WBODCopyVisibleUsersAttributes(ODAttributeType attribute, ...) SC_REQUIRES_NIL_TERMINATION;

#endif
