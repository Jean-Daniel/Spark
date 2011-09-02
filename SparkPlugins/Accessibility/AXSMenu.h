//
//  AXSMenu.h
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "AXSUIElement.h"

@interface AXSMenu : AXSUIElement {
@private
}

- (NSArray *)items;
- (NSString *)title;

@end

@interface AXSMenuItem : AXSUIElement {
@private
  AXSMenu *ax_submenu;
}

- (AXSMenu *)submenu;

- (NSString *)title;
- (BOOL)isSeparator;

@end
