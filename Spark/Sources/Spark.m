/*
 *  Spark.m
 *  Spark Editor
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007 Shadow Lab. All rights reserved.
 */

#import "Spark.h"

#import "SEPlugInInstaller.h"

#if defined (DEBUG)
#import "SEEntryEditor.h"
#import <Foundation/NSDebug.h>
#import <SparkKit/SparkLibrarySynchronizer.h>
// #import <SparkKit/SparkEntryManagerPrivate.h>
#endif

#import <SparkKit/SparkKit.h>
#import <SparkKit/SparkPlugIn.h>
#import <SparkKit/SparkLibrary.h>
#import <SparkKit/SparkActionLoader.h>

#import <HotKeyToolKit/HotKeyToolKit.h>

#import "SparkleDelegate.h"

#import "SEPlugInHelp.h"
#import "SEPreferences.h"
#import "SELibraryWindow.h"
#import "SELibraryDocument.h"
#import "SEServerConnection.h"

int main(int argc, const char *argv[]) {
#if defined(DEBUG)
  NSDebugEnabled = YES;
  NSZombieEnabled = YES;
  
  HKTraceHotKeyEvents = YES;
  SparkLogSynchronization = YES;
  // SparkLibraryFileFormat = NSPropertyListXMLFormat_v1_0;
#endif
  return NSApplicationMain(argc, argv);
}

NSArray *gSortByNameDescriptors = nil;
NSString * const SparkEntriesPboardType = @"SparkEntriesPboardType";
NSString * const SESparkEditorDidChangePlugInStatusNotification = @"SESparkEditorDidChangePlugInStatus";

@implementation SparkEditor {
  /* Scripting Addition */
  NSMenu *se_plugins;
}

/* Create shared sort descriptor */
+ (void)initialize {
  if ([SparkEditor class] == self) {
    NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    gSortByNameDescriptors = [[NSArray alloc] initWithObjects:desc, nil];
  }
}

/* Initialize daemon status */
- (id)init {
  if (self = [super init]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePlugIns:)
                                                 name:SESparkEditorDidChangePlugInStatusNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangePlugIns:)
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
    SparkPlugIn *plugin = plugins[idx];
    NSString *sdef = [plugin sdefFile];
    if (sdef) {
      NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:sdef]
                                                                options:NSXMLNodePreserveAll | NSXMLDocumentXInclude error:&error];
      if (!doc) {
        SPXDebug(@"Error while loading sdef from %@: %@", sdef, error);
      } else {
        NSXMLElement *root = [definition rootElement];
        NSArray *suites = [[doc rootElement] nodesForXPath:@"/dictionary/suite" error:&error];
        if (!suites) {
          SPXDebug(@"Error while loading suites from %@: %@", sdef, error);
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
    HKEventTarget target = { .pid = getpid() };
    HKEventPostKeystrokeToTarget([sender keycode], [sender nativeModifier], target, kHKEventTargetProcess, NULL, kHKEventDefaultLatency);
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (NSMenu *)plugInsMenu {
  if (!se_plugins) {
    se_plugins = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"NEW_TRIGGER_MENU", @"New Trigger Menu Title")];
    SEPopulatePlugInMenu(se_plugins);
  }
  return se_plugins;
}

- (void)didChangePlugIns:(NSNotification *)aNotification {
  if (se_plugins) {
    NSUInteger count = [se_plugins numberOfItems];
    while (count-- > 0) {
      [se_plugins removeItemAtIndex:count];
    }
    SEPopulatePlugInMenu(se_plugins);
  }
}

@end

// MARK: -
@implementation Spark {
@private
  IBOutlet NSMenu *aboutMenu;
  IBOutlet NSMenuItem *statusMenuItem;
  SEPreferences *se_preferences;
}

+ (Spark *)sharedSpark {
  return (Spark *)[NSApp delegate];
}

