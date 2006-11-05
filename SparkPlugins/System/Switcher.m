/*
 *  Switcher.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */


#import "Controller.h"

@implementation Controller

- (void)awakeFromNib {
  id usr = [self userList];
  NSTask *pipeTask = [[NSTask alloc] init];
  [pipeTask setLaunchPath:@"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"];
  [pipeTask setArguments:[NSArray arrayWithObjects:@"-switchToUserID", [[usr objectAtIndex:1] objectForKey:@"uid"], nil]];
  [pipeTask launch];
}
//-suspend
- (IBAction)send:(id)sender {
}

- (NSArray *)userList {
  // use getpwnam();
  NSTask *pipeTask = [[NSTask alloc] init];
  NSPipe *newPipe = [NSPipe pipe];
  NSFileHandle *readHandle = [newPipe fileHandleForReading];
  NSData *inData = nil;
  NSMutableData *data = [NSMutableData data];
  // write handle is closed to this process
  [pipeTask setStandardOutput:newPipe]; 
  [pipeTask setLaunchPath:@"/usr/bin/nidump"];
  [pipeTask setArguments:[NSArray arrayWithObjects:@"-r", @"/users", @".", nil]];
  [pipeTask launch];
  
  while ((inData = [readHandle availableData]) && [inData length]) {
    [data appendData:inData];
  }
  [pipeTask release];
  return [self processData:data];
}

// This method is a callback which your controller can use to do other cleanup when a process
// is halted.
- (NSArray *)processData:(NSData *)data {
  NSMutableString *str = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  int index = [str rangeOfString:@"(\n"].location;
  [str deleteCharactersInRange:NSMakeRange(0, index)];
  index = [str rangeOfString:@")" options:NSBackwardsSearch].location +1;
  [str deleteCharactersInRange:NSMakeRange(index, [str length] - index)];
  [str replaceOccurrencesOfString:@"("
                       withString:@""
                          options:NSBackwardsSearch
                            range:NSMakeRange(1, [str length] - 2)];
  [str replaceOccurrencesOfString:@")"
                       withString:@""
                          options:NSBackwardsSearch
                            range:NSMakeRange(1, [str length] - 2)];
  NSMutableArray *users = [str propertyList];
  [str release];
  
  id desc = [[NSSortDescriptor alloc] initWithKey:@"uid" ascending:YES selector:@selector(compareNumeric:)];
  [users sortUsingDescriptors:[NSArray arrayWithObject:desc]];
  [desc release];
  id items = [users reverseObjectEnumerator];
  id item;
  id result = [NSMutableArray array];
  while (item = [items nextObject]) {
    if ([[item objectForKey:@"uid"] intValue] >= 501) {
      id dico = [[NSMutableDictionary alloc] init];
      [dico setObject:[item objectForKey:@"realname"] forKey:@"Name"];
      [dico setObject:[item objectForKey:@"picture"] forKey:@"Picture"];
      [dico setObject:[item objectForKey:@"uid"] forKey:@"uid"];
      [result insertObject:dico atIndex:0];
      [dico release];
    }
    else break;
  }
  return result;
}

@end

@interface NSString (NumericCompare) 
- (NSComparisonResult)compareNumeric:(NSString *)otherString;
@end
@implementation NSString (NumericCompare)
- (NSComparisonResult)compareNumeric:(NSString *)otherString {
  return [self compare:otherString options:NSNumericSearch];
}
@end