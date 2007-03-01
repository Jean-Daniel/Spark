/*
 *  DAApplicationMenu.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "DAApplicationMenu.h"

#import "DocumentAction.h"

#import <ShadowKit/SKImageUtils.h>

@implementation DAApplicationMenu

- (id)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    [self removeAllItems];
    NSMenu *menu = [self menu];
    [self setAutoenablesItems:NO];
    [menu addItem:[NSMenuItem separatorItem]];
    /* Append choose menu item */
    NSString *title = NSLocalizedStringFromTableInBundle(@"CHOOSE_MENU", nil,
                                                         kDocumentActionBundle,
                                                         @"Title of the Choose MenuItem item in the (With Application:) Menu");
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
                                                  action:@selector(choose:) 
                                           keyEquivalent:@""];
    [item setTarget:self];
    [menu addItem:item];
    [item release];
    [self selectItemAtIndex:1];
    
    da_custom = YES;
  }
  return self;
}

- (IBAction)choose:(id)sender {
  NSOpenPanel *oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowsMultipleSelection:YES];
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
  if (!da_custom) {
    [[self menu] insertItem:[NSMenuItem separatorItem] atIndex:0];
    da_custom = YES;
  }
  NSString *path;
  NSEnumerator *files = [[sheet filenames] reverseObjectEnumerator];
  while (path = [files nextObject]) {
    [[self menu] insertItem:[self itemForPath:path] atIndex:0];
  }
  [self selectItemAtIndex:0];
}

- (void)loadAppForDocument:(NSString *)path {
  while ([self numberOfItems] > 2) {
    [self removeItemAtIndex:0];
  }
  da_custom = NO;
  if (path) {
    NSURL *url = [NSURL fileURLWithPath:path];
    if (url) {
      NSArray *applications = (id)LSCopyApplicationURLsForURL((CFURLRef)url, kLSRolesAll);
      if ([applications count]) {
        CFURLRef prefered = NULL;
        LSGetApplicationForURL((CFURLRef)url, kLSRolesAll, NULL, &prefered);
        /* Sort applications */
        NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"path.lastPathComponent" ascending:NO selector:@selector(caseInsensitiveCompare:)];
        NSArray *sorted = [applications sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
        NSEnumerator *urls = [sorted objectEnumerator];
        [desc release];
        
        NSURL *application;
        while (application = [urls nextObject]) {
          if ([application isFileURL])
            [[self menu] insertItem:[self itemForPath:[application path]] atIndex:0];
        }
        if (prefered) {
          int idx = [sorted indexOfObject:(id)prefered];
          if (idx != NSNotFound) {
            idx++;
            [self selectItemAtIndex:[sorted count] - idx];
          }
          CFRelease(prefered);
        }
      }
      [applications release];
    }
  } else {
    [self selectItemAtIndex:1];
  }
}

- (NSMenuItem *)itemForPath:(NSString *)path {
  NSString *name = [[[NSFileManager defaultManager] displayNameAtPath:path] stringByDeletingPathExtension];
  
  NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
  if (icon) {
    SKImageSetRepresentationsSize(icon, NSMakeSize(16, 16));
  }
  [icon setSize:NSMakeSize(16, 16)];
  
  NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""];
  [item setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"path", name, @"name", icon, @"icon", nil]];
  [item setImage:icon];
  
  return [item autorelease];
}

@end
