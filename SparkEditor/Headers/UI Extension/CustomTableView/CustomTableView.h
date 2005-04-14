//
//  Extension.h
//  Spark
//
//  Created by Fox on Mon Jan 12 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

extern NSString * const kCustomTableViewDidBecomeFirstResponder;

@interface CustomTableView : NSTableView {
}

@end

@interface NSObject (CustomTableViewDelegate)
- (void)deleteSelectionInTableView:(CustomTableView *)view;
@end