// MARK: Init And Destroy
- (id)init {
  if (self = [super init]) {
#if defined (DEBUG)
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     @{
      //@"YES", @"NSShowNonLocalizedStrings",
      //@"YES", @"NSShowAllViews",
      //WBFloat(0.15f), @"NSWindowResizeTime",
      //@"6", @"NSDragManagerLogLevel",
      //@"YES", @"NSShowNonLocalizableStrings",
      //@"1", @"NSScriptingDebugLogLevel",
       }];
#endif
    
    /* Check active library sanity */
//    @try {
    SparkActiveLibrary();
//    } @catch (NSException *exception) {
//      SPXLogException(exception);
//    }
    
    /* Register defaults */
    [SEPreferences setup];
    
    /* Setup updater */
    [self setupSparkle];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

bool SparkDebugEnabled = false;

- (void)awakeFromNib {
#ifndef DEBUG
//  if ([[EDPreferences sharedPreferences] showDebugMenu])
//    SparkDebugEnabled = true;
//  else
    SparkDebugEnabled = (kCGEventFlagMaskShift == (CGEventSourceFlagsState(kCGEventSourceStateCombinedSessionState) & NSDeviceIndependentModifierFlagsMask));
#else
  SparkDebugEnabled = true;
#endif

  if (SparkDebugEnabled)
    [self createDebugMenu];

  [self createAboutMenu];
  
  NSMenu *file = [[[NSApp mainMenu] itemWithTag:1] submenu];
  [file setSubmenu:[NSApp plugInsMenu] forItem:[file itemWithTag:1]];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePlugIns:)
                                               name:SESparkEditorDidChangePlugInStatusNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangePlugIns:)
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

// MARK: -
// MARK: Menu IBActions
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

// MARK: -
// MARK: Import/Export Support


// MARK: -
// MARK: PlugIn Help Support
- (IBAction)showPlugInHelp:(id)sender {
  [[SEPlugInHelp sharedPlugInHelp] showWindow:sender];
}

- (void)showPlugInHelpPage:(NSString *)page {
  [[SEPlugInHelp sharedPlugInHelp] setPage:page];
  [[SEPlugInHelp sharedPlugInHelp] showWindow:self];
}

// MARK: -
// MARK: Open File & Sheet Did End
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

//- (BOOL)openPlugIn:(NSString *)filename {
//  /* Verifier que le plugin n'est pas déjà installé.
//  • Si installé => Si version supérieur, proposer de remplacer, redémarrer server, demander de redémarrer éditeur.
//  • Si non installé => Proposer d'installer dans ≠ domaines (Utilisateur et ordinateur).
//  */
//  id installer = nil;
//  CFBundleRef dest = nil;
//  CFBundleRef src = CFBundleCreate(kCFAllocatorDefault, (CFURLRef)[NSURL fileURLWithPath:filename]);
//  if (!src) {
//    SPXDebug(@"Unable to open bundle: %@", filename);
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

// MARK: -
// MARK: Application Delegate
- (void)openPlugInBundle:(NSString *)path {
  SEPlugInInstaller *panel = [[SEPlugInInstaller alloc] init];
  [panel setReleasedWhenClosed:YES];
  [panel setPlugIn:path];
  [NSApp runModalForWindow:[panel window]];
}

- (void)openLibraryBackup:(NSURL *)url {
  SELibraryDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];
  if (!doc) {
    NSBeep();
  } else {
    [doc revertToBackup:url];
  }
}

- (BOOL)se_openDefaultLibrary {
  SELibraryDocument *doc = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"org.shadowlab.spark.library" error:NULL];
  if (!doc)
    doc = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"SparkLibraryFile" error:NULL];
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
      [self openPlugInBundle:filename];
    } else if ([[filename pathExtension] isEqualToString:kSparkLibraryFileExtension]) {
      SPXDebug(@"Try to open a Spark Library => considere it as a restore action");
      [self openLibraryBackup:[NSURL fileURLWithPath:filename]];
    }
  } else {
    result = NO;
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

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  return YES;
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

// MARK: -
// MARK: About PlugIns Menu
- (void)createAboutMenu {
  NSUInteger count = [aboutMenu numberOfItems];
  while (count-- > 0) {
    [aboutMenu removeItemAtIndex:count];
  }
  
  NSArray *items = [[[SparkActionLoader sharedLoader] plugIns] sortedArrayUsingDescriptors:gSortByNameDescriptors];
  
  SparkPlugIn *plugin;
  NSEnumerator *plugins = [items objectEnumerator];
  while (plugin = [plugins nextObject]) {
    if ([plugin isEnabled]) {
      NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"ABOUT_PLUGIN_MENU_ITEM",
                                                                                                            @"About Plugin (%@ => Plugin name)"), [plugin name]]
                                                        action:@selector(aboutPlugIn:) keyEquivalent:@""];
      NSImage *img = [[plugin icon] copy];
      [img setSize:NSMakeSize(16, 16)];
      [menuItem setImage:img];

      [menuItem setRepresentedObject:plugin];
      [aboutMenu addItem:menuItem];
    }
  }
}

