//
//  AXSUIElement.m
//  NeoLab
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "AXSUIElement.h"

@implementation AXSUIElement

// FIXME: override init to return nil.

- (id)initWithElement:(AXUIElementRef)anElement {
  if (self = [super init]) {
    ax_elt = CFRetain(anElement);
  }
  return self;
}

- (void)dealloc {
  if (ax_elt) 
    CFRelease(ax_elt);
  [super dealloc];
}

- (NSString *)description {
  CFStringRef str = CFCopyDescription(ax_elt);
  NSString *desc = [NSString stringWithFormat:@"<%@ %p> { %@ }", 
                    [self class], self, str];
  if (str) CFRelease(str);
  return desc;
}

#pragma mark -
- (AXUIElementRef)element {
  return ax_elt;
}

- (NSString *)role {
  return [self valueForAttribute:NSAccessibilityRoleAttribute];
}

#pragma mark Attributes
- (NSArray *)attributeNames {
  CFArrayRef names;
  if (kAXErrorSuccess == AXUIElementCopyAttributeNames(ax_elt, &names))
    return WBCFAutorelease(NSArray, names);
  return nil; 
}
- (id)valueForAttribute:(NSString *)anAttribute {
  NSParameterAssert(anAttribute);
//  id result;
  CFTypeRef value;
  if (kAXErrorSuccess == AXUIElementCopyAttributeValue(ax_elt, (CFStringRef)anAttribute, &value)) {
//    if (CFGetTypeID(value) == AXUIElementGetTypeID()) {
//      result = [[[AXSUIElement alloc] initWithElement:value] autorelease];
//      CFRelease(value);
//    } else {
//      result = [NSMakeCollectable(value) autorelease];
//    }
//    return result;
    return WBCFAutorelease(NSString, value);
  }
  return nil;
}
- (BOOL)setValue:(id)aValue forAttribute:(NSString *)anAttribute {
  NSParameterAssert(anAttribute);
  return kAXErrorSuccess == AXUIElementSetAttributeValue(ax_elt, (CFStringRef)anAttribute, (CFTypeRef)aValue);
}

- (NSUInteger)countOfValuesForAttribute:(NSString *)anAttribute {
  NSParameterAssert(anAttribute);
  CFIndex count;
  if (kAXErrorSuccess == AXUIElementGetAttributeValueCount(ax_elt, (CFStringRef)anAttribute, &count))
    return count;
  return 0;
}
- (NSArray *)valuesForAttribute:(NSString *)anAttribute {
  NSParameterAssert(anAttribute);
  NSUInteger count = [self countOfValuesForAttribute:anAttribute];
  if (count > 0)
    return [self valuesForAttribute:anAttribute range:NSMakeRange(0, count)];
  return nil;
}
- (NSArray *)valuesForAttribute:(NSString *)anAttribute range:(NSRange)aRange {
  NSParameterAssert(anAttribute);
  CFArrayRef values;
  if (kAXErrorSuccess == AXUIElementCopyAttributeValues(ax_elt, (CFStringRef)anAttribute, aRange.location, aRange.length, &values))
    return WBCFAutorelease(NSArray, values);
  return nil;
}

#pragma mark Actions
- (NSArray *)actionNames {
  CFArrayRef names;
  if (kAXErrorSuccess == AXUIElementCopyActionNames(ax_elt, &names))
    return WBCFAutorelease(NSArray, names);
  return nil;  
}

- (NSString *)actionDescription:(NSString *)anAction {
  CFStringRef str;
  if (kAXErrorSuccess == AXUIElementCopyActionDescription(ax_elt, (CFStringRef)anAction, &str))
    return WBCFAutorelease(NSString, str);
  return NSAccessibilityActionDescription(anAction);
}

- (BOOL)performAction:(NSString *)anAction {
  NSParameterAssert(nil != anAction);
  return kAXErrorSuccess == AXUIElementPerformAction(ax_elt, (CFStringRef)anAction);
}

@end

