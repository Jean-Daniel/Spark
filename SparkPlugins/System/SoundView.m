/*
 *  SoundView.m
 *  Spark Plugins
 *
 *  Created by Black Moon Team.
 *  Copyright (c) 2004 - 2007, Shadow Lab. All rights reserved.
 */

#import "SoundView.h"

//
//  Graphics.m
//  BezelUI
//
//  Created by Jean-Daniel Dupas on 17/07/2015.
//  Copyright (c) 2015 Xenonium. All rights reserved.
//

#import <Foundation/Foundation.h>

/* Internal */
typedef struct {
  CGPathElementType type;
  const float points[6];
} BYPathElement;

static const BYPathElement audio[] = {
  { kCGPathElementMoveToPoint, { 72.0116f, 121.3806f } },
  { kCGPathElementAddCurveToPoint, { 71.9796f, 122.4556f, 71.1036f, 123.3196f, 70.0196f, 123.3196f } },
  { kCGPathElementAddCurveToPoint, { 69.5476f, 123.3196f, 69.1186f, 123.1486f, 68.7766f, 122.8746f } },
  { kCGPathElementAddCurveToPoint, { 68.7706f, 122.8756f, 68.7616f, 122.8796f, 68.7546f, 122.8816f } },
  { kCGPathElementAddCurveToPoint, { 68.7386f, 122.8426f, 58.9686f, 114.5456f, 53.5866f, 109.9766f } },
  { kCGPathElementAddCurveToPoint, { 53.4986f, 109.9816f, 53.4166f, 110.0026f, 53.3276f, 110.0026f } },
  { kCGPathElementAddLineToPoint, { 39.7236f, 110.0026f } },
  { kCGPathElementAddCurveToPoint, { 37.1346f, 110.0026f, 35.0136f, 107.8826f, 35.0136f, 105.2926f } },
  { kCGPathElementAddLineToPoint, { 35.0136f, 87.7046f } },
  { kCGPathElementAddCurveToPoint, { 35.0136f, 85.1146f, 37.1346f, 82.9946f, 39.7236f, 82.9946f } },
  { kCGPathElementAddLineToPoint, { 53.3276f, 82.9946f } },
  { kCGPathElementAddCurveToPoint, { 53.4356f, 82.9946f, 53.5366f, 83.0196f, 53.6426f, 83.0266f } },
  { kCGPathElementAddCurveToPoint, { 59.0616f, 78.3436f, 68.8426f, 69.8976f, 68.8786f, 69.9086f } },
  { kCGPathElementAddCurveToPoint, { 68.8776f, 69.9086f, 68.8896f, 69.9146f, 68.8986f, 69.9186f } },
  { kCGPathElementAddCurveToPoint, { 69.2186f, 69.7016f, 69.6046f, 69.5746f, 70.0196f, 69.5746f } },
  { kCGPathElementAddCurveToPoint, { 71.0626f, 69.5746f, 71.9096f, 70.3766f, 71.9996f, 71.3966f } },
  { kCGPathElementAddCurveToPoint, { 72.0076f, 71.4006f, 72.0206f, 71.4066f, 72.0206f, 71.4066f } },
  { kCGPathElementAddCurveToPoint, { 72.0206f, 71.3356f, 71.9646f, 121.4286f, 72.0206f, 121.3756f } },
  { kCGPathElementAddCurveToPoint, { 72.0206f, 121.3756f, 72.0126f, 121.3806f, 72.0116f, 121.3806f } },
  { kCGPathElementCloseSubpath, { 0 } },

  { kCGPathElementMoveToPoint, { 122.0745f, 132.4613f } },
  { kCGPathElementAddCurveToPoint, { 121.2315f, 133.4763f, 119.7395f, 133.6033f, 118.7345f, 132.7623f } },
  { kCGPathElementAddCurveToPoint, { 117.7285f, 131.9233f, 117.5945f, 130.4273f, 118.4325f, 129.4223f } },
  { kCGPathElementAddCurveToPoint, { 134.8585f, 109.7253f, 134.8585f, 83.2623f, 118.4325f, 63.5743f } },
  { kCGPathElementAddCurveToPoint, { 117.5945f, 62.5693f, 117.7285f, 61.0723f, 118.7345f, 60.2333f } },
  { kCGPathElementAddCurveToPoint, { 119.1785f, 59.8633f, 119.7165f, 59.6823f, 120.2545f, 59.6823f } },
  { kCGPathElementAddCurveToPoint, { 120.9295f, 59.6823f, 121.6065f, 59.9723f, 122.0745f, 60.5353f } },
  { kCGPathElementAddCurveToPoint, { 140.0205f, 82.0393f, 140.0205f, 110.9453f, 122.0745f, 132.4613f } },
  { kCGPathElementCloseSubpath, { 0 } },

  { kCGPathElementMoveToPoint, { 103.2788f, 123.1736f } },
  { kCGPathElementAddCurveToPoint, { 102.2778f, 122.3276f, 102.1578f, 120.8316f, 103.0008f, 119.8306f } },
  { kCGPathElementAddCurveToPoint, { 114.6408f, 106.0926f, 114.6408f, 86.9046f, 103.0008f, 73.1666f } },
  { kCGPathElementAddCurveToPoint, { 102.1578f, 72.1656f, 102.2778f, 70.6696f, 103.2788f, 69.8236f } },
  { kCGPathElementAddCurveToPoint, { 103.7238f, 69.4456f, 104.2698f, 69.2596f, 104.8118f, 69.2596f } },
  { kCGPathElementAddCurveToPoint, { 105.4838f, 69.2596f, 106.1518f, 69.5456f, 106.6248f, 70.0986f } },
  { kCGPathElementAddCurveToPoint, { 119.7878f, 85.6426f, 119.7878f, 107.3546f, 106.6248f, 122.8976f } },
  { kCGPathElementAddCurveToPoint, { 105.7718f, 123.8936f, 104.2798f, 124.0146f, 103.2788f, 123.1736f } },
  { kCGPathElementCloseSubpath, { 0 } },

  { kCGPathElementMoveToPoint, { 87.6137f, 113.5147f } },
  { kCGPathElementAddCurveToPoint, { 86.6307f, 112.6487f, 86.5337f, 111.1497f, 87.3997f, 110.1667f } },
  { kCGPathElementAddCurveToPoint, { 94.4757f, 102.1187f, 94.4757f, 90.8797f, 87.3997f, 82.8317f } },
  { kCGPathElementAddCurveToPoint, { 86.5337f, 81.8497f, 86.6307f, 80.3507f, 87.6137f, 79.4837f } },
  { kCGPathElementAddCurveToPoint, { 88.0627f, 79.0877f, 88.6227f, 78.8937f, 89.1787f, 78.8937f } },
  { kCGPathElementAddCurveToPoint, { 89.8367f, 78.8937f, 90.4907f, 79.1667f, 90.9587f, 79.6997f } },
  { kCGPathElementAddCurveToPoint, { 99.6597f, 89.5897f, 99.6597f, 103.4087f, 90.9587f, 113.2997f } },
  { kCGPathElementAddCurveToPoint, { 90.0917f, 114.2817f, 88.5957f, 114.3797f, 87.6137f, 113.5147f } },
  { kCGPathElementCloseSubpath, { 0 } },
};

