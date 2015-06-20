//
//  AXSMenu.h
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "AXSUIElement.h"

@interface AXSMenu : AXSUIElement

@property(nonatomic, readonly) NSArray *items;
@property(nonatomic, readonly) NSString *title;

@end

@interface AXSMenuItem : AXSUIElement

@property(nonatomic, readonly) AXSMenu *submenu;

@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) BOOL isSeparator;

@end
