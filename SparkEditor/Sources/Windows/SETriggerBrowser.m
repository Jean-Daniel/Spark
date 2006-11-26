/*
 *  SETriggerBrowser.m
 *  Spark Editor
 *
 *  Created by Grayfox on 10/09/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SETriggerBrowser.h"

#import "SETableView.h"
#import "SEHeaderCell.h"

@implementation SETriggerBrowser

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc {
  
  [super dealloc];
}

- (void)awakeFromNib {
  /* Configure Library Header Cell */
//  NSString *title = @"Shortcuts";
//  int idx = [[ibTriggers tableColumns] count];
//  while (idx-- > 0) {
//    SEHeaderCell *header = [[SEHeaderCell alloc] initTextCell:title];
//    [header setAlignment:NSCenterTextAlignment];
//    [header setFont:[NSFont systemFontOfSize:11]];
//    [[[ibTriggers tableColumns] objectAtIndex:idx] setHeaderCell:header];
//    [header release];
//    title = @"";
//  }
//  [ibTriggers setCornerView:[[[SEHeaderCellCorner alloc] init] autorelease]];
  //  NSRect rect = [[table headerView] frame];
  //  rect.size.height += 1;
  //  [[table headerView] setFrame:rect];
  
  [ibTriggers setHighlightShading:[NSColor colorWithCalibratedRed:.340f
                                                            green:.606f
                                                             blue:.890f
                                                            alpha:1]
                           bottom:[NSColor colorWithCalibratedRed:0
                                                            green:.312f
                                                             blue:.790f
                                                            alpha:1]
                           border:[NSColor colorWithCalibratedRed:.239f
                                                            green:.482f
                                                             blue:.855f
                                                            alpha:1]];
}

@end
