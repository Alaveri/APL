{$I COMPILER.INC}
unit VgaConst;

interface

const
  VgaScIndex = $03C4;
  VgaScData = $03C5;
  VgaCrtcIndex = $03D4;
  VgaCrtcData = $03D5;
  VgaMiscOutput = $03C2;

  VgaMemoryMode = $04;
  VgaDwordModeDisable = $14; { Underline Location Register }
  VgaModeControl = $17;
  VgaVSyncPolarity = $E3;
  VgaMapMask = $02;

  VgaChain4Disable = $06 shl 8;
  VgaWordDisable = $E3 shl 8;
  VgaAllPlanes = $FF shl 8;
  VgaSynchronousReset = $01 shl 8;

  VgaPaletteIndex = $03C8;
  VgaPaletteData = $03C9;
  VgaInputStatus = $03DA;
  VgaGcIndex = $03CE;
  VgaGcData = $03CF;

  VgaDisplayEnable = $01;
  VgaRetrace = $08;

  VgaHighAddress = $0C;
  VgaLowAddress = $0D;

implementation

end.