- (void)didChangePlugIns:(NSNotification *)sender {
  [self createAboutMenu];
}

- (IBAction)aboutPlugIn:(id)sender {
  SparkPlugIn *plugin = [sender representedObject];
  NSMutableDictionary *opts = [NSMutableDictionary dictionary];
  
  [opts setObject:[NSString stringWithFormat:NSLocalizedString(@"ABOUT_PLUGIN_BOX_TITLE", 
                                                               @"About Plugin (%@ => Plugin name)"), [plugin name]] 
           forKey:@"ApplicationName"];
  if (plugin.URL) {
    NSImage *icon = nil;
    if ([plugin.URL getResourceValue:&icon forKey:NSURLEffectiveIconKey error:NULL]) {
      [icon setSize:NSMakeSize(64, 64)];
      [opts setObject:icon forKey:@"ApplicationIcon"];
    }
    NSBundle *bundle = [NSBundle bundleWithURL:plugin.URL];
  
    NSString *credits = nil;
    if ((credits = [bundle pathForResource:@"Credits" ofType:@"html"]) ||
        (credits = [bundle pathForResource:@"Credits" ofType:@"rtf"]) ||
        (credits = [bundle pathForResource:@"Credits" ofType:@"rtfd"])) {
      NSAttributedString *str = [[NSAttributedString alloc] initWithURL:[NSURL fileURLWithPath:credits] documentAttributes:nil];
      [opts setObject:str forKey:@"Credits"];
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

// MARK: -
// MARK: Debug Menu

- (void)createDebugMenu {
  NSMenuItem *debugMenu = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Debug"];
//  [menu addItemWithTitle:@"Importer" action:@selector(openImporter:) keyEquivalent:@""];
//  [menu addItemWithTitle:@"Trigger Browser" action:@selector(openTriggerBrowser:) keyEquivalent:@""];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItemWithTitle:@"Dump Library" action:@selector(dumpLibrary:) keyEquivalent:@""];
  [menu addItemWithTitle:@"External Representation" action:@selector(dumpExternal:) keyEquivalent:@""];
  [menu addItem:[NSMenuItem separatorItem]];
  // [menu addItemWithTitle:@"Restart" action:@selector(restart:) keyEquivalent:@""];
  [debugMenu setSubmenu:menu];
  [[NSApp mainMenu] insertItem:debugMenu atIndex:[[NSApp mainMenu] numberOfItems] -1];
  
  // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRestart:) name:SURestarterApplicationDidRestartNotification object:nil];
}

//- (IBAction)restart:(id)sender {
//  SURestarter *restarter = [[SURestarter alloc] initWithTargetPath:[[NSBundle mainBundle] bundlePath] error:nil];
//  [restarter setData:[@"Hello wonderfull world!" dataUsingEncoding:NSUTF8StringEncoding]];
//
//  [NSApp terminate:sender];
//}

- (IBAction)dumpExternal:(id)sender {
//  NSMutableArray *library = [[NSMutableArray alloc] init];
//  SELibraryDocument *doc = SEGetDocumentForLibrary(SparkActiveLibrary());
//  SEEntryCache *cache = [doc cache];
//  SESparkEntrySet *entries = [cache entries];
//  
//  SPXDebug(@"%@", [[doc application] externalRepresentation]);
//  
//  SparkEntry *entry;
//  NSEnumerator *iter = [entries entryEnumerator];
//  while (entry = [iter nextObject]) {
//    [library addObject:[entry externalRepresentation]];
//  }
//  
//  SPXDebug(@"%@", library);
//  [library release];
}

SPARK_EXPORT
void SparkDumpEntries(SparkLibrary *aLibrary);

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

@end

// MARK: -
void SEPopulatePlugInMenu(NSMenu *menu) {
  NSCParameterAssert(menu);
  NSArray *plugins = [[[SparkActionLoader sharedLoader] plugIns] sortedArrayUsingDescriptors:gSortByNameDescriptors];

  NSInteger idx = 1;
  for (SparkPlugIn *plugin in plugins) {
    if ([plugin isEnabled]) {
      NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[plugin name] action:@selector(newTriggerFromMenu:) keyEquivalent:@""];
      NSImage *icon = [[plugin icon] copy];
      if (icon) {
        [icon setSize:NSMakeSize(16, 16)];
        [item setImage:icon];
      }
      [item setRepresentedObject:plugin];
      if (idx < 10) 
        [item setKeyEquivalent:[NSString stringWithFormat:@"%ld", idx++]];
      [menu addItem:item];
    }
  }  
}
