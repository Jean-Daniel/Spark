//
//  KeyListExporter.m
//  Spark
//
//  Created by Fox on Fri Feb 27 2004.
//  Copyright (c) 2004 Shadow Lab. All rights reserved.
//
#import <SparkKit/SparkKit.h>
#import "LibraryWindowController.h"

#import "Spark.h"
#import "SparkExporter.h"
#import "LibraryController.h"
#import "InspectorController.h"
#import "KeyLibraryController.h"

@interface Spark (ExportExtensions)
- (unsigned)exportFormat;
- (void)setExportFormat:(unsigned)newExportFormat;
- (void)exportSparkList:(SparkObjectList *)list modalForWindow:(NSWindow *)window;
@end

@implementation Spark (ExportExtensions)

- (NSSavePanel *)exportPanel {
  id panel = [NSSavePanel savePanel];
  [panel setCanSelectHiddenExtension:YES];
  [panel setTreatsFilePackagesAsDirectories:YES];
  [panel setCanCreateDirectories:YES];
  return panel;
}

- (IBAction)exportLibrary:(id)sender {
  id panel = [self exportPanel];
  [panel setRequiredFileType:kSparkLibraryFileExtension];
  [panel beginSheetForDirectory:nil
                           file:NSLocalizedString(@"EXPORT_LIBRARY_NAME", @"Export Library - Default name")
                 modalForWindow:[libraryWindow window]
                  modalDelegate:self
                 didEndSelector:@selector(backupPanelDidEnd:returnCode:contextInfo:)
                    contextInfo:nil];
}

- (void)exportSparkList:(SparkObjectList *)list modalForWindow:(NSWindow *)window {
  id panel = [self exportPanel];
  [self setExportFormat:kSparkListFormat];
  if ([[list contentType] isSubclassOfClass:[SparkHotKey class]]) {
    [panel setAccessoryView:exportView];
  }
  [panel setRequiredFileType:kSparkListFileExtension];
  [panel beginSheetForDirectory:nil
                           file:[NSString stringWithFormat:NSLocalizedString(@"EXPORT_LIST_NAME", @"Export List default name (%@ => list name)"), [list name]]
                 modalForWindow:window
                  modalDelegate:self
                 didEndSelector:@selector(exportPanelDidEnd:returnCode:contextInfo:)
                    contextInfo:list];
}

- (void)backupPanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(SparkObjectList *)list {
  if (returnCode == NSOKButton) {
    @try {
      [SparkDefaultLibrary() writeToFile:[sheet filename] atomically:YES];
    }
    @catch (id exception) {
      SKLogException(exception);
    }
  }
}

- (void)exportPanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(SparkObjectList *)list {
  if (returnCode == NSOKButton) {
    SparkExporter *exporter = [(SparkExporter *)[SparkExporter alloc] initWithFormat:exportFormat];
    @try {
      if (list) {
        [exporter exportList:list
                      toFile:[sheet filename]];
      }
    }
    @catch (id exception) {
      SKLogException(exception);
    }
  }
  [self setValue:SKInt(0) forKey:@"exportFormat"];
}

- (unsigned)exportFormat {
  return exportFormat;
}

- (void)setExportFormat:(unsigned)newExportFormat {
  if (exportFormat != newExportFormat) {
    exportFormat = newExportFormat;
    id type = nil;
    switch (exportFormat) {
      case kSparkListFormat:
        type = kSparkListFileExtension;
        break;
      case kHTMLFormat:
        type = @"html";
        break;
    }
    [(NSSavePanel *)[exportView window] setRequiredFileType:type];
  }
}

@end

@interface LibraryWindowController (SparkExportList)
- (IBAction)exportList:(id)sender;
@end

@implementation LibraryWindowController (SparkExportList)
- (IBAction)exportList:(id)sender {
  id list = [keyLibrary selectedList];
  [[NSApp delegate] exportSparkList:list modalForWindow:[self window]];
}
@end

@interface InspectorController (SparkExportList)
- (IBAction)exportList:(id)sender;
@end

@implementation InspectorController (SparkExportList)
- (IBAction)exportList:(id)sender {
  id list = [[self frontLibrary] selectedList];
  [[NSApp delegate] exportSparkList:list modalForWindow:[self window]];
}
@end

