/*
 *  SEFirstRun.m
 *  Spark Editor
 *
 *  Created by Grayfox on 23/08/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import "SEFirstRun.h"
#import "Spark.h"

static const int kSparkVersion = 0x030000; /* 3.0.0 */

@implementation Spark (SEFirstRun)

- (void)displayFirstRunIfNeeded {
  int version = [[NSUserDefaults standardUserDefaults] integerForKey:@"SparkVersion"];
  if (version < kSparkVersion) {
    SEFirstRun *first = [[SEFirstRun alloc] init];
    [first setReleasedWhenClosed:YES];
    [NSApp beginSheet:[first window]
       modalForWindow:[self mainWindow]
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:nil];
  }
}

@end

@implementation SEFirstRun

+ (NSString *)frameAutoSaveName {
  return nil;
}

- (void)awakeFromNib {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"Read First" ofType:@"rtf"];
}

- (IBAction)close:(id)sender {
  //if (autorun) {
//    [Preferences setAutoStart:YES];
//  }
//  [[NSUserDefaults standardUserDefaults] setBool:autorun forKey:kSparkPrefAutoStart];
  [[NSUserDefaults standardUserDefaults] setInteger:kSparkVersion forKey:@"SparkVersion"];
  [super close:sender];  
}

@end