static const BYPathElement audio_mute[] = {
  { kCGPathElementMoveToPoint, { 97.2145f, 93.5094f } },
  { kCGPathElementAddCurveToPoint, { 98.0645f, 100.3924f, 95.9785f, 107.4984f, 90.9105f, 113.2674f } },
  { kCGPathElementAddCurveToPoint, { 90.0455f, 114.2494f, 88.5525f, 114.3474f, 87.5725f, 113.4834f } },
  { kCGPathElementAddCurveToPoint, { 86.5925f, 112.6174f, 86.4945f, 111.1204f, 87.3595f, 110.1384f } },
  { kCGPathElementAddCurveToPoint, { 90.9285f, 106.0724f, 92.6865f, 101.1924f, 92.6465f, 96.3204f } },
  { kCGPathElementCloseSubpath, { 0 } },

  { kCGPathElementMoveToPoint, { 114.0714f, 83.1372f } },
  { kCGPathElementAddCurveToPoint, { 118.7904f, 96.4142f, 116.2844f, 111.3332f, 106.5384f, 122.8592f } },
  { kCGPathElementAddCurveToPoint, { 105.6874f, 123.8542f, 104.1994f, 123.9752f, 103.2014f, 123.1342f } },
  { kCGPathElementAddCurveToPoint, { 102.2014f, 122.2882f, 102.0824f, 120.7942f, 102.9234f, 119.7942f } },
  { kCGPathElementAddCurveToPoint, { 111.2974f, 109.8952f, 113.6304f, 97.1652f, 109.9274f, 85.6872f } },
  { kCGPathElementCloseSubpath, { 0 } },

  { kCGPathElementMoveToPoint, { 130.1107f, 73.2683f } },
  { kCGPathElementAddCurveToPoint, { 139.2297f, 92.5683f, 136.5107f, 114.9323f, 121.9517f, 132.4143f } },
  { kCGPathElementAddCurveToPoint, { 121.1117f, 133.4293f, 119.6227f, 133.5563f, 118.6197f, 132.7163f } },
  { kCGPathElementAddCurveToPoint, { 117.6167f, 131.8773f, 117.4827f, 130.3823f, 118.3187f, 129.3773f } },
  { kCGPathElementAddCurveToPoint, { 131.5077f, 113.5383f, 134.0727f, 93.3213f, 126.0327f, 75.7773f } },
  { kCGPathElementCloseSubpath, { 0 } },

  { kCGPathElementMoveToPoint, { 72.0135f, 121.2846f } },
  { kCGPathElementAddCurveToPoint, { 72.0145f, 121.3176f, 72.0155f, 121.3396f, 72.0165f, 121.3386f } },
  { kCGPathElementAddCurveToPoint, { 72.0165f, 121.3386f, 72.0085f, 121.3426f, 72.0075f, 121.3426f } },
  { kCGPathElementAddCurveToPoint, { 71.9755f, 122.4166f, 71.1015f, 123.2796f, 70.0205f, 123.2796f } },
  { kCGPathElementAddCurveToPoint, { 69.5495f, 123.2796f, 69.1215f, 123.1096f, 68.7795f, 122.8356f } },
  { kCGPathElementAddCurveToPoint, { 68.7735f, 122.8366f, 68.7645f, 122.8406f, 68.7585f, 122.8416f } },
  { kCGPathElementAddCurveToPoint, { 68.7485f, 122.8176f, 64.9005f, 119.5386f, 60.7085f, 115.9726f } },
  { kCGPathElementAddLineToPoint, { 71.9915f, 109.0296f } },
  { kCGPathElementAddCurveToPoint, { 71.9915f, 115.7046f, 71.9975f, 120.7376f, 72.0135f, 121.2836f } },
  { kCGPathElementCloseSubpath, { 0 } },

  { kCGPathElementMoveToPoint, { 118.3190f, 63.5834f } },
  { kCGPathElementAddCurveToPoint, { 117.4830f, 62.5794f, 117.6170f, 61.0834f, 118.6200f, 60.2454f } },
  { kCGPathElementAddCurveToPoint, { 119.0630f, 59.8754f, 119.6000f, 59.6954f, 120.1360f, 59.6954f } },
  { kCGPathElementAddCurveToPoint, { 120.8100f, 59.6954f, 121.4850f, 59.9844f, 121.9520f, 60.5464f } },
  { kCGPathElementAddCurveToPoint, { 123.2590f, 62.1144f, 124.4580f, 63.7264f, 125.5740f, 65.3674f } },
  { kCGPathElementAddLineToPoint, { 121.5400f, 67.8554f } },
  { kCGPathElementAddCurveToPoint, { 120.5450f, 66.4024f, 119.4780f, 64.9744f, 118.3190f, 63.5834f } },
  { kCGPathElementCloseSubpath, { 0 } },

  { kCGPathElementMoveToPoint, { 39.7125f, 109.9744f } },
  { kCGPathElementAddCurveToPoint, { 37.1295f, 109.9744f, 35.0135f, 107.8554f, 35.0135f, 105.2684f } },
  { kCGPathElementAddLineToPoint, { 35.0135f, 87.6934f } },
  { kCGPathElementAddCurveToPoint, { 35.0135f, 85.1064f, 37.1295f, 82.9874f, 39.7125f, 82.9874f } },
  { kCGPathElementAddLineToPoint, { 53.3675f, 82.9874f } },
  { kCGPathElementAddCurveToPoint, { 53.4755f, 82.9874f, 53.5765f, 83.0124f, 53.6825f, 83.0194f } },
  { kCGPathElementAddCurveToPoint, { 59.0885f, 78.3404f, 68.8455f, 69.9014f, 68.8815f, 69.9124f } },
  { kCGPathElementAddCurveToPoint, { 68.8805f, 69.9124f, 68.8935f, 69.9184f, 68.9025f, 69.9224f } },
  { kCGPathElementAddCurveToPoint, { 69.2205f, 69.7054f, 69.6055f, 69.5784f, 70.0205f, 69.5784f } },
  { kCGPathElementAddCurveToPoint, { 71.0615f, 69.5784f, 71.9055f, 70.3804f, 71.9955f, 71.3994f } },
  { kCGPathElementAddCurveToPoint, { 72.0035f, 71.4024f, 72.0165f, 71.4094f, 72.0165f, 71.4094f } },
  { kCGPathElementAddCurveToPoint, { 72.0165f, 71.3724f, 72.0005f, 85.2714f, 71.9945f, 98.4114f } },
  { kCGPathElementAddLineToPoint, { 53.2455f, 109.9744f } },
  { kCGPathElementCloseSubpath, { 0 } },

  { kCGPathElementMoveToPoint, { 102.9238f, 73.1674f } },
  { kCGPathElementAddCurveToPoint, { 102.0818f, 72.1674f, 102.2018f, 70.6724f, 103.2018f, 69.8274f } },
  { kCGPathElementAddCurveToPoint, { 103.6448f, 69.4494f, 104.1898f, 69.2644f, 104.7308f, 69.2644f } },
  { kCGPathElementAddCurveToPoint, { 105.4018f, 69.2644f, 106.0668f, 69.5494f, 106.5388f, 70.1024f } },
  { kCGPathElementAddCurveToPoint, { 107.8488f, 71.6524f, 109.0228f, 73.2664f, 110.0728f, 74.9274f } },
  { kCGPathElementAddLineToPoint, { 106.0388f, 77.4154f } },
  { kCGPathElementAddCurveToPoint, { 105.1138f, 75.9534f, 104.0788f, 74.5324f, 102.9238f, 73.1674f } },
  { kCGPathElementCloseSubpath, { 0 } },

  { kCGPathElementMoveToPoint, { 87.3600f, 82.8246f } },
  { kCGPathElementAddCurveToPoint, { 86.4950f, 81.8436f, 86.5920f, 80.3466f, 87.5720f, 79.4806f } },
  { kCGPathElementAddCurveToPoint, { 88.0210f, 79.0846f, 88.5800f, 78.8906f, 89.1340f, 78.8906f } },
  { kCGPathElementAddCurveToPoint, { 89.7910f, 78.8906f, 90.4430f, 79.1636f, 90.9100f, 79.6956f } },
  { kCGPathElementAddCurveToPoint, { 92.2770f, 81.2506f, 93.4030f, 82.9116f, 94.3390f, 84.6316f } },
  { kCGPathElementAddLineToPoint, { 90.3010f, 87.1216f } },
  { kCGPathElementAddCurveToPoint, { 89.5140f, 85.6216f, 88.5450f, 84.1756f, 87.3600f, 82.8246f } },
  { kCGPathElementCloseSubpath, { 0 } },

  { kCGPathElementMoveToPoint, { 31.5363f, 131.5779f } },
  { kCGPathElementAddCurveToPoint, { 30.3623f, 132.3009f, 28.8263f, 131.9319f, 28.1053f, 130.7569f } },
  { kCGPathElementAddCurveToPoint, { 27.3843f, 129.5819f, 27.7503f, 128.0429f, 28.9253f, 127.3209f } },
  { kCGPathElementAddLineToPoint, { 138.9413f, 59.6249f } },
  { kCGPathElementAddCurveToPoint, { 139.3343f, 59.3839f, 139.7663f, 59.2649f, 140.1943f, 59.2559f } },
  { kCGPathElementAddCurveToPoint, { 141.0503f, 59.2389f, 141.8923f, 59.6629f, 142.3723f, 60.4459f } },
  { kCGPathElementAddCurveToPoint, { 143.0933f, 61.6219f, 142.7263f, 63.1599f, 141.5533f, 63.8819f } },
  { kCGPathElementCloseSubpath, { 0 } },
};

