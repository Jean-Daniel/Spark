//
//  SEUpdater.h
//  Spark Editor
//
//  Created by Jean-Daniel Dupas on 18/09/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <SUpdaterKit/SUpdater.h>
#import <ShadowKit/SKSingleton.h>

@interface SEUpdater : SUpdater {
  @private
  id se_delegate;
  bool se_pending;
}

- (void)searchWithDelegate:(id)delegate;

@end

SKSingletonInterface(SEUpdater, sharedUpdater);

@interface NSObject (SEUpdaterDelegate)

- (void)updater:(SEUpdater *)updater didSearchVersion:(BOOL)newVersion error:(NSError *)anError;

@end
