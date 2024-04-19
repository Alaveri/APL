{$IFDEF debug}
  {$A-,B-,D+,F+,G-,I+,L+,N+,O-,R+,S+,V-,X+}
{$ELSE}
  {$A-,B-,D-,F+,G-,I+,L-,N+,O-,R-,S-,V-,X+}
{$ENDIF}
{$IFDEF VER70}
  {$IFDEF debug}
    {$P+,Q+,T-}
  {$ELSE}
    {$P+,Q-,T-}
  {$ENDIF}
{$ENDIF}