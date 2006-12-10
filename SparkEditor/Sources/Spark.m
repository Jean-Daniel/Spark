/*
 *  Spark.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) Shadow Lab. 2004 - 2006. All rights reserved.
 */

#import "Spark.h"

#import "SEPluginInstaller.h"

#if defined (DEBUG)
#import "SEEntryEditor.h"
#import "SETriggerBrowser.h"
#import <Foundation/NSDebug.h>
#endif

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkActionLoader.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

#import "SEPluginHelp.h"
#import "SEPreferences.h"
#import "SELibraryWindow.h"
#import "SEEntriesManager.h"
#import "SEServerConnection.h"


const UInt32 kSparkVersion = 0x030000; /* 3.0.0 */

int main(int argc, const char *argv[]) {
#if defined(DEBUG)
  NSDebugEnabled = YES;
  NSHangOnUncaughtException = YES;
//  SparkLibraryFileFormat = NSPropertyListXMLFormat_v1_0;
#endif
  return NSApplicationMain(argc, argv);
}

NSArray *gSortByNameDescriptors = nil;
NSString * const SparkTriggerListPboardType = @"SparkTriggerListPboardType";
NSString * const SESparkEditorDidChangePluginStatusNotification = @"SESparkEditorDidChangePluginStatus";

@implementation SparkEditor 

/* Create shared sort descriptor */
+ (void)initialize {
  if ([SparkEditor class] == self) {
    NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    gSortByNameDescriptors = [[NSArray alloc] initWithObjects:desc, nil];
    [desc release];
  }
}

/* Initialize daemon status */
- (id)init {
  if (self = [super init]) {
    se_status = kSparkDaemonStopped;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePlugins:)
                                                 name:SESparkEditorDidChangePluginStatusNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePlugins:)
                                                 name:SparkActionLoaderDidRegisterPlugInNotification
                                               object:nil];
    /* Force script system initialization */
    [NSScriptSuiteRegistry sharedScriptSuiteRegistry];
  }
  return self;
}

- (void)dealloc {
  [se_plugins release];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

/* Intercepts help keydown events */
- (void)sendEvent:(NSEvent *)event {
  if (([event type] == NSKeyDown || [event type] == NSKeyUp) && [event keyCode] == kVirtualHelpKey) {
    id window = [self keyWindow];
    if ([window respondsToSelector:@selector(isTrapping)] && [window isTrapping]) {
      [window sendEvent:event];
      return;
    }
  } 
  [super sendEvent:event];
}

- (void)populateMenu:(NSMenu *)menu {
  NSArray *plugins = [[[SparkActionLoader sharedLoader] plugins] sortedArrayUsingDescriptors:gSortByNameDescriptors];
  
  SparkPlugIn *plugin;
  NSEnumerator *items = [plugins objectEnumerator];
  int idx = 1;
  while (plugin = [items nextObject]) {
    if ([plugin isEnabled]) {
      NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[plugin name] action:@selector(newTriggerFromMenu:) keyEquivalent:@""];
      NSImage *icon = [[plugin icon] copy];
      if (icon) {
        [icon setScalesWhenResized:YES];
        [icon setSize:NSMakeSize(16, 16)];
        [item setImage:icon];
        [icon release];
      }
      [item setRepresentedObject:plugin];
      if (idx < 10) 
        [item setKeyEquivalent:[NSString stringWithFormat:@"%i", idx++]];
      [menu addItem:item];
      [item release];
    }
  }
}

- (NSMenu *)pluginsMenu {
  if (!se_plugins) {
    se_plugins = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"NEW_TRIGGER_MENU", @"New Trigger Menu Title")];
    [self populateMenu:se_plugins];
  }
  return se_plugins;
}

- (void)didChangePlugins:(NSNotification *)aNotification {
  if (se_plugins) {
    unsigned count = [se_plugins numberOfItems];
    while (count-- > 0) {
      [se_plugins removeItemAtIndex:count];
    }
    [self populateMenu:se_plugins];
  }
}

@end

#pragma mark -
@implementation Spark

#pragma mark Init And Destroy
- (id)init {
  if (self = [super init]) {
#if defined (DEBUG)
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
      //@"YES", @"NSShowNonLocalizedStrings",
      //@"YES", @"NSShowAllViews",
      //SKFloat(0.15f), @"NSWindowResizeTime",
      //@"6", @"NSDragManagerLogLevel",
      //@"YES", @"NSShowNonLocalizableStrings",
      //@"1", @"NSScriptingDebugLogLevel",
      nil]];
