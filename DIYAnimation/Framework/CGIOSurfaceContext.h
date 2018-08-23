#ifndef CGIOSURFACE_H_
#define CGIOSURFACE_H_
#include <CoreGraphics/CoreGraphics.h>
CF_IMPLICIT_BRIDGING_ENABLED
CF_ASSUME_NONNULL_BEGIN

CG_EXTERN _Nullable CGContextRef CGIOSurfaceContextCreate(IOSurfaceRef surface,
                                                size_t width,
                                                size_t height,
                                                size_t bitsPerComponent,
                                                size_t bitsPerPixel,
                                                CGColorSpaceRef space,
                                                uint32_t /*CGBitmapInfo*/ bitmapInfo);
CG_EXTERN void CGIOSurfaceContextSetDisplayMask(CGContextRef ctx, CGOpenGLDisplayMask mask);
CG_EXTERN CGOpenGLDisplayMask CGIOSurfaceContextGetDisplayMask(CGContextRef ctx);
CG_EXTERN int CGIOSurfaceContextGetWidth(CGContextRef ctx);
CG_EXTERN int CGIOSurfaceContextGetHeight(CGContextRef ctx);
CG_EXTERN IOSurfaceRef CGIOSurfaceContextGetSurface(CGContextRef ctx);
CG_EXTERN int CGIOSurfaceContextGetBitsPerComponent(CGContextRef ctx);
CG_EXTERN int CGIOSurfaceContextGetBitsPerPixel(CGContextRef ctx);
CG_EXTERN CGColorSpaceRef CGIOSurfaceContextGetColorSpace(CGContextRef ctx);
CG_EXTERN CGBitmapInfo CGIOSurfaceContextGetBitmapInfo(CGContextRef ctx);
CG_EXTERN CGImageRef CGIOSurfaceContextCreateImage(CGContextRef ctx);
CG_EXTERN CGImageRef CGIOSurfaceContextCreateImageReference(CGContextRef ctx);
CG_EXTERN void CGIOSurfaceContextGetSizeLimits(CGContextRef ctx, int *width, int *height);

CF_ASSUME_NONNULL_END
CF_IMPLICIT_BRIDGING_DISABLED
#endif /* CGIOSURFACE_H_ */
