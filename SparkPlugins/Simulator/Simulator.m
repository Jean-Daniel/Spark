/*
 *  Simulator.m
 *  Spark Plugins
 *
 *  Created by Grayfox on 10/09/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "Simulator.h"

#import "ITunesInfo.h"
#import "ITunesAESuite.h"

int main(int argc, const char **argv) {
  return NSApplicationMain(argc, argv);
}

@implementation Simulator

- (id)init {
  if (self = [super init]) {
    info = [[ITunesInfo alloc] init];
  }
  return self;
}

- (void)dealloc {
  [info release];
  [super dealloc];
}

- (IBAction)show:(id)sender {
  iTunesTrack track;
  SKAENullDesc(&track);
  if (noErr == iTunesGetCurrentTrack(&track)) {
    [info setTrack:&track];
    SKAEDisposeDesc(&track);
  } else {
    [info setTrack:NULL];
  }
  [info display:sender];
}

@end
