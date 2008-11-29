/*
 *  Spark.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "Spark.h"

#import "SEPluginInstaller.h"

#if defined (DEBUG)
#import "SEEntryEditor.h"
#import <Foundation/NSDebug.h>
#import <SparkKit/SparkLibrarySynchronizer.h>
#endif

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkActionLoader.h>

#import WBHEADER(WBFunctions.h)
#import WBHEADER(WBFSFunctions.h)

#import <SUpdaterKit/SURestarter.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

#import "SEUpdater.h"
#import "SEPluginHelp.h"
#import "SEPreferences.h"
#import "SELibraryWindow.h"
#import "SELibraryDocument.h"
#import "SEServerConnection.h"
#import "SparkLibraryArchive.h"

int main(int argc, const char *argv[]) {
#if defined(DEBUG)
  HKTraceHotKeyEvents = YES;
  SparkLogSynchronization = YES;
  // SparkLibraryFileFormat = NSPropertyListXMLFormat_v1_0;
#endif
  return NSApplicationMain(argc, argv);
}

NSArray *gSortByNameDescriptors = nil;
NSString * const SparkEntriesPboardType = @"SparkEntriesPboardType";
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePlugins:)
                                                 name:SESparkEditorDidChangePluginStatusNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePlugins:)
                                                 name:SparkActionLoaderDidRegisterPlugInNotification
                                               object:nil];
#if defined(DYNAMIC_SDEF)
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleGetSDEFEvent:withReplyEvent:)
                                                     forEventClass:'ascr'
                                                        andEventID:'gsdf'];
#endif
    /* Force script system initialization */
    [NSScriptSuiteRegistry sharedScriptSuiteRegistry];
    
    /* Check update */
    
    /* Leopard Help hack */
//    if (WBSystemMajorVersion() == 10 && WBSystemMinorVersion() >= 5) {
//      HKHotKey *help = [[HKHotKey alloc] initWithKeycode:kHKVirtualHelpKey modifier:0];
//      [help setTarget:self];
//      [help setAction:@selector(handleHelpEvent:)];
//      [help setRegistred:YES];
//      /* NOTE: do not release 'help': an hotkey is unregistred when deallocated */
//    }
  }
  return self;
}
#if defined(DYNAMIC_SDEF)
- (void)handleGetSDEFEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
  NSError *error = nil;
  NSURL *sparkSdef = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SparkSuite" ofType:@"sdef"]];
  NSXMLDocument *definition = [[NSXMLDocument alloc] initWithContentsOfURL:sparkSdef
                                                                   options:NSXMLNodePreserveAll | NSXMLDocumentXInclude error:&error];
  if (!definition) {
    [NSApp presentError:error];
    return;
  }
  
  NSArray *plugins = [[SparkActionLoader sharedLoader] plugins];
  for (NSUInteger idx = 0; idx < [plugins count]; idx++) {
    SparkPlugIn *plugin = [plugins objectAtIndex:idx];
    NSString *sdef = [plugin sdefFile];
    if (sdef) {
      NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:sdef]
                                                                options:NSXMLNodePreserveAll | NSXMLDocumentXInclude error:&error];
      if (!doc) {
        DLog(@"Error while loading sdef from %@: %@", sdef, error);
      } else {
        NSXMLElement *root = [definition rootElement];
        NSArray *suites = [[doc rootElement] nodesForXPath:@"/dictionary/suite" error:&error];
        if (!suites) {
          DLog(@"Error while loading suites from %@: %@", sdef, error);
        } else {
          [suites makeObjectsPerformSelector:@selector(detach)];
          [root insertChildren:suites atIndex:[root childCount]];
        }
      }
    }
  }
  NSData *sdefData = [definition XMLDataWithOptions:NSXMLNodeCompactEmptyElement | NSXMLNodeUseDoubleQuotes];
  [replyEvent setDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeUTF8Text data:sdefData]
                 forKeyword:keyDirectObject];
}
#endif

- (void)handleHelpEvent:(id)sender {
  id window = [self keyWindow];
  if ([window respondsToSelector:@selector(isTrapping)] && [window isTrapping]) {
    [window handleHotKey:sender];
  } else {
    ProcessSerialNumber psn = {0, kCurrentProcess};
    HKEventTarget target = { psn: &psn };
    HKEventPostKeystrokeToTarget([sender keycode], [sender nativeModifier], target, kHKEventTargetProcess, NULL, kHKEventDefaultLatency);
  }
}

