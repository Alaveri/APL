{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G+,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G+,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit Lzw;

interface

uses
  Objects,
  Collects,
  MemDrv,
  Streams,
  Compress;

type
  PLzwCompressor = ^TLzwCompressor;

  TLzwCompressor = object(TCompressor)
  private
    InputCode: integer;
    OutputCode: integer;
    procedure WriteHashCode(code: integer);
  public
    procedure Init; virtual;
    procedure InitCompression; virtual;
    procedure InitDecompression; virtual;
    procedure CompressStreamPos(sourcePos, destPos, length: longint); virtual;
    procedure DecompressStreamPos(sourcePos, destPos, length: longint); virtual;
  end;


implementation

const
  EmptyCode = -3;

procedure TLzwCompressor.Init;
begin
  inherited init;
end;

procedure TLzwCompressor.InitCompression;
begin
  inherited InitCompression;
  OutputCode := EmptyCode;
end;

procedure TLzwCompressor.InitDecompression;
begin
  inherited InitDecompression;
  InputCode := EmptyCode;
end;

procedure TLzwCompressor.WriteHashCode(code: integer);
begin
  if (code = EmptyCode) then begin
    Dest^.WriteInteger((code shr 4) and $FF);
    OutputCode := code and $0F;
  end
  else begin
    Dest^.WriteInteger((OutputCode shr 4) and $FF0 + (code shr 8) and $00F);
    OutputCode := EmptyCode;
  end;
end;

procedure TLzwCompressor.CompressStreamPos(sourcePos, destPos, length: longint);
begin
  inherited CompressStreamPos(sourcePos, destPos, length);
end;

procedure TLzwCompressor.DecompressStreamPos(sourcePos, destPos, length: longint);
begin
  inherited DecompressStreamPos(sourcePos, destPos, length);
end;

end.

