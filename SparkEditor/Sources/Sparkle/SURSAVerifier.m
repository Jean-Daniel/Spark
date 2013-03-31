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
#import <WonderBox/WBCDSAFunctions.h>
#import <WonderBox/WBSecurityFunctions.h>

@implementation Spark (SUSignatureVerifier)

static
SecCertificateRef __SULoadCertificateAtURL(CFURLRef anURL) {
  CFDataRef certData;
  OSStatus err = noErr;
  SecCertificateRef cert = NULL;
  if (anURL && CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault, anURL, &certData, NULL, NULL, &err)) {
    const CSSM_DATA cdata = { (CSSM_SIZE)CFDataGetLength(certData), (UInt8 *)CFDataGetBytePtr(certData) };
    err = SecCertificateCreateFromData(&cdata, CSSM_CERT_X_509v3, CSSM_CERT_ENCODING_BER, &cert);
    if (noErr != err)  // try DER if BER fail
      err = SecCertificateCreateFromData(&cdata, CSSM_CERT_X_509v3, CSSM_CERT_ENCODING_DER, &cert);

    CFRelease(certData);
  }
  return cert;
}

- (NSURL *)updateCertificateURL {
  NSString *cert = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SUPublicRSAKeyFile"];
  if (!cert)
    return nil;
  NSString *path = [[NSBundle mainBundle] pathForResource:[cert stringByDeletingPathExtension] ofType:[cert pathExtension]];
  return path ? [NSURL fileURLWithPath:path] : nil;
}

SPX_INLINE
CSSM_ALGORITHMS __WBAlgorithmForSUAlgorithm(SUSignatureAlgorithm algo) {
  switch (algo) {
    default: return CSSM_ALGID_NONE;
     /* RSA only */
    case kSUSignatureSHA1WithRSA:
      return CSSM_ALGID_SHA1WithRSA;
    case kSUSignatureSHA224WithRSA:
      return CSSM_ALGID_SHA224WithRSA;
    case kSUSignatureSHA256WithRSA:
      return CSSM_ALGID_SHA256WithRSA;
    case kSUSignatureSHA384WithRSA:
      return CSSM_ALGID_SHA384WithRSA;
    case kSUSignatureSHA512WithRSA:
      return CSSM_ALGID_SHA512WithRSA;
  }
}

- (BOOL)verifyFileAtPath:(NSString *)aPath forItem:(SUAppcastItem *)anItem {
  // Load certificat
  const char *archPath = NULL;
  @try {
    archPath = [aPath safeFileSystemRepresentation];
  } @catch (id) {}
  if (!archPath) {
    SPXLogError(@"Invalid archive path: %@", aPath);
    return NO;
  }

  bool valid = false;
  SecCertificateRef cert = __SULoadCertificateAtURL((CFURLRef)[self updateCertificateURL]);
  if (cert) {
    // extract public key
    SecKeyRef pubKey = NULL;
    if (noErr == SecCertificateCopyPublicKey(cert, &pubKey)) {
      // check all supported signature (and stop at the first that works)
      for (SUItemSignature *sign in [anItem signatures]) {
        NSData *data = [sign data];
        CSSM_ALGORITHMS algo = __WBAlgorithmForSUAlgorithm([sign algorithm]);
        if (data && CSSM_ALGID_NONE != algo) {
          const CSSM_DATA signature = { [data length], (UInt8 *)[data bytes] };
          CSSM_RETURN err = WBSecurityVerifyFileSignature(archPath, &signature, pubKey, algo, &valid);
          if (noErr != err)
            SPXLogWarning(@"Error while verifying archive signature: %s", WBCDSAGetErrorString(err));
          // stop on first match
          if (valid) break;
        }
      }
      CFRelease(pubKey);
    }
    CFRelease(cert);
  }
  return valid;
}

@end

