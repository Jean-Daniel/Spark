//
//  ApplicationMenu.m
//  Spark
//
//  Created by Fox on Thu Feb 19 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//

#import "ApplicationMenu.h"
#import "DocumentActionPlugin.h"

@implementation ApplicationMenu

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  [self removeAllItems];
  id menu = [self menu];
  [self setAutoenablesItems:NO];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"CHOOSE_MENU", nil,
                                                            kDocumentActionBundle,
                                                            @"Title of the Choose MenuItem item in the (With Application:) Menu")
                  action:@selector(choose:) keyEquivalent:@""];
  [[menu itemAtIndex:1] setTarget:self];
  [self selectItemAtIndex:1];
  hasCustomApp = YES;
  return self;
}

- (IBAction)choose:(id)sender {
  NSOpenPanel *oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection:NO];
  [oPanel beginSheetForDirectory:nil
                            file:nil
                           types:[NSArray arrayWithObjects:@"app", @"APPL", nil]
                  modalForWindow:[self window]
                   modalDelegate:self
                  didEndSelector:@selector(choosePanel:returnCode:contextInfo:)
                     contextInfo:nil];
}

- (void)choosePanel:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(id)contextInfo {
  if (returnCode == NSCancelButton) {
    return;
  }
  if (!hasCustomApp) {
    [[self menu] insertItem:[NSMenuItem separatorItem] atIndex:0];
    hasCustomApp = YES;
  }
  [[self menu] insertItem:[self itemForPath:[[sheet filenames] objectAtIndex:0]] atIndex:0];
  [self selectItemAtIndex:0];
}

- (void)loadAppForDocument:(NSString *)path {
  while ([self numberOfItems] > 2) {
    [self removeItemAtIndex:0];
  }
  hasCustomApp = NO;
  if (path) {
    id url = [NSURL fileURLWithPath:path];
    id listAppl = (id)LSCopyApplicationURLsForURL((CFURLRef)url, kLSRolesAll);
    id desc = [[NSSortDescriptor alloc] initWithKey:@"path.lastPathComponent" ascending:NO selector:@selector(caseInsensitiveCompare:)];
    id apps = [[listAppl sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]] objectEnumerator];
    [desc release];
    id app;
    while (app = [apps nextObject]) {
      [[self menu] insertItem:[self itemForPath:[app path]] atIndex:0];
    }
    [self selectItemAtIndex:0];
    [listAppl release];
  }
  else {
    [self selectItemAtIndex:1];
  }
}

- (NSMenuItem *)itemForPath:(NSString *)path {
  id name = [[[NSFileManager defaultManager] displayNameAtPath:path] stringByDeletingPathExtension];
  id icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
  id object = [NSDictionary dictionaryWithObjectsAndKeys:path, @"path", name, @"name", icon, @"icon", nil];
  id item = [[NSMenuItem alloc] initWithTitle:name action:@selector(appChange:) keyEquivalent:@""];
  [icon setSize:NSMakeSize(16,16)];
  [item setImage:icon];
  [item setRepresentedObject:object];
  return [item autorelease];
}
@end
