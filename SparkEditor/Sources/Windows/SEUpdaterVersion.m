//
//  SEUpdaterVersion.m
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 21/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SEUpdaterVersion.h"

#import <WebKit/WebKit.h>

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKHeaderView.h>
#import <ShadowKit/SKUpdaterVersion.h>

@implementation SEUpdaterVersion

- (void)dealloc {
  [se_versions release];
  [super dealloc];
}

- (void)awakeFromNib {
  [ibHistory setPolicyDelegate:self];
}

#pragma mark -
- (IBAction)close:(id)sender {
  [self setModalResultCode:NSCancelButton];
  [super close:sender];
}

- (IBAction)install:(id)sender {
  [self setModalResultCode:NSOKButton];
  [super close:sender];
}

- (void)setVersions:(NSArray *)versions {
  /* make sure nib is loaded */
  [self window];
  
  [ibHeader setPadding:12 forPosition:kSKHeaderLeft];
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Versions"];
  NSUInteger idx = [versions count];
  while (idx-- > 0) {
    SKUpdaterVersion *version = [versions objectAtIndex:idx];
    NSString *title = (id)SKVersionCreateStringForNumber([version version]);
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ Release Notes", title] action:nil keyEquivalent:@""];
    [item setRepresentedObject:version];
    [menu addItem:item];
    [title release];
    [item release];
  }
  if (!se_versions) {
    se_versions = [[ibHeader addMenu:menu position:kSKHeaderLeft] retain];
    [se_versions setAction:@selector(selectVersion:)];
    [se_versions setTarget:self];
  } else {
    [se_versions setMenu:menu];
  }
  [menu release];
  
  [self selectVersion:se_versions];
  
  SKUpdaterVersion *last = [versions lastObject];
  CFStringRef vers = SKVersionCreateStringForNumber([last version]);
  [ibTitle setStringValue:[NSString stringWithFormat:@"A new version of %@ is available (%@)", [[NSProcessInfo processInfo] processName], vers]];
  CFRelease(vers);
}

- (void)setSelectedVersion:(SKUpdaterVersion *)aVersion {
  [se_versions selectItemAtIndex:[se_versions indexOfItemWithRepresentedObject:aVersion]];
}

- (IBAction)selectVersion:(id)sender {
  NSMenuItem *select = [sender selectedItem];
  id history = [[select representedObject] history];
  if ([history isKindOfClass:[NSURL class]]) {
    NSURLRequest *request = [NSURLRequest requestWithURL:history
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    [[ibHistory mainFrame] loadRequest:request];
  } else {
    [[ibHistory mainFrame] loadHTMLString:history baseURL:nil];
  }
}

#pragma mark WebView delegate
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
  NSNumber *type = [actionInformation objectForKey:WebActionNavigationTypeKey];
  switch (SKIntegerValue(type)) {
    case WebNavigationTypeLinkClicked:
    case WebNavigationTypeFormSubmitted:
    case WebNavigationTypeFormResubmitted:
      [[NSWorkspace sharedWorkspace] openURL:[request URL]];
      [listener ignore];
      break;
    default:
      [listener use];
      break;
  }
}

@end
