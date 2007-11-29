//
//  SparkEntryPlaceholder.h
//  SparkKit
//
//  Created by Jean-Daniel Dupas on 29/11/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <SparkKit/SparkKit.h>

@class SparkLibrary, SparkEntry;
@interface SparkEntryPlaceholder : NSObject {
  @private
  UInt32 flags;
  
  SparkUID sp_action;
  SparkUID sp_trigger;
  SparkUID sp_application;
}

- (id)initWithActionUID:(SparkUID)act triggerUID:(SparkUID)trg applicationUID:(SparkUID)app;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

@end
