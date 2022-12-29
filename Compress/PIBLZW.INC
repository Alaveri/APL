(*--------------------------------------------------------------------------*)
(*          Terminate --- Finish output file, close files.                  *)
(*--------------------------------------------------------------------------*)

PROCEDURE Terminate;

BEGIN (* Terminate *)
                                   (* Write any remaining characters *)
                                   (* to output file.                *)
   IF ( Output_Pos > 0 ) THEN
      BlockWrite( Output_File, Output_Buffer, Output_Pos );

   Ierr := IOResult;
                                   (* Close input and output files   *)
   CLOSE( Input_File  );
   Ierr := IOResult;

   CLOSE( Output_File );
   Ierr := IOResult;

END   (* Terminate *);

(*--------------------------------------------------------------------------*)
(*          Get_Hash_Code --- Gets hash code for given <w>C string          *)
(*--------------------------------------------------------------------------*)

FUNCTION Get_Hash_Code( PrevC, FollC : INTEGER ) : INTEGER;

VAR
   Index  : INTEGER;
   Index2 : INTEGER;

BEGIN (* Get_Hash_Code *)
                                   (* Get initial index using hashing *)

   Index := ( ( PrevC SHL 5 ) XOR FollC ) AND MaxTab;

                                   (* If entry not already used, return *)
                                   (* its index as hash code for <w>C.  *)

   IF ( NOT String_Table[Index].Used ) THEN
      Get_Hash_Code := Index
   ELSE
                                   (* If entry already used, search to  *)
                                   (* end of list of hash collision     *)
                                   (* entries for this hash code.       *)
                                   (* Do linear probe to find an        *)
                                   (* available slot.                   *)
      BEGIN

                                   (* Skip to end of collision list ... *)

         WHILE ( String_Table[Index].Next <> End_List ) DO
            Index := String_Table[Index].Next;

                                   (* Begin linear probe down a bit from  *)
                                   (* last entry in collision list ...    *)

         Index2 := ( Index + 101 ) AND MaxTab;

                                   (* Look for unused entry using linear  *)
                                   (* probing ...                         *)

         WHILE ( String_Table[Index2].Used ) DO
            Index2 := SUCC( Index2 ) AND MaxTab;

                                   (* Point prior end of collision list   *)
                                   (* to this new node.                   *)

         String_Table[Index].Next := Index2;

                                   (* Return hash code for <w>C           *)

         Get_Hash_Code          := Index2;

      END;

END   (* Get_Hash_Code *);

(*--------------------------------------------------------------------------*)
(*          Make_Table_Entry --- Enter <w>C string in string table          *)
(*--------------------------------------------------------------------------*)

PROCEDURE Make_Table_Entry( PrevC, FollC: INTEGER );

BEGIN (* Make_Table_Entry *)
                                   (* Only enter string if there is room left *)

   IF ( Table_Used <= MaxTab ) THEN
      BEGIN
         WITH String_Table[ Get_Hash_Code( PrevC , FollC ) ] DO
            BEGIN
               Used     := TRUE;
               Next     := End_List;
               PrevChar := PrevC;
               FollChar := FollC;
            END;
                                   (* Increment count of items used *)

         INC( Table_Used );
(*
         IF ( Table_Used > ( MaxTab + 1 ) ) THEN
            BEGIN
               WRITELN('Hash table full.');
            END;
*)
      END;

END   (* Make_Table_Entry *);

(*--------------------------------------------------------------------------*)
(*            Initialize_String_Table --- Initialize string table           *)
(*--------------------------------------------------------------------------*)

PROCEDURE Initialize_String_Table;

VAR
   I: INTEGER;

BEGIN (* Initialize_String_Table *)

                                   (* No entries used in table yet *)
   Table_Used  := 0;
                                   (* Clear all table entries      *)
   FOR I := 0 TO MaxTab DO
      WITH String_Table[I] DO
         BEGIN
            PrevChar := No_Prev;
            FollChar := No_Prev;
            Next     := -1;
            Used     := FALSE;
         END;
                                   (* Enter all single characters into *)
                                   (* table                            *)
   FOR I := 0 TO 255 DO
      Make_Table_Entry( No_Prev , I );

END   (* Initialize_String_Table *);

(*--------------------------------------------------------------------------*)
(*            Initialize --- Initialize compression/decompression           *)
(*--------------------------------------------------------------------------*)

PROCEDURE Initialize;

VAR
   Input_Name  : AnyStr            (* Input file name  *);
   Output_Name : AnyStr            (* Output file name *);

