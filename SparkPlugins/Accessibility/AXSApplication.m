//
//  AXSApplication.m
//  NeoLab
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "AXSApplication.h"
#import "AXSMenu.h"

@implementation AXSApplication {
@private
  AXSMenu *_menu;
}

- (id)initWithProcessIdentifier:(pid_t)aPid {
  AXUIElementRef app = AXUIElementCreateApplication(aPid);
  if (app) {
    if (self = [super initWithElement:app]) {
      
    }
    CFRelease(app);
  } else {
    self = nil;
  }
  return self;
}

#pragma mark -
- (AXSMenu *)menu {
  if (!_menu) {
    CFTypeRef menu = NULL;
    AXError err = AXUIElementCopyAttributeValue([self element], kAXMenuBarAttribute, &menu);
    if (noErr == err) {
      NSAssert(CFGetTypeID(menu) == AXUIElementGetTypeID(), @"invalid menu element");
      _menu = [[AXSMenu alloc] initWithElement:(AXUIElementRef)menu];
      CFRelease(menu);
    }
  }
  return _menu;
}

- (pid_t)processIdentifier {
  pid_t pid;
  if (kAXErrorSuccess == AXUIElementGetPid([self element], &pid))
    return pid;
  return 0;
}

@end
