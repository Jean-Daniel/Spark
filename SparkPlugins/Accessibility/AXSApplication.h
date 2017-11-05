//
//  AXSApplication.h
//  NeoLab
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "AXSUIElement.h"

@class AXSMenu;
@interface AXSApplication : AXSUIElement

- (id)initWithProcessIdentifier:(pid_t)aPid NS_DESIGNATED_INITIALIZER;

@property(nonatomic, readonly) AXSMenu *menu;

@property(nonatomic, readonly) pid_t processIdentifier;

@end
