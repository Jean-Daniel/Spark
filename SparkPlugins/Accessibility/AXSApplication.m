//
//  AXSApplication.m
//  NeoLab
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "AXSApplication.h"
#import "AXSMenu.h"

@implementation AXSApplication

- (id)initWithProcess:(ProcessSerialNumber *)aProcess {
  pid_t pid;
  if (noErr == GetProcessPID(aProcess, &pid))
    return [self initWithProcessIdentifier:pid];
  [self release];
  return nil;
}

- (id)initWithProcessIdentifier:(pid_t)aPid {
  AXUIElementRef app = AXUIElementCreateApplication(aPid);
  if (app) {
    if (self = [super initWithElement:app]) {
      
    }
    CFRelease(app);
  } else {
    [self release];
    self = nil;
  }
  return self;
}

- (void)dealloc {
  if (ax_menu)
    CFRelease(ax_menu);
  [super dealloc];
}

#pragma mark -
- (AXSMenu *)menu {
  if (!ax_menu) {
    CFTypeRef menu = NULL;
    AXError err = AXUIElementCopyAttributeValue([self element], kAXMenuBarAttribute, &menu);
    if (noErr == err) {
      NSAssert(CFGetTypeID(menu) == AXUIElementGetTypeID(), @"invalid menu element");
      ax_menu = [[AXSMenu alloc] initWithElement:(AXUIElementRef)menu];
      CFRelease(menu);
    }
  }
  return ax_menu;
}

- (pid_t)processIdentifier {
  pid_t pid;
  if (kAXErrorSuccess == AXUIElementGetPid([self element], &pid))
    return pid;
  return 0;
}

@end