static
void BYCGContextAddBYPath(CGContextRef ctxt, const BYPathElement *elements, size_t count) {
  for (size_t idx = 0; idx < count; ++idx) {
    const BYPathElement *step = &elements[idx];
    switch (step->type) {
      case kCGPathElementCloseSubpath:
        CGContextClosePath(ctxt);
        break;
      case kCGPathElementMoveToPoint:
        CGContextMoveToPoint(ctxt, step->points[0], step->points[1]);
        break;
      case kCGPathElementAddLineToPoint:
        CGContextAddLineToPoint(ctxt, step->points[0], step->points[1]);
        break;
      case kCGPathElementAddQuadCurveToPoint:
        CGContextAddQuadCurveToPoint(ctxt, step->points[0], step->points[1],
                                     step->points[2], step->points[3]);
        break;
      case kCGPathElementAddCurveToPoint:
        CGContextAddCurveToPoint(ctxt, step->points[0], step->points[1],
                                 step->points[2], step->points[3],
                                 step->points[4], step->points[5]);
        break;
    }
  }
}

void _SAAudioAddVolumeImage(CGContextRef ctxt, bool muted) {
  if (muted)
    BYCGContextAddBYPath(ctxt, audio_mute, sizeof(audio_mute) / sizeof(*audio_mute));
  else
    BYCGContextAddBYPath(ctxt, audio, sizeof(audio) / sizeof(*audio));
}
