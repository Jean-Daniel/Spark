/* AppleScriptActionPlugin */

#import <SparkKit/SparkKit.h>
#import <Cocoa/Cocoa.h>

extern NSString * const kASActionBundleIdentifier;

#define AppleScriptActionBundle		[NSBundle bundleWithIdentifier:kASActionBundleIdentifier]

@interface AppleScriptActionPlugin : SparkActionPlugIn {
  IBOutlet id textView;
  id attr;
  id _script;
  id _scriptFile;
  
  int tabIndex;
}

- (IBAction)checkSyntax:(id)sender;
- (IBAction)run:(id)sender;
- (IBAction)open:(id)sender;
- (IBAction)import:(id)sender;

- (IBAction)launchEditor:(id)sender;

- (NSAlert *)checkSyntax;
- (NSAlert *)compileScript:(NSAppleScript *)script;
- (NSAlert *)alertForScriptError:(NSDictionary *)errors;

- (void)setAttributes;

- (id)script;
- (void)setScript:(id)newScript;

- (id)scriptFile;
- (void)setScriptFile:(id)newScriptFile;

@end

@interface SourceView : NSTextView {
}
@end