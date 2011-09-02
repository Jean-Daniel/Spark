/*
 *  ODUsers.c
 *  Spark Plugins
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2011 __MyCompanyName__. All rights reserved.
 */

#include "SystemUsers.h"

CFTypeRef WBODRecordCopyFirstValue(ODRecordRef record, ODAttributeType attribute) {
  CFArrayRef values = ODRecordCopyValues(record, attribute, NULL);
  if (!values) return NULL;
  
  CFTypeRef result = NULL;
  if (CFArrayGetCount(values) > 0)
    result = CFRetain(CFArrayGetValueAtIndex(values, 0));
  
  CFRelease(values);
  return result;
}

static
CFTypeRef _WBODDetailsGetDefaultValue(CFDictionaryRef details, ODAttributeType attribute) {
  CFArrayRef values = CFDictionaryGetValue(details, attribute);
  if (!values) return NULL;
  
  if (CFArrayGetCount(values) > 0)
    return CFArrayGetValueAtIndex(values, 0);
  
  return NULL;
}

CFDictionaryRef WBODRecordCopyAttributes(ODRecordRef record, CFArrayRef attributes) {
  CFDictionaryRef values = ODRecordCopyDetails(record, attributes, NULL);
  if (!values) return NULL;
  
  CFMutableDictionaryRef user = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                          &kCFCopyStringDictionaryKeyCallBacks,
                                                          &kCFTypeDictionaryValueCallBacks);
  
  for (CFIndex idx = 0, count = CFArrayGetCount(attributes); idx < count; ++idx) {
    ODAttributeType key = CFArrayGetValueAtIndex(attributes, idx);
    CFTypeRef value = _WBODDetailsGetDefaultValue(values, key);
    if (value)
      CFDictionarySetValue(user, key, value);
  }
  CFRelease(values);
  
  return user;
}

CFArrayRef WBODCopyVisibleUsersAttributes(ODAttributeType attribute, ...) {
  assert(attribute);
  
  CFArrayRef required = CFArrayCreate(kCFAllocatorDefault, (const void **)(ODAttributeType[]) {
    kODAttributeTypePassword,
    kODAttributeTypeUserShell
  }, 2, &kCFTypeArrayCallBacks);
  
  CFErrorRef error;
  ODQueryRef query = ODQueryCreateWithNodeType(kCFAllocatorDefault, kODNodeTypeLocalNodes, kODRecordTypeUsers, 
                                               kODAttributeTypeAllAttributes, kODMatchAny, NULL,
                                               required, 0, &error);
  CFRelease(required);
  
  if (!query) {
    CFRelease(error);
    return NULL;
  }
  
  CFArrayRef records = ODQueryCopyResults(query, false, &error);
  CFRelease(query);
  if (!records) {
    CFRelease(error);
    return NULL;
  }
  
  va_list args;
  va_start(args, attribute);
  CFMutableArrayRef requested = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
  CFStringRef attr = attribute;
  do {
    CFArrayAppendValue(requested, attr);
    attr = va_arg(args, CFStringRef);
  } while (attr);
  va_end(args);
  
  CFMutableArrayRef users = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
  
  for (CFIndex idx = 0, count = CFArrayGetCount(records); idx < count; ++idx) {
    ODRecordRef record = (ODRecordRef)CFArrayGetValueAtIndex(records, idx);
    CFStringRef shell = WBODRecordCopyFirstValue(record, kODAttributeTypeUserShell);
    if (shell && !CFEqual(shell, CFSTR("/usr/bin/false"))) {
      CFStringRef passwd = WBODRecordCopyFirstValue(record, kODAttributeTypePassword);
      if (passwd && !CFEqual(passwd, CFSTR("*"))) {
        CFDictionaryRef user = WBODRecordCopyAttributes(record, requested);
        if (user) {
          CFArrayAppendValue(users, user);
          CFRelease(user);
        }
      }
      if (passwd) CFRelease(passwd);
    }
    if (shell) CFRelease(shell);
  }
  
  CFRelease(requested);
  CFRelease(records);
  return users;
}
