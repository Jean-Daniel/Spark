/*
 *  SparkKitBase.h
 *  SparkKit
 *
 *  Created by Grayfox on 19/11/2004.
 *  Copyright 2004 Shadow Lab. All rights reserved.
 *
 */

#if defined(__cplusplus)
#define SPARK_EXPORT extern "C"
#endif

#if !defined(SPARK_EXPORT)
#define SPARK_EXPORT extern
#endif

#if !defined(SPARK_STATIC_INLINE)
#define SPARK_STATIC_INLINE static __inline__
#endif

#if !defined(SPARK_EXTERN_INLINE)
#define SPARK_EXTERN_INLINE extern __inline__
#endif