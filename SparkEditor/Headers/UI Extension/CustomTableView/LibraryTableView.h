//
//  LibrarySortDecriptor.h
//  Spark
//
//  Created by Fox on Sat Jan 10 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import <SparkKit/SparkKit.h>
#import "CustomTableView.h"

@interface ListTableView : CustomTableView {
}

@end

@interface LibraryTableView : ListTableView {

}

@end

@interface ListTableCell : SKImageAndTextCell

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

@end