/* PlugInHelpController */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface PlugInHelpController : NSWindowController {
    IBOutlet WebView *helpView;
    IBOutlet NSPopUpButton *popupMenu;
}

- (IBAction)reloadPlugInMenu:(id)sender;
- (IBAction)showHelp:(id)sender;

- (void)setHelpPage:(NSString *)plugInName;

@end
