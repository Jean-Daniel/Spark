//
//  AXSApplication.h
//  NeoLab
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "AXSUIElement.h"

@class AXSMenu;
@interface AXSApplication : AXSUIElement {
@private
  AXSMenu *ax_menu;
}

- (id)initWithProcess:(ProcessSerialNumber *)aProcess;
- (id)initWithProcessIdentifier:(pid_t)aPid;

- (AXSMenu *)menu;

- (pid_t)processIdentifier;
@end
