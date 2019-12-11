#ifndef Bridge_h
#define Bridge_h

// Communication between Swift and Metal via the shader bridge:
#import "./Render SPI/Shaders/LayerShaderBridge.h"

// Private IOSurface API:
#import "./CGIOSurfaceContext.h"

// Private XPC API:
#import "./xpc_private.h"

// Swift masks all bootstrap symbols, even those in Foundation.
static inline kern_return_t __bootstrap_register(const char *name, mach_port_t port) {
    
    // Essentially re-exporting private launchd/Bootstrap API:
    extern kern_return_t bootstrap_register(
        mach_port_t bootstrap_port,
        const char *service_name,
        mach_port_t service_port
    );
    return bootstrap_register(bootstrap_port, name, port);
}

// TODO:
#import <QuartzCore/QuartzCore.h>
extern void CATransform3DInterpolate(CATransform3D *, CATransform3D *, CATransform3D *, double);



typedef int CGSValue;
typedef void *CGSRegionRef;
typedef int CGSConnectionID;
typedef int CGSWindowID;
typedef int CGSSurfaceID;
typedef int CGSSpaceID;

extern CGSValue CGSCreateCStringNoCopy(const char str);
extern char CGSCStringValue(CGSValue string);
extern int CGSIntegerValue(CGSValue intVal);

typedef enum _CGSWindowOrderingMode {
   kCGSOrderAbove                =  1, // Window is ordered above target.
   kCGSOrderBelow                = -1, // Window is ordered below target.
   kCGSOrderOut                  =  0  // Window is removed from the on-screen window list.
} CGSWindowOrderingMode;

CG_EXTERN CGError CGSNewWindow(CGSConnectionID cid, int /* use 0x3 */, float, float, CGSRegionRef, CGSWindowID *);
CG_EXTERN CGError CGSNewWindowWithOpaqueShape(CGSConnectionID cid, int backingType /* use 0x3 */, CGSRegionRef region, CGSRegionRef opaqueShape, int flags, const int tags[2], size_t maxTagSize /* use 0x40 */, CGSWindowID *outWID);
CG_EXTERN CGError CGSNewEmptyRegion(CGSRegionRef *outRegion);
CG_EXTERN CGError CGSNewRegionWithRect(const CGRect *rect, CGSRegionRef *newRegion);
CG_EXTERN CGError CGSOrderWindow(CGSConnectionID cid, CGSWindowID win, CGSWindowOrderingMode place, CGSWindowID relativeToWindow /* nullable */);
CG_EXTERN CGError CGSSetWindowProperty(CGSConnectionID cid, CGSWindowID wid, CGSValue key, CGSValue value);
CG_EXTERN CGError CGSSetWindowTags(CGSConnectionID cid, CGSWindowID wid, const int tags[2], size_t maxTagSize /* use 0x40 */);
CG_EXTERN CGError CGSSetWindowOpacity(CGSConnectionID cid, CGSWindowID wid, bool isOpaque);
CG_EXTERN CGSConnectionID CGSMainConnectionID();
CG_EXTERN CGError CGSAddSurface(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID *sid);
CG_EXTERN CGError CGSSetSurfaceBounds(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid, CGRect rect);
CG_EXTERN CGError CGSOrderSurface(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid, int a, int b);
CG_EXTERN CGError CGSSetSurfaceOpacity(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid, bool isOpaque);
CG_EXTERN CGError CGSSetSurfaceResolution(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid, double scale);
CG_EXTERN CGError CGSMoveWindow(CGSConnectionID cid, CGSWindowID wid, CGPoint *point);
CG_EXTERN CGLError CGLSetSurface(CGLContextObj gl, CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid);
CG_EXTERN CGSSpaceID CGSSpaceCreate(CGSConnectionID cid, int flags, CFDictionaryRef options);
CG_EXTERN void CGSSpaceDestroy(CGSConnectionID cid, CGSSpaceID sid);
CG_EXTERN CGError CGSSpaceSetName(CGSConnectionID cid, CGSSpaceID sid, CFStringRef name);
CG_EXTERN CGError CGSSpaceSetAbsoluteLevel(CGSConnectionID cid, CGSSpaceID sid, int level);
CG_EXTERN void CGSShowSpaces(CGSConnectionID cid, CFArrayRef spaces);
CG_EXTERN void CGSHideSpaces(CGSConnectionID cid, CFArrayRef spaces);
CG_EXTERN void CGSAddWindowsToSpaces(CGSConnectionID cid, CFArrayRef windows, CFArrayRef spaces);
CG_EXTERN void CGSRemoveWindowsFromSpaces(CGSConnectionID cid, CFArrayRef windows, CFArrayRef spaces);

/*
 CoreDisplay::DisplaySurface::Get*
  1. IOSurface
  2. CGXDisplayDeviceSurface (== same obj)
  3. IOAccelSurface
  4. FBO
  5. GLTexture
  6. MTLTexture
  7. Accelerator
  8. MTLDeviceSPI
  9. CGLSContext
 10. CGXDisplayDevice
*/

#endif /* Bridge_h */
