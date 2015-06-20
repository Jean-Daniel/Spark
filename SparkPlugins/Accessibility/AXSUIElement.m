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
    _element = CFRetain(anElement);
  }
  return self;
}

- (void)dealloc {
  if (_element)
    CFRelease(_element);
}

- (NSString *)description {
  CFStringRef str = CFCopyDescription(_element);
  NSString *desc = [NSString stringWithFormat:@"<%@ %p> { %@ }", 
                    [self class], self, str];
  if (str) CFRelease(str);
  return desc;
}

#pragma mark -
- (NSString *)role {
  return [self valueForAttribute:NSAccessibilityRoleAttribute];
}

#pragma mark Attributes
- (NSArray *)attributeNames {
  CFArrayRef names;
  if (kAXErrorSuccess == AXUIElementCopyAttributeNames(_element, &names))
    return SPXCFArrayBridgingRelease(names);
  return nil; 
}
- (id)valueForAttribute:(NSString *)anAttribute {
  NSParameterAssert(anAttribute);
//  id result;
  CFTypeRef value;
  if (kAXErrorSuccess == AXUIElementCopyAttributeValue(_element, SPXNSToCFString(anAttribute), &value)) {
//    if (CFGetTypeID(value) == AXUIElementGetTypeID()) {
//      result = [[[AXSUIElement alloc] initWithElement:value] autorelease];
//      CFRelease(value);
//    } else {
//      result = [NSMakeCollectable(value) autorelease];
//    }
//    return result;
    return SPXCFStringBridgingRelease(value);
  }
  return nil;
}
- (BOOL)setValue:(id)aValue forAttribute:(NSString *)anAttribute {
  NSParameterAssert(anAttribute);
  return kAXErrorSuccess == AXUIElementSetAttributeValue(_element, SPXNSToCFString(anAttribute), SPXNSToCFType(aValue));
}

- (NSUInteger)countOfValuesForAttribute:(NSString *)anAttribute {
  NSParameterAssert(anAttribute);
  CFIndex count;
  if (kAXErrorSuccess == AXUIElementGetAttributeValueCount(_element, SPXNSToCFString(anAttribute), &count))
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
  if (kAXErrorSuccess == AXUIElementCopyAttributeValues(_element, SPXNSToCFString(anAttribute), aRange.location, aRange.length, &values))
    return SPXCFArrayBridgingRelease(values);
  return nil;
}

#pragma mark Actions
- (NSArray *)actionNames {
  CFArrayRef names;
  if (kAXErrorSuccess == AXUIElementCopyActionNames(_element, &names))
    return SPXCFArrayBridgingRelease(names);
  return nil;  
}

- (NSString *)actionDescription:(NSString *)anAction {
  CFStringRef str;
  if (kAXErrorSuccess == AXUIElementCopyActionDescription(_element, SPXNSToCFString(anAction), &str))
    return SPXCFStringBridgingRelease(str);
  return NSAccessibilityActionDescription(anAction);
}

- (BOOL)performAction:(NSString *)anAction {
  NSParameterAssert(nil != anAction);
  return kAXErrorSuccess == AXUIElementPerformAction(_element, SPXNSToCFString(anAction));
}

@end

