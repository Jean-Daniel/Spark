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
    color = @"textColor";
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
  [[info window] setIgnoresMouseEvents:NO];
  [[info window] setMovableByWindowBackground:YES];
  [info showWindow:sender];  
}

- (IBAction)display:(id)sender {
  iTunesTrack track;
  SKAENullDesc(&track);
  if (noErr == iTunesGetCurrentTrack(&track)) {
    [info setTrack:&track];
    SKAEDisposeDesc(&track);
  } else {
    [info setTrack:NULL];
  }
  [[info window] setIgnoresMouseEvents:YES];
  [[info window] setMovableByWindowBackground:NO];
  [info display:sender];
}

- (NSColor *)color {
  return color ? [info valueForKey:color] : nil;
}
- (void)setColor:(NSColor *)aColor {
  if (color)
    [info setValue:aColor forKey:color];
}

- (UInt32)component {
  if ([color isEqualToString:@"borderColor"]) return 1;
  else if ([color isEqualToString:@"backgroundColor"]) return 2;
  else if ([color isEqualToString:@"backgroundTopColor"]) return 4;
  else if ([color isEqualToString:@"backgroundBottomColor"]) return 5;
  return 0;
}

- (void)setComponent:(UInt32)component {
  [self willChangeValueForKey:@"color"];
  switch (component) {
    case 0:
      color = @"textColor";
      break;
    case 1:
      color = @"borderColor";
      break;
    case 2:
      color = @"backgroundColor";
      break;
    case 4:
      color = @"backgroundTopColor";
      break;
    case 5:
      color = @"backgroundBottomColor";
      break;
  }
  [self didChangeValueForKey:@"color"];
}

@end
