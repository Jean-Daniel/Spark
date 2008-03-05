//
//  SEExportOptions.h
//  Spark Editor
//
//  Created by Grayfox on 28/10/07.
//  Copyright 2007 Shadow Lab. All rights reserved.
//

#import WBHEADER(WBViewController.h)

/* this class breaks the MVC patter to avoid binding circular reference */
@interface SEExportOptions : WBViewController {
  @private
  IBOutlet NSButton *uiIcons;
	IBOutlet NSButton *uiStrike;
  IBOutlet NSPopUpButton *uiGroup;
}

- (BOOL)strike;
- (BOOL)includeIcons;
- (NSInteger)groupBy;
@end
