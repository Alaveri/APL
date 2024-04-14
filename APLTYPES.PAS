{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit AplTypes;

interface

type
  TModalResult =
  (
    mrNone,
    mrYes,
    mrNo,
    mrOk,
    mrCancel,
    mrHelp
  );


implementation

end.