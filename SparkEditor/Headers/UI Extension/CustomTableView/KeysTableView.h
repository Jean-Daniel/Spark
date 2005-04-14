//
//  KeysTableView.h
//  Spark
//
//  Created by Fox on Wed Jan 14 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "CustomTableView.h"

@interface KeysTableView : CustomTableView {
  BOOL _isDragging;
  NSImage *_dragImg;
}
//- (NSImage *)badgeWithCount:(int)count;
@end
