import OpenGL.GL

// .Surface or .IOSurface classes = display's buffer (can be used by CA::OGL::Context)
// TODO: DisplayStream to mimic ^

/*
SkyLight:
	1. Locate display surface
	2. Ask display surface for IOSurface
	3. Create metal compositor
	4. Render
	5. Flush

DIYAnimation:
	1. Create window "surface" (GL context)
	2. Create IOSurface
	3. Create metal compositor
	4. Render
	***** 5. Blit to GL context [PERFORMANCE OVERHEAD HERE]
	6. Flush
*/