#endif
    /* Register Built-in plugin */

    
    /* First load Library */
    SparkLibrary *library = SparkSharedLibrary();
    /* Get default library path */
    NSString *path = [library path];
    /* If library does not exist, check for previous version library */
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
      NSString *old = [SparkLibraryFolder() stringByAppendingPathComponent:@"SparkLibrary.splib"];
      /* If old library exists, load it, and resave it into new format */
      if ([[NSFileManager defaultManager] fileExistsAtPath:old]) {
        [library setPath:old];
        [library readLibrary:nil];
        [library setPath:path];
        [library synchronize];
      }
    } else if (![library readLibrary:nil]) {
      // Run alert panel
      DLog(@"Cannot read library");
    }
  
    /* Register defaults */
    [SEPreferences setup];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [se_mainWindow release];
  [super dealloc];
}

- (void)awakeFromNib {
#if defined (DEBUG)
  [self createDebugMenu];
#endif
  [self createAboutMenu];
  
  NSMenu *file = [[[NSApp mainMenu] itemWithTag:1] submenu];
  [file setSubmenu:[NSApp pluginsMenu] forItem:[file itemWithTag:1]];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePlugins:)
                                               name:SESparkEditorDidChangePluginStatusNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePlugins:)
                                               name:SparkActionLoaderDidRegisterPlugInNotification
                                             object:nil];
  
  /* Register for server status event and start connection */
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(serverStatusDidChange:)
                                               name:SEServerStatusDidChangeNotification
                                             object:nil];
  /* Check daemon path and connect */
  SEServerStartConnection();
  
  [self showMainWindow:nil];
  [self displayFirstRunIfNeeded];
}

- (void)serverStatusDidChange:(NSNotification *)aNotification {
  SparkDaemonStatus status = [[aNotification object] serverStatus];
  NSString *title = nil;
  if (kSparkDaemonStarted != status)
    title = NSLocalizedString(@"ACTIVE_SPARK_MENU", 
                              @"Spark Daemon Menu Title * Active *");
  else
    title = NSLocalizedString(@"DEACTIVE_SPARK_MENU", 
                              @"Spark Daemon Menu Title * Desactive *");
  [statusMenuItem setTitle:title];
}

#pragma mark -
#pragma mark Menu IBActions
- (IBAction)revert:(id)sender {
  [[NSAlert alertWithMessageText:@"You are about to revert all changed perform since Spark Launch."
                   defaultButton:@"Revert"
                 alternateButton:@"Cancel"
                     otherButton:nil
       informativeTextWithFormat:@"Revert will restore your database."] beginSheetModalForWindow:[self mainWindow]
                                                 modalDelegate:self
                                                didEndSelector:@selector(revertPanelDidEnd:returnCode:contextInfo:)
                                                   contextInfo:nil];
}

- (void)revertPanelDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
  if (NSOKButton == returnCode) {
    NSError *error = nil;
    [SparkSharedLibrary() readLibrary:&error];
    if (error) {
      [[NSAlert alertWithError:error] runModal];
    } else {
      [[SEEntriesManager sharedManager] reload];
      [[NSNotificationCenter defaultCenter] postNotificationName:@"SEDidReloadLibrary"
                                                          object:nil];
    }
    if ([NSApp serverStatus] == kSparkDaemonStarted) {
      [[SEServerConnection defaultConnection] restart];
    }
  }
}


- (IBAction)toggleServer:(id)sender {
  if ([NSApp serverStatus] == kSparkDaemonStarted) {
    [[SEServerConnection defaultConnection] shutdown];
  } else {
    SELaunchSparkDaemon();
  }
}

- (NSWindow *)mainWindow {
  return [se_mainWindow window];
}

- (IBAction)showPreferences:(id)sender {
  SEPreferences *preferences = [[SEPreferences alloc] init];
  [preferences setReleasedWhenClosed:YES];
  [NSApp beginSheet:[preferences window]
     modalForWindow:[self mainWindow]
      modalDelegate: nil
     didEndSelector: nil
        contextInfo: nil];
}

