/*
 *  SoundView.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "WBLevelView.h"

@interface SoundView : WBLevelView {

}

- (BOOL)isMuted;
- (void)setMuted:(BOOL)flag;

@end
