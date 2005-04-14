//
//  CustomOutlineView.h
//  Spark Editor
//
//  Created by Fox on 10/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CustomOutlineView : NSOutlineView {

}

@end

@interface NSObject (CustomOutlineViewDelegate)
- (void)deleteSelectionInOutlineView:(id)view;
@end