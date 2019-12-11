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

/*
+ (id)serverIfRunning;
+ (id)serverWithOptions:(id)arg1;
+ (id)server;
+ (id)contextWithOptions:(id)arg1;
+ (id)context;

- (unsigned int)contextIdHostingContextId:(unsigned int)arg1;
- (unsigned int)taskNamePortOfContextId:(unsigned int)arg1;
- (unsigned int)clientPortOfContextId:(unsigned int)arg1;

@property(readonly) NSArray *displays;
- (void)_detectDisplays;
- (id)displayWithUniqueId:(id)arg1;
- (id)displayWithDisplayId:(unsigned int)arg1;
- (id)displayWithName:(id)arg1;
- (void)removeAllDisplays;
- (void)removeDisplay:(id)arg1;
- (void)addDisplay:(id)arg1;
@property(getter=isMirroringEnabled) BOOL mirroringEnabled;
*/
