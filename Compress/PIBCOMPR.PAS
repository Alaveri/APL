(*$R-,V-,S-,I-*)
PROGRAM PibCompr;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*       Program:  PibCompr                                                 *)
(*                                                                          *)
(*       Purpose:  Compresses a file using the Lempel-Ziv-Welch approach.   *)
(*                                                                          *)
(*       Author:   Philip R. Burns.   April 30, 1988.                       *)
(*                                                                          *)
(*       Use:      PIBCOMPR  inputfile outputfile                           *)
(*                                                                          *)
(*                    inputfile  --- the input file to be compressed        *)
(*                    outputfile --- the output compressed file             *)
(*                                                                          *)
(*       Remarks:                                                           *)
(*                                                                          *)
(*          PibCompr implements the Lempel-Ziv file compression algorithm.  *)
(*          (Files compressed by PibCommpr are uncompressed by PibDComp.)   *)
(*          It operates by finding common substrings and replaces them      *)
(*          with a fixed-length 12-bit code.  This is deterministic, and    *)
(*          can be done with a single pass over the file.  Thus,            *)
(*          the decompression procedure needs no input table, but           *)
(*          can track the way the table was built.                          *)
(*                                                                          *)
(*       Algorithm:                                                         *)
(*                                                                          *)
(*                                                                          *)
(*          This section is abstracted from Terry Welch's article           *)
(*          referenced below.  The algorithm builds a string                *)
(*          translation table that maps substrings in the input             *)
(*          into fixed-length codes.  The compress algorithm may            *)
(*          be described as follows:                                        *)
(*                                                                          *)
(*            1. Initialize table to contain single-character strings.      *)
(*            2. Read the first character.  Set <w> (the prefix string)     *)
(*               to that character.                                         *)
(*            3. (step): Read next input character, C.                      *)
(*            4. If at end of file, output code(<w>); exit.                 *)
(*            5. If <w>C is in the string table:                            *)
(*                  Set <w> to <w>C; goto step 3.                           *)
(*            6. Else <w>C is not in the string table.                      *)
(*                  Output code(<w>);                                       *)
(*                  Put <w>C into the string table;                         *)
(*                  Set <w> to C; Goto step 3.                              *)
(*                                                                          *)
(*          "At each execution of the basic step an acceptable input        *)
(*          string <w> has been parsed off.  The next character C is        *)
(*          read and the extended string <w>C is tested to see if it        *)
(*          exists in the string table.  If it is there, then the           *)
(*          extended string becomes the parsed string <w> and the           *)
(*          step is repeated.  If <w>C is not in the string table,          *)
(*          then it is entered, the code for the successfully               *)
(*          parsed string <w> is put out as comprssed data, the             *)
(*          character K becomes the beginning of the next string,           *)
(*          and the step is repeated."                                      *)
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
(*$I PIBLZW.INC *)

(*--------------------------------------------------------------------------*)
(*             Put_Code  ---  Write hash code to output file.               *)
(*--------------------------------------------------------------------------*)

PROCEDURE Put_Code( Hash_Code : INTEGER );

BEGIN (* Put_Code *)
                                   (* Output code word is empty.        *)
                                   (* Put out 1st 8 bits of compression *)
                                   (* code and save last 4 bit for next *)
                                   (* time through.                     *)

   IF ( Output_Code = Empty ) THEN
      BEGIN
         Put_Char( ( Hash_Code SHR 4 ) AND $FF );
         Output_Code := Hash_Code AND $0F;
      END
   ELSE
                                   (* Output code word not empty.         *)
                                   (* Put out last 4 bits of previous     *)
                                   (* code appended to 1st 4 bits of this *)
                                   (* code.  Then put out last 8 bits of  *)
                                   (* this code.                          *)
      BEGIN
         Put_Char( ( ( Output_Code SHL 4 ) AND $FF0 ) +
                   ( ( Hash_Code SHR 8 ) AND $00F ) ) ;
         Put_Char( Hash_Code AND $FF );
         Output_Code := Empty;
      END;

END   (* Put_Code *);

(*--------------------------------------------------------------------------*)
(*             Do_Compression --- Perform Lempel-Ziv-Welch compression      *)
(*--------------------------------------------------------------------------*)

PROCEDURE Do_Compression;

VAR
   C  : INTEGER             (* Current input character = C *);
   WC : INTEGER             (* Hash code value for <w>C    *);
   W  : INTEGER             (* Hash code value for <w>     *);

BEGIN (* Do_Compression *)
                                   (* Read first character ==> Step 2 *)
   Get_Char( C );
                                   (* Initial hash code -- first character *)
                                   (* has no previous string (<w> is null) *)

   W := Lookup_String( No_Prev , C );

                                   (* Get next character ==> Step 3    *)
   Get_Char( C );
                                   (* Loop over input characters until *)
                                   (* end of file reached ==> Step 4.  *)
   WHILE( C <> EOF_Char ) DO
      BEGIN
                                   (* See if <w>C is in table. *)

         WC := Lookup_String( W , C );

                                   (* If <w>C is not in the table, *)
                                   (* enter it into the table and  *)
                                   (* output <w>.  Reset <w> to    *)
                                   (* be the code for C ==> Step 6 *)

         IF ( WC = End_List ) THEN
            BEGIN

               Make_Table_Entry( W , C );
               Put_Code( W );
               W := Lookup_String( No_Prev , C );

            END
         ELSE                      (* If <w>C is in table, keep looking *)
                                   (* for longer strings == Step 5      *)

            W := WC;

                                   (* Get next input character ==> Step 3 *)
         Get_Char( C );

      END;
                                   (* Make sure last code is       *)
                                   (* written out ==> Step 4.      *)
   Put_Code( W );

END   (* Do_Compression *);

(*--------------------------------------------------------------------------*)
(*                     PibCompr --- Main program                            *)
(*--------------------------------------------------------------------------*)

BEGIN (* PibCompr *)
                                   (* We are doing compression *)
   If_Compressing := TRUE;
                                   (* Initialize compression   *)
   Initialize;
                                   (* Perform compression      *)
   Do_Compression;
                                   (* Clean up and exit        *)
   Terminate;

END   (* PibCompr *).
