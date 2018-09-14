/*
 *  SparkleDelegate.m
 *  Spark
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2009 - 2010 Ninsight. All rights reserved.
 */

#import "SparkleDelegate.h"

@implementation Spark (SparkleDelegate)

- (void)setupSparkle {
//  SUUpdater *updater = [SUUpdater sharedUpdater];
//  [updater setDelegate:self];
//  [updater setAllowsAutomaticallyDownloadsUpdates:NO];
}

- (IBAction)checkForUpdates:(id)sender {
  [[SUUpdater sharedUpdater] checkForUpdates:sender];
}

- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater sendingSystemProfile:(BOOL)sendingProfile {
  NSString *lang = [NSLocale preferredLanguages].firstObject;
  NSDictionary *param = @{
                          @"key": @"locale",
                          @"value": lang,
                          @"displayKey": @"Locale",
                          @"displayValue": [[NSLocale currentLocale] displayNameForKey:NSLocaleLanguageCode value:lang]
                          };
  return @[param];
}

//- (void)updater:(SUUpdater *)updater willInstallUpdate:(SUAppcastItem *)update {
//
//}

- (void)updaterWillRelaunchApplication:(SUUpdater *)updater {
  // TODO: Stop Spark Daemon.
}

- (id<SUVersionComparison>)versionComparatorForUpdater:(SUUpdater *)updater {
  return self;
}

- (NSURL *)feedURL {
  return [[SUUpdater sharedUpdater] feedURL];
}
- (void)setFeedURL:(NSURL *)anURL {
  [[SUUpdater sharedUpdater] setFeedURL:anURL];
}

- (NSURL *)releaseFeedURL {
  return [[SUUpdater sharedUpdater] defaultFeedURL];
}
- (NSURL *)betaFeedURL {
  NSURL *url = [[SUUpdater sharedUpdater] defaultFeedURL];
  NSMutableString *str = [[url absoluteString] mutableCopyWithZone:nil];
  [str replaceOccurrencesOfString:@"release." withString:@"beta."
                          options:NSLiteralSearch range:NSMakeRange(0, [str length])];
  return [NSURL URLWithString:str];
}

@end
