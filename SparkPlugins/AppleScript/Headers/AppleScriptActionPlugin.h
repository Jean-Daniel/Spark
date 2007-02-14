/*
 *  AppleScriptActionPlugin.h
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2006, Shadow Lab. All rights reserved.
 */

#import <SparkKit/SparkPluginAPI.h>

@interface AppleScriptActionPlugin : SparkActionPlugIn {
  IBOutlet id ibScript;
  @private
    NSString *as_file;
  int as_tidx;
}

- (IBAction)compile:(id)sender;

- (IBAction)run:(id)sender;
- (IBAction)open:(id)sender;
- (IBAction)import:(id)sender;

- (IBAction)launchEditor:(id)sender;

- (NSAlert *)compileScript:(NSAppleScript *)script;

- (NSString *)scriptFile;
- (void)setScriptFile:(NSString *)aFile;

- (int)selectedTab;
- (void)setSelectedTab:(int)tab;

@end

@interface SourceView : NSTextView {
}
- (NSString *)source;
- (void)setSource:(NSString *)src;
@end
