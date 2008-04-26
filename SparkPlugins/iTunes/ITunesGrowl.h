//
//  ITunesGrowl.h
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 05/04/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import "ITunesAction.h"
#include "ITunesAESuite.h"

#import <Growl/GrowlApplicationBridge.h>

@interface ITunesAction (ITunesGrowl) <GrowlApplicationBridgeDelegate>

- (void)displayTrackUsingGrowl:(iTunesTrack *)track;

- (NSString *)starsForRating:(NSNumber *)rating;

@end

