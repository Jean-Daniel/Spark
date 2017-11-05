/*
 *  SEPlugInHelp.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "SEPlugInHelp.h"

#import "Spark.h"

#import <WebKit/WebKit.h>

#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkActionLoader.h>

@interface SEPlugInHelp () <WebFrameLoadDelegate>

@end

@implementation SEPlugInHelp {
@private

}

+ (id)sharedPlugInHelp {
  static SEPlugInHelp *shared = nil;
  if (shared)
    return shared;
  @synchronized(self) {
    if (!shared) {
      shared = [[SEPlugInHelp alloc] init];
      /* Load nib */
      [shared window];
    }
  }
  return shared;
}

- (id)init {
  if (self = [super init]) {
    /* Dynamic plugin */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLoadPlugIn:)
                                                 name:SESparkEditorDidChangePlugInStatusNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLoadPlugIn:)
                                                 name:SparkActionLoaderDidRegisterPlugInNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadPlugInMenu {
  NSMenu *aMenu = [[NSMenu alloc] initWithTitle:@"PlugIns"];
  NSEnumerator *plugins = [[[[SparkActionLoader sharedLoader] plugIns] sortedArrayUsingDescriptors:gSortByNameDescriptors] objectEnumerator];
  
  SparkPlugIn *plugin;
  while (plugin = [plugins nextObject]) {
    if ([plugin isEnabled]) {
      NSURL *help = [plugin helpURL];
      if (help) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[plugin name] action:nil keyEquivalent:@""];
        /* Set icon */
        NSImage *icon = [[plugin icon] copy];
        [icon setSize:NSMakeSize(16, 16)];
        [item setImage:icon];
        
        [item setRepresentedObject:[help absoluteString]];
        [aMenu addItem:item];
      }
    }
  }
	
  if (![aMenu numberOfItems]) {
    NSURL *help = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:
																					NSLocalizedStringFromTable(@"nohelp", 
																																		 @"Resources", 
																																		 @"No Help page available")
                                                                         ofType:@"html"]];
    NSAssert(help, @"nohelp.html not found");
    if (help) {
      NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"no help", @"No help menu item title")
                                                    action:nil keyEquivalent:@""];
      [item setImage:[NSImage imageNamed:@"plugin"]];
      [item setRepresentedObject:[help absoluteString]];
      [aMenu addItem:item];
    } else {
      [[ibWeb mainFrame] loadHTMLString:@"no plugin help available" baseURL:nil];
    }
  }

  [ibPlugins setMenu:aMenu];
  
  if ([aMenu numberOfItems])
    [self selectPlugIn:[aMenu itemAtIndex:0]];
}

- (void)didLoadPlugIn:(NSNotification *)aNotification {
  [self loadPlugInMenu];
}

- (void)awakeFromNib {
//    se_previous = [ibHead addButton:[NSImage imageNamed:@"SEBack"] position:kWBHeaderLeft];
//    se_previous.target = ibWeb;
//    se_previous.action = @selector(goBack:);
//    [se_previous bind:@"enabled" toObject:ibWeb withKeyPath:@"canGoBack" options:nil];
//
//    se_next = [ibHead addButton:[NSImage imageNamed:@"SEForward"] position:kWBHeaderLeft];
//    se_next.target = ibWeb;
//    se_next.action = @selector(goForward:);
//    [se_next bind:@"enabled" toObject:ibWeb withKeyPath:@"canGoForward" options:nil];

  [ibWeb setFrameLoadDelegate:self];
  [self loadPlugInMenu];
}

#pragma mark -
- (void)setPage:(NSString *)aPage {
  if (aPage && [ibPlugins indexOfItemWithTitle:aPage] != NSNotFound) {
    [ibPlugins selectItemWithTitle:aPage];
    [self selectPlugIn:nil];
  }
}

- (void)setPlugIn:(SparkPlugIn *)aPlugin {
  [ibPlugins selectItemWithTitle:aPlugin.name];
  [self selectPlugIn:nil];
}

- (IBAction)selectPlugIn:(NSPopUpButton *)sender {
  NSString *path = [[ibPlugins selectedItem] representedObject];
  if (path) {
    [[ibWeb backForwardList] setCapacity:0];
    [ibWeb setValue:path forKey:@"mainFrameURL"];
    [[ibWeb backForwardList] setCapacity:10];
  }
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
  if (frame == [sender mainFrame]) {
    [[sender window] setTitle:title];
  }
}

@end
