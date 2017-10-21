//
//  AXAPlugin.h
//  Spark Plugins
//
//  Created by Jean-Daniel Dupas on 27/11/08.
//  Copyright 2008 Ninsight. All rights reserved.
//

#import <SparkKit/SparkKit.h>

@interface AXActionPlugIn : SparkActionPlugIn {
@private
  IBOutlet NSPopUpButton *uiMenus;
  IBOutlet NSPopUpButton *uiApplications;
  
  IBOutlet NSTextField *uiTitle, *uiSubtitle;
}

- (IBAction)selectApplication:(NSPopUpButton *)sender;

- (IBAction)chooseMenuItem:(NSMenuItem *)sender;

@end