- (void)dealloc {
  [se_plugins release];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

/* Intercepts help keydown events */
- (void)sendEvent:(NSEvent *)event {
  if ([event type] == NSKeyDown || [event type] == NSKeyUp) {
    if ([event keyCode] == kHKVirtualHelpKey) {
      id window = [self keyWindow];
      if ([window respondsToSelector:@selector(isTrapping)] && [window isTrapping]) {
        [window sendEvent:event];
        return;
      }
    }
  }
  [super sendEvent:event];
}

- (NSMenu *)pluginsMenu {
  if (!se_plugins) {
    se_plugins = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"NEW_TRIGGER_MENU", @"New Trigger Menu Title")];
    SEPopulatePluginMenu(se_plugins);
  }
  return se_plugins;
}

- (void)didChangePlugins:(NSNotification *)aNotification {
  if (se_plugins) {
    NSUInteger count = [se_plugins numberOfItems];
    while (count-- > 0) {
      [se_plugins removeItemAtIndex:count];
    }
    SEPopulatePluginMenu(se_plugins);
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
      @"YES", @"NSShowNonLocalizedStrings",
      //@"YES", @"NSShowAllViews",
      //WBFloat(0.15f), @"NSWindowResizeTime",
      //@"6", @"NSDragManagerLogLevel",
      //@"YES", @"NSShowNonLocalizableStrings",
      //@"1", @"NSScriptingDebugLogLevel",
      nil]];
#endif
    
    /* Check active library sanity */
//    @try {
    SparkActiveLibrary();
//    } @catch (NSException *exception) {
//      WBLogException(exception);
//    }
    
    /* Register defaults */
    [SEPreferences setup];
    
    /* Check update */
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:kSEPreferencesAutoUpdate])
//      [[SEUpdater sharedUpdater] runInBackground];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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
}

- (void)serverStatusDidChange:(NSNotification *)aNotification {
  NSString *title = nil;
  if ([[SEServerConnection defaultConnection] isRunning]) {
    title = NSLocalizedString(@"STOP_SPARK_DAEMON_MENU", 
                              @"Spark Daemon Menu Title * Desactive *");
  } else {
    title = NSLocalizedString(@"START_SPARK_DAEMON_MENU", 
                              @"Spark Daemon Menu Title * Active *");  
  }
  
  [statusMenuItem setTitle:title];
}

#pragma mark -
#pragma mark Menu IBActions
- (IBAction)toggleServer:(id)sender {
  if ([[SEServerConnection defaultConnection] isRunning]) {
    [[SEServerConnection defaultConnection] shutdown];
  } else {
    SELaunchSparkDaemon(NULL);
  }
}

- (IBAction)showPreferences:(id)sender {
  if (!se_preferences) {
    se_preferences = [[SEPreferences alloc] init];
    [se_preferences setReleasedWhenClosed:NO];
  }
  [se_preferences showWindow:nil];
}

#pragma mark -
#pragma mark Import/Export Support


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

#pragma mark -
#pragma mark Application Delegate
- (void)openPluginBundle:(NSString *)path {
  SEPluginInstaller *panel = [[SEPluginInstaller alloc] init];
  [panel setReleasedWhenClosed:YES];
  [panel setPlugin:path];
  [NSApp runModalForWindow:[panel window]];
}

- (void)openLibraryBackup:(NSString *)file {
  SELibraryDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];
  if (!doc) {
    NSBeep();
  } else {
    [doc revertToBackup:file];
  }
}

