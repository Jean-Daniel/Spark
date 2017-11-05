/*
 *  SETriggerTable.h
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import <WonderBox/WBTableView.h>

@class SETriggerTable;
@protocol SETriggerTableDelegate <WBTableViewDelegate>

- (void)spaceDownInTableView:(SETriggerTable *)aTable;
- (BOOL)tableView:(SETriggerTable *)aTable shouldHandleOptionClick:(NSEvent *)anEvent;

@end

@interface SETriggerTable : WBTableView

@property(assign) id<SETriggerTableDelegate> delegate;

@end
