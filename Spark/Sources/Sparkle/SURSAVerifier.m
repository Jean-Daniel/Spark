/*
 *  SUSignature.m
 *  Emerald
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright © 2009 - 2010 Ninsight. All rights reserved.
 */

#import "SparkleDelegate.h"

#import <Security/Security.h>

#import <WonderBox/WBFSFunctions.h>
#import <WonderBox/WBSecurityFunctions.h>

@implementation Spark (SUSignatureVerifier)

static
SecCertificateRef __SULoadCertificateAtURL(NSURL *anURL) {
  SecCertificateRef cert = NULL;
  NSData *certData = [NSData dataWithContentsOfURL:anURL];
  if (certData)
    cert = SecCertificateCreateWithData(kCFAllocatorDefault, SPXNSToCFData(certData));
  return cert;
}

- (NSURL *)updateCertificateURL {
  NSString *cert = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SUPublicRSAKeyFile"];
  if (!cert)
    return nil;
  NSString *path = [[NSBundle mainBundle] pathForResource:[cert stringByDeletingPathExtension] ofType:[cert pathExtension]];
  return path ? [NSURL fileURLWithPath:path] : nil;
}

typedef struct {
  CFTypeRef name;
  size_t length;
} SparkDigestAlgorithm;

SPX_INLINE
SparkDigestAlgorithm __WBAlgorithmForSUAlgorithm(NSString *str) {
  if (!str)
    return (SparkDigestAlgorithm){ NULL, 0 };

  const char *string = [[[str lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] UTF8String];
  if (!string || strlen(string) == 0)
    return (SparkDigestAlgorithm){ NULL, 0 };

  if (0 == strcmp("sha1withrsa", string))
    return (SparkDigestAlgorithm){ kSecDigestSHA1, 0 };
  if (0 == strcmp("sha256withrsa", string))
    return (SparkDigestAlgorithm){ kSecDigestSHA2, 256 };
  if (0 == strcmp("sha512withrsa", string))
    return (SparkDigestAlgorithm){ kSecDigestSHA2, 512 };
  if (0 == strcmp("sha224withrsa", string))
    return (SparkDigestAlgorithm){ kSecDigestSHA2, 224 };
  if (0 == strcmp("sha384withrsa", string))
    return (SparkDigestAlgorithm){ kSecDigestSHA2, 384 };

  return (SparkDigestAlgorithm){ NULL, 0 };
}

- (BOOL)verifyItem:(SUAppcastItem *)anItem atURL:(NSURL *)anURL {
  // Load certificat
  BOOL valid = NO;
  SecCertificateRef cert = __SULoadCertificateAtURL([self updateCertificateURL]);
  if (cert) {
    // extract public key
    SecKeyRef pubKey = NULL;
    if (noErr == SecCertificateCopyPublicKey(cert, &pubKey)) {
      // check all supported signature (and stop at the first that works)
      for (SUItemSignature *sign in [anItem signatures]) {
        NSData *data = sign.data;
        SparkDigestAlgorithm algo = __WBAlgorithmForSUAlgorithm([sign algorithm]);
        if (data && algo.name) {
          CFBooleanRef ok = WBSecurityVerifyFileSignature(SPXNSToCFURL(anURL), SPXNSToCFData(data), pubKey, algo.name, algo.length, NULL);
          if (!ok || !CFBooleanGetValue(ok))
            SPXLogWarning(@"Error while verifying archive signature");
          else
            // stop on first match
            valid = YES;
            break;
        }
      }
      CFRelease(pubKey);
    }
    CFRelease(cert);
  }
  return valid;
}

@end

