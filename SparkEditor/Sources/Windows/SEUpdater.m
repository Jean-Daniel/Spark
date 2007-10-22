//
//  SEUpdater.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 18/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SEUpdater.h"

SKSingleton(SEUpdater, sharedUpdater);

@implementation SEUpdater

- (id)init {
  if (self = [super initWithBundle:[NSBundle mainBundle]]) {
    
  }
  return self;
}

- (void)dealloc {
  
  [super dealloc];
}

- (void)willPerformStep:(SUpdaterStepName)step {
  switch ([self step]) {
    case kSUpdaterStepSearch:
      /* does nothing */
      [uiProgress startAnimation:nil];
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
      [uiProgress stopAnimation:nil];
      break;
    default:
      [super didPerformStep:step];
      break;
  }
}

- (void)updater:(SUpdaterController *)ctrl stepProgress:(CGFloat)progress expected:(CGFloat)total {
  switch ([self step]) {
    case kSUpdaterStepSearch:
      if (progress <= 0) {
        if (total >= 0) {
          [uiProgress setMaxValue:total];
          [uiProgress setIndeterminate:NO];
        } else {
          [uiProgress setIndeterminate:YES];
        }
      } else {
        [uiProgress setDoubleValue:progress];
      }
      break;
    default:
      [super updater:ctrl stepProgress:progress expected:total];
      break;
  }
}

@end