- (IBAction)showMainWindow:(id)sender {
  if (!se_mainWindow) {
    se_mainWindow = [[SELibraryWindow alloc] init];
    [[se_mainWindow window] setDelegate:self];
  }
  [se_mainWindow showWindow:nil];
}

#pragma mark -
#pragma mark Import/Export Support

//- (IBAction)importLibrary:(id)sender {
//  NSOpenPanel *panel = [NSOpenPanel openPanel];
//  [panel setCanChooseDirectories:NO];
//  [panel setCanCreateDirectories:NO];
//  [panel setAllowsMultipleSelection:NO];
//  int result = [panel runModalForTypes:[NSArray arrayWithObjects:
//    kSparkLibraryFileExtension,
//    kSparkListFileExtension,
//    NSFileTypeForHFSTypeCode(kSparkListFileType),
//    nil]];
//  if (result == NSOKButton) {
//    [self application:NSApp openFile:[[panel filenames] objectAtIndex:0]];
//  }
//}

#pragma mark -
#pragma mark PlugIn Help Support
- (IBAction)showPlugInHelp:(id)sender {
  [[SEPluginHelp sharedPluginHelp] showWindow:sender];
}

- (void)showPlugInHelpPage:(NSString *)page {
  [[SEPluginHelp sharedPluginHelp] setPage:page];
  [[SEPluginHelp sharedPluginHelp] showWindow:self];
}

#pragma mark -
#pragma mark Live Update Support
//- (IBAction)checkForNewVersion:(id)sender {
//  NSString *currVersionNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
//  NSDictionary *productVersionDict = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:NSLocalizedStringFromTable(@"UPDATE_FILE_URL",
//                                                                                                                               @"Update", @"Url of the update file (.xml or .plist). Do not localize.")]];
//  NSString *latestVersionNumber = [productVersionDict valueForKey:@"Spark"];
//  if (latestVersionNumber == nil) {
//    NSBeginAlertSheet(NSLocalizedStringFromTable(@"UPDATE_CHECKING_ERROR",
//                                                 @"Update", @"Check Update Error * Title *"),
//                      NSLocalizedStringFromTable(@"OK",
//                                                 @"Update", @"Alert default button"),
//                      nil, nil, [libraryWindow window],
//                      nil, nil, nil, nil,
//                      NSLocalizedStringFromTable(@"UPDATE_CHECKING_ERROR_MSG",
//                                                 @"Update", @"Check Update Error * Msg * (Replace ChezJD by the web Site URL)"));
//    return;
//  }
//  if([latestVersionNumber isEqualTo:currVersionNumber])
//  {
//    NSBeginAlertSheet(NSLocalizedStringFromTable(@"SOFTWARE_UP_TO_DATE_NOTIFICATION",
//                                                 @"Update", @"When a the user's software is up to date. * Title *"),
//                      NSLocalizedStringFromTable(@"OK",
//                                                 @"Update", @"Alert default button"),
//                      nil, nil, [libraryWindow window],
//                      nil, nil, nil, nil,
//                      NSLocalizedStringFromTable(@"SOFTWARE_UP_TO_DATE_NOTIFICATION_MSG",
//                                                 @"Update", @"When a the user's software is up to date. * Msg *"));
//  }
//  else {
//    id alert = [NSAlert alertWithMessageText:NSLocalizedStringFromTable(@"CONFIRM_GO_TO_UPDATE_PAGE",
//                                                                        @"Update", @"New version available")
//                               defaultButton:NSLocalizedStringFromTable(@"CONFIRM_GO_TO_UPDATE_PAGE_YES",
//                                                                        @"Update", @"New version available * default button *")
//                             alternateButton:NSLocalizedStringFromTable(@"CONFIRM_GO_TO_UPDATE_PAGE_CANCEL",
//                                                                        @"Update", @"New version available * cancel button *")
//                                 otherButton:nil
//                   informativeTextWithFormat:NSLocalizedStringFromTable(@"CONFIRM_GO_TO_UPDATE_PAGE_MSG",
//                                                                        @"Update", @"New version available * msg *"), latestVersionNumber];
//    [alert beginSheetModalForWindow:[libraryWindow window]
//                      modalDelegate:self
//                     didEndSelector:@selector(checkUpdateAlertDidEnd:returnCode:contextInfo:)
//                        contextInfo:nil];
//  }
//}

