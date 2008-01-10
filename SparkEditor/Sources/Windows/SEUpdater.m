//
//  SEUpdater.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 18/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SEUpdater.h"

#import <ShadowKit/SKSingleton.h>

@implementation SEUpdater
SKSingleton(SEUpdater, sharedUpdater);

- (id)init {
  if (self = [super initWithBundle:[NSBundle mainBundle]]) {
    
  }
  return self;
}

- (void)dealloc {
  
  [super dealloc];
}

#pragma mark -
- (void)searchWithDelegate:(id)delegate {
  se_delegate = delegate;
  [self start];
}

#pragma mark -
- (void)didFoundNewVersion:(SUpdaterProductVersion *)version {
  [se_delegate updater:self didSearchVersion:(version != nil) error:nil];
  se_delegate = nil;
}

- (void)willPerformStep:(SUpdaterStepName)step {
  switch ([self step]) {
    case kSUpdaterStepSearch:
      /* does nothing */
      break;
    default:
      [super willPerformStep:step];
      break;
  }
}

- (void)didPerformStep:(SUpdaterStepName)step {
  switch ([self step]) {
    case kSUpdaterStepSearch:
      /* does nothing */
      break;
    default:
      [super didPerformStep:step];
      break;
  }
}

- (void)updater:(SUpdaterController *)ctrl stepProgress:(CGFloat)progress expected:(CGFloat)total {
  switch ([self step]) {
    case kSUpdaterStepSearch:
      /* did nothing */
      break;
    default:
      [super updater:ctrl stepProgress:progress expected:total];
      break;
  }
}

- (void)errorOccured:(NSError *)anError {
  switch ([self step]) {
    case kSUpdaterStepSearch:
      /* did nothing */
      [se_delegate updater:self didSearchVersion:NO error:anError];
      se_delegate = nil;
      break;
    default:
      [super errorOccured:anError];
      break;
  }
}

/* Specific methods */
- (void)didCancel {
  switch ([self step]) {
    case kSUpdaterStepSearch:
      /* did nothing */
      [se_delegate updater:self didSearchVersion:NO error:nil];
      se_delegate = nil;
      break;
    default:
      [super didCancel];
      break;
  }
}

- (NSData *)updaterRestartNotificationData:(SUpdaterController *)ctrl {
  return [@"Super je suis a jour!" dataUsingEncoding:NSUTF8StringEncoding];
}

@end

