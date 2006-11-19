/*
 *  SparkHelper.m
 *  Spark Editor
 *
 *  Created by Grayfox on 19/11/06.
 *  Copyright 2006 Shadow Lab. All rights reserved.
 */

#import <getopt.h>
#import "SparkHelper.h"

#import <SparkKit/SparkActionLoader.h>

int main(int argc, char **argv) {
  int ch;
  BOOL delete = NO;
  NSString *src = nil;
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  /* options descriptor */
  static struct option longopts[] = {
  {"delete", required_argument, nil, 'd' },
  {"install", required_argument, nil, 'i' },
  {nil, 0, nil, 0} };
       
  /* invalid arg count */
  if (argc < 2) {
    return 1;
  }
  
  while ((ch = getopt_long(argc, argv, "d:i:", longopts, NULL)) != -1) {
    switch(ch) {
      case 'd':
        delete = YES;
        if (src) {
          return 1;
        }
          src = [[NSString alloc] initWithUTF8String:optarg];
        break;
      case 'i':
        if (src) {
          return 1;
        }
        src = [[NSString alloc] initWithUTF8String:optarg];
        break;
      case '?':
      default:
        return 1;
    }
  }
  
  NSArray *folders = [SparkActionLoader pluginPathsForDomains:kSKComputerDomain];
  if (folders && [folders count]) {
    NSString *dest = [folders objectAtIndex:0];
    // mkdir dest
  }
  [src release];
  [pool release];
  return 0;
}

@implementation SparkHelper

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

/*
 NSWorkspaceDestroyOperation
 if (![[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceMoveOperation
                                                   source:@"/Documents"
                                              destination:[@"~/Desktop/" stringByStandardizingPath]
                                                    files:[NSArray arrayWithObject:@"test"]
                                                      tag:NULL]) {
   DLog(@"Failed");
 } else {
   DLog(@"Success");
 }
 */

@end
