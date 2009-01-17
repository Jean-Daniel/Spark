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

#import WBHEADER(WBHeaderView.h)

@implementation SEPlugInHelp

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
  [super dealloc];
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
        [icon release];
        
        [item setRepresentedObject:[help absoluteString]];
        [aMenu addItem:item];
        [item release];
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
      [item release];
    } else {
      [[ibWeb mainFrame] loadHTMLString:@"no plugin help available" baseURL:nil];
    }
  }
  
  if (!se_plugins) {
    se_plugins = [ibHead addMenu:aMenu position:kWBHeaderLeft];
    [se_plugins setTarget:self];
    [se_plugins setAction:@selector(selectPlugIn:)];
  } else {
    [se_plugins setMenu:aMenu];
  }
  
  if ([aMenu numberOfItems]) {
    [self selectPlugIn:[aMenu itemAtIndex:0]];
  }
  
  [aMenu release];
}

- (void)didLoadPlugIn:(NSNotification *)aNotification {
  [self loadPlugInMenu];
}

- (void)awakeFromNib {
  if (!se_previous) {
    se_previous = [ibHead addButton:[NSImage imageNamed:@"SEBack"] position:kWBHeaderLeft];
    [se_previous setTarget:ibWeb];
    [se_previous setAction:@selector(goBack:)];
    [se_previous bind:@"enabled" toObject:ibWeb withKeyPath:@"canGoBack" options:nil];
    
    se_next = [ibHead addButton:[NSImage imageNamed:@"SEForward"] position:kWBHeaderLeft];
    [se_next setTarget:ibWeb];
    [se_next setAction:@selector(goForward:)];
    [se_next bind:@"enabled" toObject:ibWeb withKeyPath:@"canGoForward" options:nil];
    
    [ibWeb setFrameLoadDelegate:self];
    [self loadPlugInMenu];
  }
}

#pragma mark -
- (void)setPage:(NSString *)aPage {
  if (aPage && [se_plugins indexOfItemWithTitle:aPage] != NSNotFound) {
    [se_plugins selectItemWithTitle:aPage];
    [self selectPlugIn:nil];
  }
}

- (void)setPlugIn:(SparkPlugIn *)aPlugin {
  [se_plugins selectItemWithTitle:[aPlugin name]];
  [self selectPlugIn:nil];
}

- (IBAction)selectPlugIn:(id)sender {
  NSString *path = [[se_plugins selectedItem] representedObject];
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