//- (void)checkUpdateAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(NSDictionary *)plist {
//  if(NSAlertDefaultReturn == returnCode) {
//    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedStringFromTable(@"UPDATE_PAGE_URL",
//                                                                                           @"Update", @"The url of the update page. Do not localize.")]];
//  }
//}

#pragma mark -
#pragma mark Open File & Sheet Did End
//- (BOOL)openList:(NSString *)filename {
//  id plist = nil;
//  id data = [[NSData alloc] initWithContentsOfFile:filename];
//  if (data) {
//    plist = [NSPropertyListSerialization propertyListFromData:data 
//                                             mutabilityOption:kCFPropertyListMutableContainersAndLeaves
//                                                       format:nil
//                                             errorDescription:nil];
//    [data release];
//  }
//  if (plist) {
//    SparkImporter *import = [[SparkImporter alloc] init];
//    [import setSerializedList:plist];
//    [NSApp beginSheet: [import window]
//       modalForWindow: [libraryWindow window]
//        modalDelegate: self
//       didEndSelector: @selector(sheetDidEnd:returnCode:context:)
//          contextInfo: nil];
//    return YES;
//  }
//  return NO;
//}

//- (BOOL)openPlugin:(NSString *)filename {
//  /* Verifier que le plugin n'est pas déjà installé.
//  • Si installé => Si version supérieur, proposer de remplacer, redémarrer server, demander de redémarrer éditeur.
//  • Si non installé => Proposer d'installer dans ≠ domaines (Utilisateur et ordinateur).
//  */
//  id installer = nil;
//  CFBundleRef dest = nil;
//  CFBundleRef src = CFBundleCreate(kCFAllocatorDefault, (CFURLRef)[NSURL fileURLWithPath:filename]);
//  if (!src) {
//    DLog(@"Unable to open bundle: %@", filename);
//    return NO;
//  }
//  id identifier = (id)CFBundleGetIdentifier(src);
//  
//  id plugins = [[[SparkActionLoader sharedLoader] plugins] objectEnumerator];
//  id plugin;
//  while (plugin = [plugins nextObject]) {
//    if ([identifier isEqualToString:[plugin bundleIdentifier]]) {
//      break;
//    }
//  }
//  if (plugin) {
//    dest = CFBundleCreate(kCFAllocatorDefault, (CFURLRef)[NSURL fileURLWithPath:[plugin path]]);
//  }
//  if (dest) {
//    UInt32 srcVersion = 0, destVersion = 0;
//    srcVersion = CFBundleGetVersionNumber(src);
//    destVersion = CFBundleGetVersionNumber(dest);
//    
//    if (srcVersion <= destVersion) {
//      NSBeginAlertSheet(NSLocalizedString(@"MORE_RECENT_PLUGIN_INSTALLED_ALERT",
//                                          @"More Recent plugin installed"),
//                        NSLocalizedString(@"OK",
//                                          @"Alert default button"),
//                        nil, nil, [libraryWindow window],
//                        nil, nil, nil, nil,
//                        NSLocalizedString(@"MORE_RECENT_PLUGIN_INSTALLED_ALERT_MSG",
//                                          @"More Recent plugin installed"));
//    } else {
//      /* Replace plugin */
//      installer = [[PluginInstaller alloc] init];
//      [installer setSource:src];
//      [installer setDestination:dest];
//    }
//  } else {
//    /* Install New Plugin */
//    installer = [[PluginInstaller alloc] init];
//    [installer setSource:src];
//  }
//  if (installer) {
//    [NSApp beginSheet:[installer window]
//       modalForWindow:[libraryWindow window]
//        modalDelegate:self
//       didEndSelector:@selector(sheetDidEnd:returnCode:context:)
//          contextInfo:nil];
//  }
//  if (src) { CFRelease(src); }
//  if (dest) { CFRelease(dest); }
//  return YES;
//}

