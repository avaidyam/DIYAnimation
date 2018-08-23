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

#endif /* Bridge_h */
