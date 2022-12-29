(*$R-,V-,S-,I-*)
PROGRAM PibDComp;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*       Program:  PibDComp                                                 *)
(*                                                                          *)
(*       Purpose:  Decompresses a file compressed using Lempel-Ziv-Welch    *)
(*                 appraoch by PibCompr.                                    *)
(*                                                                          *)
(*       Use:      PIBDCOMP  inputfile outputfile                           *)
(*                                                                          *)
(*                    inputfile  --- the input file to be decompressed      *)
(*                    outputfile --- the output decompressed file           *)
(*                                                                          *)
(*       Remarks:                                                           *)
(*                                                                          *)
(*          PibDComp uncompresses a file compressed by PibCompr.            *)
(*                                                                          *)
(*       Algorithm:                                                         *)
(*                                                                          *)
(*          The decompression algorithm translates each received            *)
(*          code into a prefix string and extension [suffix] character.     *)
(*          The extension character is stored (in a push-down stack),       *)
(*          and the prefix translated again, until the prefix is a          *)
(*          single character, which completes decompression of this         *)
(*          code.  The entire code is then output by popping the stack.     *)
(*                                                                          *)
(*          "An update to the string table is made for each code received   *)
(*          (except the first one).  When a code has been translated,       *)
(*          its final character is used as the extension character,         *)
(*          combined with the prior string, to add a new string to          *)
(*          the string table.  This new string is assigned a unique         *)
(*          code value, which is the same code that the compressor          *)
(*          assigned to that string.  In this way, the decompressor         *)
(*          incrementally reconstructs the same string table that           *)
(*          the decompressor used.... Unfortunately ... [the algorithm]     *)
(*          does not work for an abnormal case.                             *)
(*                                                                          *)
(*          The abnormal case occurs whenever an input character string     *)
(*          contains the sequence C<w>C<w>C, where C<w> already             *)
(*          appears in the compressor string table."                        *)
(*                                                                          *)
(*          The decompression algorithm, augmented to handle                *)
(*          the abnormal case, is as follows:                               *)
(*                                                                          *)
(*            1. Read first input code;                                     *)
(*               Store in CODE and OLDcode;                                 *)
(*               With CODE = code(C), output(C);  FINchar = C;              *)
(*            2. Read next code to CODE; INcode = CODE;                     *)
(*               If at end of file, exit;                                   *)
(*            3. If CODE not in string table (special case) then            *)
(*                  Output(FINchar);                                        *)
(*                  CODE = OLDcode;                                         *)
(*                  INcode = code(OLDcode, FINchar);                        *)
(*            4. If CODE == code(<w>C) then                                 *)
(*                  Push C onto the stack;                                  *)
(*                  CODE == code(<w>);                                      *)
(*                  Goto 4.                                                 *)
(*            5. If CODE == code(C) then                                    *)
(*                  Output C;                                               *)
(*                  FINchar = C;                                            *)
(*            6. While stack not empty                                      *)
(*                  Output top of stack;                                    *)
(*                  Pop stack;                                              *)
(*            7. Put OLDcode,C into the string table.                       *)
(*               OLDcode = INcode;                                          *)
(*               Goto 2.                                                    *)
(*                                                                          *)
(*       Reference:                                                         *)
(*                                                                          *)
(*          "A Technique for High Performance Data Compression",            *)
(*          Terry A. Welch, IEEE Computer,                                  *)
(*          vol. 17, no. 6 (June 1984), pp. 8-19.                           *)
(*                                                                          *)
(*       Note:  The hashing algorithm used here isn't very good, and        *)
(*              should be replaced by a better one.                         *)
(*                                                                          *)
(*       Usage note:                                                        *)
(*                                                                          *)
(*          You may use this program in any way you see fit without         *)
(*          restriction.  I'd appreciate a citation if you do use this      *)
(*          code in a program you distribute.                               *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

(*$I PIBLZW.DEF *)

CONST
   MaxStack = 4096                 (* Decompression stack size  *);

VAR
                                   (* Decompression stack       *)

   Stack         : ARRAY[1..MaxStack] OF INTEGER;

   Stack_Pointer : INTEGER         (* Decompression stack depth *);

(*$I PIBLZW.INC *)

(*--------------------------------------------------------------------------*)
(*                  Push --- Push character onto stack                      *)
(*--------------------------------------------------------------------------*)

PROCEDURE Push( C : INTEGER );

BEGIN (* Push *)

  INC( Stack_Pointer );
  Stack[ Stack_Pointer ] := C;

  IF ( Stack_Pointer >= MaxStack ) THEN
     BEGIN
        WRITELN('Stack overflow!');
        Terminate;
        Halt;
     END;

END  (* Push *);

(*--------------------------------------------------------------------------*)
(*                  Pop --- Pop character from stack                        *)
(*--------------------------------------------------------------------------*)

PROCEDURE Pop( VAR C : INTEGER );

BEGIN (* Pop *)

   IF ( Stack_Pointer > 0 ) THEN
      BEGIN
         C := Stack[Stack_Pointer];
         DEC( Stack_Pointer );
      END
   ELSE
      C := Empty;

END   (* Pop *);

(*--------------------------------------------------------------------------*)
(*            Get_Code --- Get compression code from input file             *)
(*--------------------------------------------------------------------------*)

PROCEDURE Get_Code( VAR Hash_Code : INTEGER );

VAR
   Local_Buf : INTEGER;

BEGIN (* Get_Code *)

   IF ( Input_Code = Empty ) THEN
      BEGIN

         Get_Char( Local_Buf );

         IF ( Local_Buf = EOF_Char ) THEN
            BEGIN
               Hash_Code := EOF_Char;
               EXIT;
            END;

         Get_Char( Input_Code );

         IF ( Input_Code = EOF_Char ) THEN
            BEGIN
               Hash_Code := EOF_Char;
               EXIT;
            END;

         Hash_Code  := ( ( Local_Buf SHL 4  ) AND $FF0 ) +
                       ( ( Input_Code SHR 4 ) AND $00F );

         Input_Code := Input_Code AND $0F;

      END
   ELSE
      BEGIN

         Get_Char( Local_Buf );

         IF ( Local_Buf = EOF_Char ) THEN
            BEGIN
               Hash_Code := EOF_Char;
               EXIT;
            END;

         Hash_Code  := Local_Buf + ( ( Input_Code SHL 8 ) AND $F00 );
         Input_Code := Empty;

      END;

END   (* Get_Code *);

(*--------------------------------------------------------------------------*)
(*            Do_Decompression --- Perform decompression                    *)
(*--------------------------------------------------------------------------*)

PROCEDURE Do_Decompression;

VAR
   C         : INTEGER             (* Current input character *);
   Code      : INTEGER             (* Current code string     *);
   Old_Code  : INTEGER             (* Previous code string    *);
   Fin_Char  : INTEGER             (* Final input character   *);
   In_Code   : INTEGER             (* Current input code      *);
   Last_Char : INTEGER             (* Previous character      *);
   Unknown   : BOOLEAN             (* TRUE if code not found  *);
   Temp_C    : INTEGER             (* Char popped off stack   *);

BEGIN (* Do_Decompression *)
                                   (* Decompression stack is empty *)
  Stack_Pointer := 0;
                                   (* First string is always known *)
  Unknown       := FALSE;
                                   (* Get first string == Step 1   *)
  Get_Code( Old_Code );

  Code          := Old_Code;
                                   (* Output corresponding character *)

  C    := String_Table[Code].FollChar;

  Put_Char( C );
                                   (* Remember this character  -- it    *)
                                   (* is final character of next string *)
  Fin_Char := C;
                                   (* Get next code  == Step 2 *)
  Get_Code( In_Code );

  WHILE( In_Code <> EOF_Char ) DO
     BEGIN
                                   (* Set code to this input code *)
        Code := In_Code;
                                   (* If code not in table, do special *)
                                   (* case ==> Step 3                  *)

        IF ( NOT String_Table[Code].Used ) THEN
           BEGIN
              Last_Char := Fin_Char;
              Code      := Old_Code;
              Unknown   := TRUE;
           END;
                                   (* Run through code extracting single *)
                                   (* characters from code string until  *)
                                   (* no more characters can be removed. *)
                                   (* Push these onto stack.  They will  *)
                                   (* be entered in reverse order, and   *)
                                   (* will come out in forwards order    *)
                                   (* when popped off.                   *)
                                   (*                                    *)
                                   (* ==> Step 4                         *)

        WHILE( String_Table[Code].PrevChar <> No_Prev ) DO
           WITH String_Table[Code] DO
              BEGIN
                 Push( FollChar );
                 Code := PrevChar;
              END;
                                   (* We now have the first character in *)
                                   (* the string.                        *)

        Fin_Char := String_Table[Code].FollChar;

                                   (* Output first character  ==> Step 5   *)
        Put_Char( Fin_Char );
                                   (* While the stack is not empty, remove *)
                                   (* and output all characters from stack *)
                                   (* which are rest of characters in the  *)
                                   (* string.                              *)
                                   (*                                      *)
                                   (* ==> Step 6                           *)
        Pop( Temp_C );

        WHILE( Temp_C <> Empty ) DO
           BEGIN
              Put_Char( Temp_C );
              Pop( Temp_C );
           END;
                                   (* If code isn't known, output the      *)
                                   (* follower character of last character *)
                                   (* of string.                           *)
        IF Unknown THEN
           BEGIN
              Fin_Char := Last_Char;
              Put_Char( Fin_Char );
              Unknown  := FALSE;
           END;
                                   (* Enter code into table ==> Step 7 *)

        Make_Table_Entry( Old_Code , Fin_Char );

                                   (* Make current code the previous code *)
        Old_Code := In_Code;

                                   (* Get next code  == Step 2 *)
        Get_Code( In_Code );

     END;

END   (* Do_Decompression *);

(*--------------------------------------------------------------------------*)
(*                     PibDComp --- Main program                            *)
(*--------------------------------------------------------------------------*)

BEGIN (* PibDComp *)
                                   (* Indicate we are doing decompression *)
   If_Compressing := FALSE;
                                   (* Initialize for deceompression       *)
   Initialize;
                                   (* Perform decompression               *)
   Do_Decompression;
                                   (* Clean up and exit                   *)
   Terminate;

END   (* PibDComp *).

