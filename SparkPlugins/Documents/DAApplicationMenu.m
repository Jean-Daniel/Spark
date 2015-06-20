/*
 *  DAApplicationMenu.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "DAApplicationMenu.h"

#import "DocumentAction.h"

#import <WonderBox/WBImageFunctions.h>

@implementation DAApplicationMenu {
  BOOL _custom;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
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
    [self selectItemAtIndex:1];
    
    _custom = YES;
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
  if (!_custom) {
    [[self menu] insertItem:[NSMenuItem separatorItem] atIndex:0];
    _custom = YES;
  }
  NSURL *path;
  NSEnumerator *files = [[sheet URLs] reverseObjectEnumerator];
  while (path = [files nextObject]) {
    [[self menu] insertItem:[self itemForURL:path] atIndex:0];
  }
  [self selectItemAtIndex:0];
}

- (void)loadAppForDocument:(NSURL *)url {
  while ([self numberOfItems] > 2) {
    [self removeItemAtIndex:0];
  }
  _custom = NO;
  if (url) {
    NSArray *applications = SPXCFArrayBridgingRelease(LSCopyApplicationURLsForURL(SPXNSToCFURL(url), kLSRolesAll));
    if ([applications count]) {
      CFURLRef prefered = NULL;
      LSGetApplicationForURL(SPXNSToCFURL(url), kLSRolesAll, NULL, &prefered);
      /* Sort applications */
      NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"path.lastPathComponent" ascending:NO selector:@selector(caseInsensitiveCompare:)];
      NSArray *sorted = [applications sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
      NSEnumerator *urls = [sorted objectEnumerator];
      
      NSURL *application;
      while (application = [urls nextObject]) {
        if ([application isFileURL])
          [[self menu] insertItem:[self itemForURL:application] atIndex:0];
      }
      if (prefered) {
        NSUInteger idx = [sorted indexOfObject:SPXCFToNSURL(prefered)];
        if (idx != NSNotFound) {
          idx++;
          [self selectItemAtIndex:[sorted count] - idx];
        }
        CFRelease(prefered);
      }
    }
  } else {
    [self selectItemAtIndex:1];
  }
}

- (NSMenuItem *)itemForURL:(NSURL *)path {
  NSString *name;
  if (![path getResourceValue:&name forKey:NSURLLocalizedNameKey error:NULL]) {
    name = [path lastPathComponent];
  }
  name = [name stringByDeletingPathExtension];
  
  NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[path path]];
  if (icon) {
    WBImageSetRepresentationsSize(icon, NSMakeSize(16, 16));
  }
  [icon setSize:NSMakeSize(16, 16)];
  
  NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""];
  [item setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"path", name, @"name", icon, @"icon", nil]];
  [item setImage:icon];
  
  return item;
}

@end
