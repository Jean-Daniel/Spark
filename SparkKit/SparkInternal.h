//
//  SparkInternal.h
//  SparkKit
//
//  Created by Jean-Daniel on 07/12/2017.
//

#ifndef SparkInternal_h
#define SparkInternal_h

#import <WonderBox/WonderBox.h>

#import <SparkKit/SparkObject.h>

@interface SparkObject (SparkSerialization) <WBSerializable>

@end

@interface WBApplication (SparkSerialization) <WBSerializable>

@end

#endif /* SparkInternal_h */
