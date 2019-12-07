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

// Specifically for IOSurface/Ref conversion in Swift 5:
@class IOSurface;
CF_IMPLICIT_BRIDGING_ENABLED
#pragma clang assume_nonnull begin
static inline IOSurfaceRef _Nullable __ioNS2CF(IOSurface *_Nullable surface) {
	return (__bridge IOSurfaceRef)surface;
}
static inline IOSurface *_Nullable __ioCF2NS(IOSurfaceRef _Nullable surface) {
	return (__bridge IOSurface *)surface;
}
#pragma clang assume_nonnull end
CF_IMPLICIT_BRIDGING_DISABLED

// TODO:
#import <QuartzCore/QuartzCore.h>
extern void CATransform3DInterpolate(CATransform3D *, CATransform3D *, CATransform3D *, double);





typedef int CGSConnectionID;
typedef int CGSWindowID;
typedef int CGSSurfaceID;

typedef uint32_t _CGWindowID;

typedef int CGSConnection;
typedef int CGSWindow;
typedef int CGSValue;

extern CGSValue CGSCreateCStringNoCopy(const char str);
extern char CGSCStringValue(CGSValue string);
extern int CGSIntegerValue(CGSValue intVal);

typedef enum _CGSWindowOrderingMode {
   kCGSOrderAbove                =  1, // Window is ordered above target.
   kCGSOrderBelow                = -1, // Window is ordered below target.
   kCGSOrderOut                  =  0  // Window is removed from the on-screen window list.
} CGSWindowOrderingMode;

typedef void *CGSRegion;
typedef CGSRegion *CGSRegionRef;
typedef CGSWindow *CGSWindowRef;

extern CGError CGSNewWindow( CGSConnection cid, int, float, float, const CGSRegion, CGSWindowRef);
extern CGError CGSNewRegionWithRect( const CGRect * rect, CGSRegionRef newRegion );
extern CGError CGSOrderWindow(CGSConnection cid, CGSWindowID win, CGSWindowOrderingMode place, CGSWindow relativeToWindow /* nullable */);
extern CGError CGSSetWindowProperty(const CGSConnection cid, CGSWindowID wid, CGSValue key, CGSValue value);
extern CGSConnectionID CGSMainConnectionID(void);
extern CGError CGSAddSurface(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID *sid);
extern CGError CGSSetSurfaceBounds(CGSConnectionID cid, CGSWindow wid, CGSSurfaceID sid, CGRect rect);
extern CGError CGSOrderSurface(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid, int a, int b);
extern CGError CGSMoveWindow(const CGSConnection cid, const CGSWindowID wid, CGPoint *point);
extern CGLError CGLSetSurface(CGLContextObj gl, CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid);

#define kCGSBufferedBackingType 2

#endif /* Bridge_h */