//- (BOOL)openLibrary:(NSString *)filename {
//  SparkLibrary *lib = [[SparkLibrary  alloc] initWithPath:filename];
//  if (!lib) {
//    return NO;
//  }
//  
//  id alert = [NSAlert alertWithMessageText:NSLocalizedString(@"CHOOSE_IMPORT_LIBRARY_ACTION",
//                                                             @"Open Spark Library * Title *")
//                             defaultButton:NSLocalizedString(@"CHOOSE_IMPORT_LIBRARY_ACTION_MERGE",
//                                                             @"Open Spark Library")
//                           alternateButton:NSLocalizedString(@"CHOOSE_IMPORT_LIBRARY_ACTION_RESTORE",
//                                                             @"Open Spark Library")
//                               otherButton:NSLocalizedString(@"CHOOSE_IMPORT_LIBRARY_ACTION_CANCEL",
//                                                             @"Open Spark Library")
//                 informativeTextWithFormat:NSLocalizedString(@"CHOOSE_IMPORT_LIBRARY_ACTION_MSG",
//                                                             @"Open Spark Library * Msg *"), [filename lastPathComponent]];
//  int result = [alert runSheetModalForWindow:[libraryWindow window]];
//  if (NSAlertOtherReturn == result) {
//    return YES;
//  } else if (NSAlertAlternateReturn == result) {
//    BOOL running = ([self serverState] == kSparkDaemonStarted);
//    if (running) [[ServerController sharedController] shutDownServer];
//    [SparkLibrary setDefaultLibrary:lib];
//    alert = [NSAlert alertWithMessageText:NSLocalizedString(@"LIBRARY_RESTORED_NOTIFICATION",
//                                                            @"Open Spark Library * Title *")
//                            defaultButton:NSLocalizedString(@"LIBRARY_RESTORED_NOTIFICATION_RESTART",
//                                                            @"Open Spark Library")
//                          alternateButton:nil
//                              otherButton:nil
//                informativeTextWithFormat:@""];
//    [alert runSheetModalForWindow:[libraryWindow window]];
//    
//    if (running) [[ServerController sharedController] startServer];
//    [Spark restartSpark];
//    return YES;
//  } else if (NSAlertDefaultReturn == result) {
//    SparkImporter *import = [[SparkImporter alloc] init];
//    [import setLibrary:lib];
//    [NSApp beginSheet: [import window]
//       modalForWindow: [libraryWindow window]
//        modalDelegate: self
//       didEndSelector: @selector(sheetDidEnd:returnCode:context:)
//          contextInfo: nil];
//  }
//  [lib release];
//  return YES;
//}

#pragma mark -
#pragma mark Windows Delegate
- (void)windowWillClose:(NSNotification *)aNotification {
//  [se_mainWindow saveWorkspace];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [NSApp terminate:nil];
}

- (BOOL)windowShouldClose:(id)sender {
  return YES;
}

#pragma mark -
#pragma mark Application Delegate
- (void)openPluginBundle:(NSString *)path {
  SEPluginInstaller *panel = [[SEPluginInstaller alloc] init];
  [panel setReleasedWhenClosed:YES];
  [panel setPlugin:path];
  [NSApp beginSheet:[panel window]
     modalForWindow:[self mainWindow]
      modalDelegate:self
     didEndSelector:NULL
        contextInfo:nil];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
  if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:filename]) {
    if ([[filename pathExtension] isEqualToString:[SparkActionLoader extension]]) {
      [self openPluginBundle:filename];
      return YES;
    }
    //    else if ([[filename pathExtension] isEqualToString:kSparkLibraryFileExtension]) {
    //      if ([self openLibraryFile:filename])
    //        return YES;
    //    }
  } else {
//    OSType type = [[[NSFileManager defaultManager] fileAttributesAtPath:filename traverseLink:NO] fileHFSTypeCode];
//    if ([[filename pathExtension] isEqualToString:kSparkListFileExtension] || type == kSparkListFileType) { // Il faudrait aussi verifier le type.
//      if ([self openListFile:filename])
//        return YES;
//    }
  }
//  NSAlert *error = [NSAlert alertWithMessageText:
//    [NSString stringWithFormat:NSLocalizedString(@"INVALID_FILE_ALERT",
//                                                 @"Import failed (%@ => filename) * Title *"), [filename lastPathComponent]]
//                                   defaultButton:NSLocalizedString(@"OK", @"Alert default button") 
//                                 alternateButton:nil
//                                     otherButton:nil
//                       informativeTextWithFormat:NSLocalizedString(@"INVALID_FILE_ALERT_MSG",
//                                                                   @"Open failed * Msg *")];
//  [error beginSheetModalForWindow:[se_mainWindow window]
//                    modalDelegate:nil
//                   didEndSelector:nil
//                      contextInfo:nil];
  return NO;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  [SEPreferences synchronize];
  [SparkSharedLibrary() synchronize];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
  return YES;
}

