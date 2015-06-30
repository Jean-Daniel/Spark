/*
 *  SparkleDelegate.h
 *  Emerald
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2009 - 2010 Ninsight. All rights reserved.
 */

#import "Spark.h"

#import <Sparkle/Sparkle.h>

#import <Sparkle/SUSignatureVerifierProtocol.h>

@interface Spark (SUVersionComparison) <SUVersionComparison>

- (id<SUVersionComparison>)versionComparatorForUpdater:(SUUpdater *)updater;

@end

@interface Spark (SUSignatureVerifier) <SUSignatureVerifier>

@end

@interface Spark (SparkleDelegate)

- (void)setupSparkle;
- (IBAction)checkForUpdates:(id)sender;

@property(nonatomic, retain) NSURL *feedURL;

- (NSURL *)betaFeedURL;
- (NSURL *)releaseFeedURL;

@end

