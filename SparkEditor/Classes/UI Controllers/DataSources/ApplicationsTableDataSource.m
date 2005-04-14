//
//  ApplicationsTableDataSource.m
//  Spark Editor
//
//  Created by Grayfox on 17/09/04.
//  Copyright 2004 Shadow Lab. All rights reserved.
//

#import "ApplicationsTableDataSource.h"
#import "ApplicationLibraryController.h"

@implementation ApplicationsTableDataSource

- (BOOL)canAddFile:(NSString *)path {
  id app = [[SKApplication alloc] initWithPath:path];
  if (app) {
    id apps = [SparkDefaultApplicationLibrary() applicationWithIdentifier:[app identifier]];
    [app release];
    return apps == nil;
  } 
  return  NO;
}

#pragma mark Drag & Drop Support
- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
  if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:kSparkApplicationPBoardType]]) {
    return YES;
  } else if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]) {
    BOOL accept = NO;
    id files = [[[info draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectEnumerator];
    id file;
    while (file = [files nextObject]) {
      if ([[NSFileManager defaultManager] isAliasFileAtPath:file]) {
        file = [[NSFileManager defaultManager] resolveAliasFileAtPath:file isFolder:nil];
      }
      if (file) {
        id appli = [[SparkApplication alloc] initWithPath:file];
        if (appli) {
          /* We check if app already exist */
          id app = [SparkDefaultApplicationLibrary() applicationWithIdentifier:[appli identifier]];
          if (!app) { /* If not */
            //[SparkDefaultApplicationLibrary() addObject:appli];
            [self insertObject:appli atArrangedObjectIndex:row++];
          } else if ([[self arrangedObjects] indexOfObject:app] == NSNotFound) { /* else app exist */
            [self insertObject:app atArrangedObjectIndex:row++];
          }
          [appli release];
          accept = YES;
        }
      }
    }
    return accept;
  }
  return NO;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
  if (NSTableViewDropAbove != operation) {
    return NSDragOperationNone;
  } else if ([[info draggingPasteboard] availableTypeFromArray:
    [NSArray arrayWithObjects:kSparkApplicationPBoardType, NSFilenamesPboardType, nil]]) {
    return NSDragOperationCopy;
  }
  return NSDragOperationNone;
}

@end
