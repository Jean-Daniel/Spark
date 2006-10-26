/*
 *  SETriggerBrowser.h
 *  Spark Editor
 *
 *  Created by Grayfox on 10/09/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <ShadowKit/SKWindowController.h>

@class SETableView;
@interface SETriggerBrowser : SKWindowController {
  IBOutlet SETableView *ibTriggers;
}

@end
