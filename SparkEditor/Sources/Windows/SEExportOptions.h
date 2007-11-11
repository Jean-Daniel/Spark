//
//  SEExportOptions.h
//  Spark Editor
//
//  Created by Grayfox on 28/10/07.
//  Copyright 2007 Shadow Lab. All rights reserved.
//

#import <ShadowKit/SKViewController.h>

/* this class breaks the MVC patter to avoid binding circular reference */
@interface SEExportOptions : SKViewController {
  @private
  IBOutlet NSButton *uiIcons;
  IBOutlet NSPopUpButton *uiGroup;
}

- (BOOL)includeIcons;
- (NSInteger)groupBy;
@end
