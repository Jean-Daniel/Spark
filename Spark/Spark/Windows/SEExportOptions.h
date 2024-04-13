//
//  SEExportOptions.h
//  Spark Editor
//
//  Created by Grayfox on 28/10/07.
//  Copyright 2007 Shadow Lab. All rights reserved.
//

/* this class breaks the MVC pattern to avoid binding circular reference */
@interface SEExportOptions : NSViewController {
@private
  IBOutlet NSButton *uiIcons;
  IBOutlet NSButton *uiStrike;
}

@property(nonatomic, readonly) BOOL strike;
@property(nonatomic, readonly) BOOL includeIcons;

@end