BEGIN (* Initialize *)
                                   (* Get the input file *)
   IF ( ParamCount > 0 ) THEN
      Input_Name := ParamStr( 1 )
   ELSE
      BEGIN

         CASE If_Compressing OF
            TRUE:  WRITE('Enter name of file to compress      : ');
            FALSE: WRITE('Enter name of file to decompress      : ');
         END (* CASE *);

         READLN( Input_Name );
         Ierr := IOResult;

      END;
                                   (* Open input file *)

   ASSIGN ( Input_File , Input_Name );
   RESET  ( Input_File , 1 );
   Ierr := IOResult;
                                   (* Get the output file *)
   IF ( ParamCount > 1 ) THEN
      Output_Name := ParamStr( 2 )
   ELSE
      BEGIN

         CASE If_Compressing OF
            TRUE:  WRITE('Enter name of output compressed file: ');
            FALSE: WRITE('Enter name of output uncompressed file: ');
         END (* CASE *);

         READLN( Output_Name );
         Ierr := IOResult;

      END;
                                   (* Open output file *)

   ASSIGN ( Output_File , Output_Name );
   REWRITE( Output_File , 1 );
   Ierr := IOResult;
                                   (* Point input point past end of *)
                                   (* buffer to force initial read  *)
   Input_Pos  := MaxBuff + 1;
                                   (* Nothing written out yet       *)
   Output_Pos := 0;
                                   (* Nothing read in yet           *)
   InBufSize  := 0;
                                   (* No input or output codes yet  *)
                                   (* constructed                   *)
   Output_Code := Empty;
   Input_Code  := Empty;
                                   (* Initialize string hash table  *)
   Initialize_String_Table;

END   (* Initialize *);

(*--------------------------------------------------------------------------*)
(*            Lookup_String --- Look for string <w>C in string table        *)
(*--------------------------------------------------------------------------*)

FUNCTION Lookup_String( PrevC, FollC: INTEGER ) : INTEGER;

VAR
   Index  : INTEGER;
   Index2 : INTEGER;
   Found  : BOOLEAN;

BEGIN (* Lookup_String *)
                                   (* Initialize index to check from hash *)

   Index       := ( ( PrevC SHL 5 ) XOR FollC ) AND MaxTab;

                                   (* Assume we won't find string *)
   Lookup_String := End_List;
                                   (* Search through list of hash collision *)
                                   (* entries for one that matches <w>C     *)
   REPEAT

      Found := ( String_Table[Index].PrevChar = PrevC ) AND
               ( String_Table[Index].FollChar = FollC );

      IF ( NOT Found ) THEN
         Index := String_Table[Index].Next;

   UNTIL Found OR ( Index = End_List );

                                   (* Return index if <w>C found in table. *)
   IF Found THEN
      Lookup_String := Index;

END   (* Lookup_String *);

(*--------------------------------------------------------------------------*)
(*              Get_Char  ---  Read character from input file               *)
(*--------------------------------------------------------------------------*)

PROCEDURE Get_Char( VAR C: INTEGER );

BEGIN (* Get_Char *)
                                   (* Point to next character in buffer *)
   INC( Input_Pos );
                                   (* If past end of block read in, then *)
                                   (* reset input pointer and read in    *)
                                   (* next block.                        *)

   IF ( Input_Pos > InBufSize ) THEN
      BEGIN
         BlockRead( Input_File, Input_Buffer, MaxBuff, InBufSize );
         Input_Pos := 1;
         Ierr      := IOResult;
      END;
                                  (* If end of file hit, return EOF_Char *)
                                  (* otherwise return next character in  *)
                                  (* input buffer.                       *)
   IF ( InBufSize = 0 ) THEN
      C := EOF_Char
   ELSE
      C := Input_Buffer[Input_Pos];

END   (* Get_Char *);

(*--------------------------------------------------------------------------*)
(*             Write_Char  ---  Write character to output file              *)
(*--------------------------------------------------------------------------*)

PROCEDURE Put_Char( C : INTEGER );

BEGIN (* Put_Char *)
                                   (* If buffer full, write it out and *)
                                   (* reset output buffer pointer.     *)

   IF ( Output_Pos >= MaxBuff ) THEN
      BEGIN
         BlockWrite( Output_File, Output_Buffer, MaxBuff );
         Output_Pos := 0;
         Ierr       := IOResult;
      END;
                                   (* Place character in next slot in  *)
                                   (* output buffer.                   *)

   INC( Output_Pos );
   Output_Buffer[Output_Pos] := C;

END   (* Put_Char *);
