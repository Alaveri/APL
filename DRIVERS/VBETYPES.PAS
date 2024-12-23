unit VbeTypes;

interface

const
  mmTextMode = $00;
  mmCgaGraphics = $01;
  mmHercules = $02;
  mmPlanar = $03;
  mmPackedPixel = $04;
  mmNonChanged256 = $05;
  mmDirectColor = $06;
  mmYuv = $07;
  {08h-0Fh Reserved, to be defined by VESA}
  {10h-FFh Reserved, to be defined by OEM}

type
  PVbeInfo = ^TVbeInfo;
  PVbeModeInfo1 = ^TVbeModeInfo1;
  PVbeModeInfo2 = ^TVbeModeInfo2;
  PVbeModeInfo3 = ^TVbeModeInfo3;
  PVbeMode = ^TVbeMode;

  TVbeCapability =
  (
    {set = DAC switchable, 8 bits per primary color; not set = DAC not
    switchable, 6 bits per primary color}
    vbeDacSwitchable,
    vbeVgaCompatible,
    {When programming large blocks of information into the RAMDAC, use the
    blank bit in function 09h}
    vbeUseFunction09BlankBit,
    vbeStereoscopicSupported,
    vbeStereoSignalingSupported
  );

  TVbeModeAttribute =
  (
    vbeSupportedInHardware,
    {In VBE 1.0 and 1.1, indicates if optional info after
    BytesPerScanLine is available.  Always available in 2.
    TVbeModeInfo.v2 is available}
    vbeOptionalInfoAvail,
    vbeTtyOutputSupported,
    vbeIsColor,
    vbeIsGraphics,
    vbeIsNotVgaCompatible,
    vbeWindowedModeAvail,
    vbeLinearModeAvail,
    vbeDoubleScanModeAvail,
    vbeInterlacedModeAvail,
    vbeTripleBufferAvail,
    vbeDualDisplayAvail
  );

  TVbeWindowAttribute =
  (
    vbeRelocWindowsSupported,
    vbeWindowReadable,
    vbeWindowWritable
  );

  TVbeCapabilities = set of TVbeCapability;
  TVbeModeAttributes = set of TVbeModeAttribute;
  TVbeWindowAttributes = set of TVbeWindowAttribute;

  TVbeSupport =
  (
    vbe1,
    vbe2,
    vbe3
  );

  TVbeInfo = record
    VbeSignature: array[0..3] of char;
    VbeVersion: word;
    OemStringPtr: pointer;
    Capabilities: TVbeCapabilities;
    Capabilities2: byte;
    Capabilities3: byte;
    Capabilities4: byte;
    VideoModePtr: pointer;
    TotalMemory: word;
    OemSoftwareRev: word;
    OemVendorNamePtr: PChar;
    OemProductName: PChar;
    OemProductRevision: PChar;
    Reserved: array[1..222] of byte;
    OemData: array[1..256] of byte
  end;

  TVbeModeInfo1 = record
    ModeAttributes: TVbeModeAttributes;
    WinAAttributes: TVbeWindowAttributes;
    WinBAttributes: TVbeWindowAttributes;
    {Smallest size in KBytes on which the window can be placed in frame
    buffer memory. Value is undefined if WindowAttributes bit 0 is not set.}
    WinGranularity: word;
    WinSize: word; {Size of the window in KBytes.}
    {Segment addresses where windows are located.}
    WinSegmentA: word;
    WinSegmentB: word;
    {The windowing function pointer.  If null, function 05h must be used instead.}
    WinFuncPtr: pointer;
    BytesPerScanLine: word; {Bytes per horizontal line.}
    XResolution: word; {Width in pixels.}
    YResolution: word; {Height in pixels.}
    XCharSize: byte; {Character cell width in pixels}
    YCharSize: byte; {Character cell height in pixels}
    Planes: byte; {Number of memory planes.}
    Bpp: byte; {Bits per pixel.}
    NumberOfBanks: byte; {Total number of banks in this mode.}
    MemoryModel: byte; {See MemoryModel constants above}
    BankSize: byte; {Bank size in number of KBytes.}
    NumberOfImagePages: byte; {Number of pages that will fit in video memory}
    Reserved0: byte;
    RedMask: byte; {Size of direct color red mask in bits}
    RedPosition: byte; {Bit position of lsb of red mask}
    GreenMask: byte; {Size of direct color green mask in bits}
    GreenPosition: byte; {Bit position of lsb of green mask}
    BlueMask: byte; {Size of direct color blue mask in bits}
    BluePosition: byte; {Bit position of lsb of blue mask}
    RsvdMask: byte; {Size of direct color reserved mask in bits}
    RsvdPosition: byte; {Bit position of lsb of reserved mask}
    DirectColorModeInfo: byte; {Direct color mode attributes}
  end;

  TVbeModeInfo2 = record
    PhysBasePtr: pointer; {Physical address of the linear frame buffer}
    OffScreenMemOffset: longint; {pointer to start of off screen memory}
    OffScreenMemSize: word; {amount of off screen memory in 1k units}
  end;

  TVbeModeInfo3 = record
    LinBytesPerScanLine: word; {Bytes per scan line for linear modes}
    BnkNumberOfImagePages: byte; {Number of images for banked modes}
    LinNumberOfImagePages: byte; {Number of images for linear modes}
    LinRedMaskSize: byte; {Size of direct color red mask in linear modes}
    LinRedFieldPosition: byte; {Bit position of lsb of red mask}
    LinGreenMaskSize: byte; {Size of direct color green mask in linear modes}
    LinGreenFieldPosition: byte; {Bit position of lsb of green mask}
    LinBlueMaskSize: byte; {Size of direct color blue mask in linear modes}
    LinBlueFieldPosition: byte; {Bit position of lsb of blue mask}
    LinRsvdMaskSize: byte; {Size of direct color reserved mask in linear modes}
    LinRsvdFieldPosition: byte; {Bit position of lsb of reserved mask}
    MaxPixelClock: longint; {Maximum pixel clock (in hz) for graphics modes}
    Reserved4: array[0..189] of byte;
  end;

  TVbeMode = record
    v1: TVbeModeInfo1;
    v2: TVbeModeInfo2;
    v3: TVbeModeInfo3;
  end;

implementation

end.