- (BOOL)se_openDefaultLibrary {
  SELibraryDocument *doc = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"org.shadowlab.spark.library"];
  if (!doc)
    doc = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"SparkLibraryFile"];
  if (doc) {
    [[NSDocumentController sharedDocumentController] addDocument:doc];
    [doc setLibrary:SparkActiveLibrary()];
    [doc makeWindowControllers];
    [doc showWindows];
  }
  return doc != nil;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
  BOOL result = YES;
  if ([[[NSDocumentController sharedDocumentController] documents] count] == 0)
    [self se_openDefaultLibrary];
  if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:filename]) {
    if ([[filename pathExtension] isEqualToString:[[SparkActionLoader sharedLoader] extension]]) {
      [self openPluginBundle:filename];
    } else if ([[filename pathExtension] isEqualToString:kSparkLibraryFileExtension]) {
      DLog(@"Try to open a Spark Library: ignore");
      NSBeep();
    }
  } else {
    OSType type = kLSUnknownType;
    NSString *ext = [filename pathExtension];
    WBFSGetTypeAndCreatorAtPath((CFStringRef)filename, &type, NULL);
    if (type == kSparkLibraryArchiveHFSType || [ext isEqualToString:kSparkLibraryArchiveExtension]) {
      [self openLibraryBackup:filename];
    } else {
      result = NO;
    }
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
  return result;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
  return [self se_openDefaultLibrary];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  [SEPreferences synchronize];
  SEServerStopConnection();
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
  return YES;
}

#pragma mark -
#pragma mark About Plugins Menu
- (void)createAboutMenu {
  NSUInteger count = [aboutMenu numberOfItems];
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
      NSImage *img = [[plugin icon] copy];
      [img setScalesWhenResized:YES];
      [img setSize:NSMakeSize(16, 16)];
      [menuItem setImage:img];
      [img release];
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
  if ([plugin path]) {
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
  } else {
    [opts setObject:@"" forKey:@"Credits"];
    [opts setObject:@"" forKey:@"Version"];
  }
  
  [opts setObject:([plugin version] ? : @"") forKey:@"ApplicationVersion"];
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
  [menu addItemWithTitle:@"Dump Library" action:@selector(dumpLibrary:) keyEquivalent:@""];
  [menu addItemWithTitle:@"External Representation" action:@selector(dumpExternal:) keyEquivalent:@""];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItemWithTitle:@"Restart" action:@selector(restart:) keyEquivalent:@""];
  [debugMenu setSubmenu:menu];
  [menu release];
  [[NSApp mainMenu] insertItem:debugMenu atIndex:[[NSApp mainMenu] numberOfItems] -1];
  [debugMenu release];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRestart:) name:SURestarterApplicationDidRestartNotification object:nil];
}

- (void)didRestart:(NSNotification *)aNotification {
  NSRunAlertPanel([[NSString alloc] initWithData:[aNotification object] encoding:NSUTF8StringEncoding], @"", @"OK", nil, nil);
}

- (IBAction)restart:(id)sender {
  SURestarter *restarter = [[SURestarter alloc] initWithTargetPath:[[NSBundle mainBundle] bundlePath] error:nil];
  [restarter setData:[@"Hello wonderfull world!" dataUsingEncoding:NSUTF8StringEncoding]];
  
  [NSApp terminate:sender];
}

- (IBAction)dumpExternal:(id)sender {
//  NSMutableArray *library = [[NSMutableArray alloc] init];
//  SELibraryDocument *doc = SEGetDocumentForLibrary(SparkActiveLibrary());
//  SEEntryCache *cache = [doc cache];
//  SESparkEntrySet *entries = [cache entries];
//  
//  DLog(@"%@", [[doc application] externalRepresentation]);
//  
//  SparkEntry *entry;
//  NSEnumerator *iter = [entries entryEnumerator];
//  while (entry = [iter nextObject]) {
//    [library addObject:[entry externalRepresentation]];
//  }
//  
//  DLog(@"%@", library);
//  [library release];
}

- (IBAction)dumpLibrary:(id)sender {
  SparkDumpEntries(SparkActiveLibrary());
//  NSMutableArray *library = [[NSMutableArray alloc] init];
//  SELibraryDocument *doc = SEGetDocumentForLibrary(SparkActiveLibrary());
//  SEEntryCache *cache = [doc cache];
//  SESparkEntrySet *entries = [cache entries];
//
//  SparkEntry *entry;
//  NSEnumerator *iter = [entries entryEnumerator];
//  while (entry = [iter nextObject]) {
//    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//    [entry serialize:dict];
//    [library addObject:dict];
//    [dict release];
//  }
//  
//  [library writeToFile:[@"~/Desktop/SparkLibrary.plist" stringByStandardizingPath] atomically:NO];
//  [library release];
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

#pragma mark -
void SEPopulatePluginMenu(NSMenu *menu) {
  NSCParameterAssert(menu);
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
