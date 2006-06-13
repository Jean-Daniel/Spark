
#import <SparkKit/SparkKit.h>
#import "PluginHelpController.h"

@implementation PlugInHelpController

- (id)init {
  if (self = [super initWithWindowNibName:@"PluginHelp"]) {
    
  }
  return self;
}

- (void)awakeFromNib {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPlugInMenu:) name:SKPluginLoaderDidLoadPluginNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPlugInMenu:) name:SKPluginLoaderDidRemovePluginNotification object:nil];
  [[self window] setFrameUsingName:@"PlugInsHelpWindow"];
  [self reloadPlugInMenu:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

- (IBAction)reloadPlugInMenu:(id)sender {
  [popupMenu removeAllItems];
  
  id menu = [popupMenu menu];
  id desc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
  id plugIns = [[[SparkActionLoader sharedLoader] plugins] sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
  [desc release];
  plugIns = [plugIns objectEnumerator];
  id plugIn;
  while (plugIn = [plugIns nextObject]) {
    id helpFile = [[plugIn principalClass] helpFile];
    if (helpFile) {
      id menuItem = [[NSMenuItem alloc] initWithTitle:[plugIn valueForKey:@"name"] action:@selector(showHelp:) keyEquivalent:@""];
      [menuItem setTarget:self];
      [menuItem setImage:[plugIn valueForKey:@"icon"]];
      [menuItem setRepresentedObject:[[NSURL fileURLWithPath:helpFile] absoluteString]];
      [menu addItem:menuItem];
      [menuItem release];
    }
  }
  if ([menu numberOfItems])
    [self showHelp:[menu itemAtIndex:0]];
}

- (IBAction)showHelp:(id)sender {
  [[helpView backForwardList] setCapacity:0];
  [helpView setValue:[sender representedObject] forKey:@"mainFrameURL"];
  [[helpView backForwardList] setCapacity:10];
}

- (void)setHelpPage:(NSString *)plugInName {
  int i = [popupMenu indexOfItemWithTitle:plugInName];
  if (i != -1) {
    [popupMenu selectItemAtIndex:i];
  }
  [self showHelp:[popupMenu selectedItem]]; 
}

- (void)windowWillClose:(NSNotification *)aNotification {
  [[self window] saveFrameUsingName:@"PlugInsHelpWindow"];
}

@end