#pragma mark -
#pragma mark About Plugins Menu

- (void)createAboutMenu {
  unsigned count = [aboutMenu numberOfItems];
  while (count-- > 0) {
    [aboutMenu removeItemAtIndex:count];
  }
  
  NSArray *items = [[[SparkActionLoader sharedLoader] plugins] sortedArrayUsingDescriptors:gSortByNameDescriptors];
  
  SparkPlugIn *plugin;
  NSEnumerator *plugins = [items objectEnumerator];
  while (plugin = [plugins nextObject]) {
    if ([plugin isEnabled]) {
      NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"ABOUT_PLUGIN_MENU_ITEM",
                                                                                                            @"About Plugin (%@ => Plugin name)"), [plugin name]]
                                                        action:@selector(aboutPlugin:) keyEquivalent:@""];
      [menuItem setImage:[plugin icon]];
      [menuItem setRepresentedObject:plugin];
      [aboutMenu addItem:menuItem];
      [menuItem release];
    }
  }
}

- (void)didChangePlugins:(NSNotification *)sender {
  [self createAboutMenu];
}

- (IBAction)aboutPlugin:(id)sender {
  SparkPlugIn *plugin = [sender representedObject];
  NSMutableDictionary *opts = [NSMutableDictionary dictionary];
  
  [opts setObject:[NSString stringWithFormat:NSLocalizedString(@"ABOUT_PLUGIN_BOX_TITLE", 
                                                               @"About Plugin (%@ => Plugin name)"), [plugin name]] 
           forKey:@"ApplicationName"];
  NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[plugin path]];
  [icon setSize:NSMakeSize(64, 64)];
  [opts setObject:icon forKey:@"ApplicationIcon"];
  NSBundle *bundle = [NSBundle bundleWithPath:[plugin path]];
  
  NSString *credits = nil;
  if ((credits = [bundle pathForResource:@"Credits" ofType:@"html"]) ||
      (credits = [bundle pathForResource:@"Credits" ofType:@"rtf"]) ||
      (credits = [bundle pathForResource:@"Credits" ofType:@"rtfd"])) {
    NSAttributedString *str = [[NSAttributedString alloc] initWithURL:[NSURL fileURLWithPath:credits] documentAttributes:nil];
    [opts setObject:str forKey:@"Credits"];
    [str release];
  } else {
    [opts setObject:@"" forKey:@"Credits"];
  }
  
  id value = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
  [opts setObject:(value) ? value : @"" forKey:@"Version"];
  value = [bundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"];
  [opts setObject:(value) ? value : @"" forKey:@"Copyright"];
  value = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  [opts setObject:(value) ? value : @"" forKey:@"ApplicationVersion"];
  [NSApp orderFrontStandardAboutPanelWithOptions:opts];
}

#pragma mark -
#pragma mark Debug Menu

#if defined (DEBUG)
- (void)createDebugMenu {
  id debugMenu = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
  id menu = [[NSMenu alloc] initWithTitle:@"Debug"];
  [menu addItemWithTitle:@"Importer" action:@selector(openImporter:) keyEquivalent:@""];
  [menu addItemWithTitle:@"Trigger Browser" action:@selector(openTriggerBrowser:) keyEquivalent:@""];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItemWithTitle:@"Clean Library" action:@selector(cleanLibrary:) keyEquivalent:@""];
  [debugMenu setSubmenu:menu];
  [menu release];
  [[NSApp mainMenu] insertItem:debugMenu atIndex:[[NSApp mainMenu] numberOfItems] -1];
  [debugMenu release];
}

- (IBAction)openTriggerBrowser:(id)sender {
  SETriggerBrowser *browser = [[SETriggerBrowser alloc] init];
  [browser setReleasedWhenClosed:YES];
  [browser showWindow:sender];
}

//- (IBAction)openImporter:(id)sender {
//  if (libraryWindow) {
//    SparkImporter *panel = [[SparkImporter alloc] init];
//    id lib = [[SparkLibrary alloc] initWithPath:[SparkDefaultLibrary() file]];
//    [panel setLibrary:lib];
//    [lib release];
//    [NSApp beginSheet: [panel window]
//       modalForWindow: [libraryWindow window]
//        modalDelegate: self
//       didEndSelector: @selector(sheetDidEnd:returnCode:context:)
//          contextInfo: nil];
//  }
//}
//

#endif

@end
