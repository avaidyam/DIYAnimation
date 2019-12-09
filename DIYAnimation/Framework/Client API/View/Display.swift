import CoreGraphics.CGDirectDisplay
//import CoreGraphics.CGDirectDisplayMetal // for CGDirectDisplayCopyCurrentMetalDevice
import CoreGraphics.CGDisplayConfiguration // for mirroring, notifications, etc

// TODO: reshape/bounds changed callback

///
public final class Display {
    
    ///
    public struct Mode {
		public internal(set) var preferredScale: UInt
		public internal(set) var internalRepresentation: UInt
		public internal(set) var colorGamut: String
		public internal(set) var hdrMode: String
		public internal(set) var colorMode: String
		public internal(set) var highBandwidth: Bool
		public internal(set) var isVirtual: Bool
		public internal(set) var refreshRate: Double // TODO: set
		public internal(set) var pixelAspectRatio: Double
		public internal(set) var width: UInt // TODO: set
		public internal(set) var height: UInt // TODO: set
    }
    
    ///
    public struct Attributes {
		public internal(set) var legacyHDMIEDID: Bool
		public internal(set) var bt2020YCC: Int
		public internal(set) var hdrStaticMetadataType1: Int
		public internal(set) var pqEOTF: Int
		public internal(set) var dolbyVision: Int
    }
	
	public static var mainDisplay: Display {
		return Display() // CGMainDisplayID()
	}
	
	public static var displays: [Display] {
		return [Display()] // CGGetActiveDisplayList() or CGGetOnlineDisplayList()
	}
	
	// CGDisplayIsActive(), CGDisplayIsAsleep(), CGDisplayIsOnline(), CGDisplayIsMain(), CGDisplayIsBuiltin(), CGDisplayIsInMirrorSet(), CGDisplayIsAlwaysInMirrorSet(), CGDisplayIsInHWMirrorSet(), CGDisplayMirrorsDisplay(), CGDisplayUsesOpenGLAcceleration(), CGDisplayIsStereo(), CGDisplayPrimaryDisplay(), CGDisplayRotation()
	
	// CGDisplayUnitNumber(), CGDisplayVendorNumber(), CGDisplayModelNumber(), CGDisplaySerialNumber()
	
	// current = CGDisplayCopyDisplayMode() + CGDisplayBounds()
	// all = CGDisplayCopyAllDisplayModes()
	// set = CGDisplaySetDisplayMode()
	
	// mode.size = CGDisplayModeGetWidth(), CGDisplayModeGetHeight(), CGDisplayModeCopyPixelEncoding(), CGDisplayModeGetRefreshRate(), CGDisplayModeGetIOFlags(), CGDisplayModeGetPixelWidth(), CGDisplayModeGetPixelHeight(),
	
	// CGDisplayIsCaptured(), CGDisplayCaptureWithOptions(), CGCaptureAllDisplaysWithOptions(), CGDisplayRelease(), CGReleaseAllDisplays()
	
	// CGDisplayCreateImage//ForRect(), CGDisplayGetDrawingContext()
	
	// CGDirectDisplayCopyCurrentMetalDevice(), CGDisplayCopyColorSpace()
	
	// CGConfigureDisplayMirrorOfDisplay(), CGDisplayRegisterReconfigurationCallback()
	
	/*
	- (void)overrideDisplayTimings:(id)arg1;
	- (id)allowedHDRModes;
	- (id)preferredHDRModes;
	- (id)supportedHDRModes;
	- (id)preferredModeWithCriteria:(NSString *)hdrMode (double):refreshRate (CGSize):resolution;

	@property(nonatomic) double latency;
	@property(readonly, nonatomic) int linkQuality;
	@property(readonly, nonatomic) CADisplayAttributes *externalDisplayAttributes;
	- (id)description;
	@property(readonly, nonatomic) BOOL supportsExtendedColors;
	@property(readonly, nonatomic) unsigned int odLUTVersion;
	@property(readonly, nonatomic) NSString *currentOrientation;
	@property(readonly, nonatomic) NSString *nativeOrientation;
	@property(readonly, nonatomic, getter=isCloningSupported) BOOL cloningSupported;
	@property(readonly, nonatomic, getter=isCloned) BOOL cloned;
	@property(copy, nonatomic) NSString *overscanAdjustment;
	@property(readonly, nonatomic) struct CGSize overscanAmounts;
	@property(readonly, nonatomic) double overscanAmount;
	@property(readonly, nonatomic, getter=isOverscanned) BOOL overscanned;
	@property(readonly, nonatomic) long long minimumFrameDuration;
	@property(readonly, nonatomic) double heartbeatRate;
	@property(readonly, nonatomic) double refreshRate;
	@property(readonly, nonatomic, getter=isExternal) BOOL external;
	@property(readonly, nonatomic, getter=isSupported) BOOL supported;
	@property(readonly, nonatomic) int processId;
	@property(readonly, nonatomic) long long tag;
	@property(readonly, nonatomic) struct CGRect safeBounds;
	@property(readonly, nonatomic) struct CGRect frame;
	@property(readonly, nonatomic) struct CGRect bounds;
	@property BOOL allowsVirtualModes;
	@property(copy, nonatomic) NSString *colorMode;
	@property(readonly, nonatomic) CADisplayMode *preferredMode;
	@property(retain, nonatomic) CADisplayMode *currentMode;
	@property(readonly, nonatomic) NSArray *availableModes;
	@property(readonly, nonatomic) NSString *productName;
	@property(readonly, nonatomic) NSString *containerId;
	@property(readonly, nonatomic) NSString *uniqueId;
	@property(readonly, nonatomic) unsigned int connectionSeed;
	@property(readonly, nonatomic) unsigned int seed;
	@property(readonly, nonatomic) unsigned int displayId;
	@property(readonly, nonatomic) NSString *deviceName;
	@property(readonly, nonatomic) NSString *name;
	*/
	
}
