{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G+,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}unit Compress;

interface

uses
  Objects,
  Streams;

type
  PCompressor = ^TCompressor;
  TCompressor = object(TBaseObject)
  private
  public
    Source: PStream;
    Dest: PStream;
    SourceStart: longint;
    SourceLength: longint;
    DestStart: longint;
    constructor Create(newSource, newDest: PStream);
    procedure Init; virtual;
    procedure InitCompression; virtual;
    procedure InitDecompression; virtual;
    procedure CompressStream; virtual;
    procedure DecompressStream; virtual;
    procedure CompressStreamPos(sourcePos, destPos, length: longint); virtual;
    procedure DecompressStreamPos(sourcePos, destPos, length: longint); virtual;
  end;

implementation

constructor TCompressor.Create(newSource, newDest: PStream);
begin
  inherited Create;
  Source := newSource;
  Dest := newDest;
end;


procedure TCompressor.Init;
begin
  inherited Init;
  Source := nil;
  Dest := nil;
  SourceStart := 0;
  SourceLength := 0;
  DestStart := 0;
  InitCompression;
  InitDecompression;
end;

procedure TCompressor.InitCompression;
begin
end;

procedure TCompressor.InitDecompression;
begin
end;

procedure TCompressor.CompressStreamPos(sourcePos, destPos, length: longint);
begin
  InitCompression;
  SourceStart := sourcePos;
  SourceLength := length;
  DestStart := destStart;
  Source^.Seek(sourcePos, soFromBeginning);
  Dest^.Seek(destPos, soFromBeginning);
end;

procedure TCompressor.DecompressStreamPos(sourcePos, destPos, length: longint);
begin
  InitDecompression;
  SourceStart := sourcePos;
  SourceLength := length;
  DestStart := destStart;
  Source^.Seek(sourcePos, soFromBeginning);
  Dest^.Seek(destPos, soFromBeginning);
end;

procedure TCompressor.CompressStream;
begin
  CompressStreamPos(0, 0, Source^.Length);
end;

procedure TCompressor.DecompressStream;
begin
  DecompressStreamPos(0, 0, Source^.Length);
end;

end.