{$I COMPILER.INC}
unit ZLibType;

interface

uses
  AplConst,
  AplObj,
  AplStr,
  AplTypes,
  Lists,
  Strings;

type
  TCodeTag = record
    Bits: byte;
    Op: byte;
    Val: word;
  end;

const
  EnoughLens = 852;
  EnoughDists = 592;
  Enough = EnoughLens + EnoughDists;

  LenFix: array[0..511] of TCodeTag = (
    (Bits: 96; Op: 7; Val: 0), (Bits: 0; Op: 8; Val: 80), (Bits: 0; Op: 8; Val: 16),
    (Bits: 20; Op: 8; Val: 115), (Bits: 18; Op: 7; Val: 31), (Bits: 0; Op: 8; Val: 112),
    (Bits: 0; Op: 8; Val: 48), (Bits: 0; Op: 9; Val: 192), (Bits: 16; Op: 7; Val: 10),
    (Bits: 0; Op: 8; Val: 96), (Bits: 0; Op: 8; Val: 32), (Bits: 0; Op: 9; Val: 160),
    (Bits: 0; Op: 8; Val: 0), (Bits: 0; Op: 8; Val: 128), (Bits: 0; Op: 8; Val: 64),
    (Bits: 0; Op: 9; Val: 224), (Bits: 16; Op: 7; Val: 6), (Bits: 0; Op: 8; Val: 88),
    (Bits: 0; Op: 8; Val: 24), (Bits: 0; Op: 9; Val: 144), (Bits: 19; Op: 7; Val: 59),
    (Bits: 0; Op: 8; Val: 120), (Bits: 0; Op: 8; Val: 56), (Bits: 0; Op: 9; Val: 208),
    (Bits: 17; Op: 7; Val: 17), (Bits: 0; Op: 8; Val: 104), (Bits: 0; Op: 8; Val: 40),
    (Bits: 0; Op: 9; Val: 176), (Bits: 0; Op: 8; Val: 8), (Bits: 0; Op: 8; Val: 136),
    (Bits: 0; Op: 8; Val: 72), (Bits: 0; Op: 9; Val: 240), (Bits: 16; Op: 7; Val: 4),
    (Bits: 0; Op: 8; Val: 84), (Bits: 0; Op: 8; Val: 20), (Bits: 21; Op: 8; Val: 227),
    (Bits: 19; Op: 7; Val: 43), (Bits: 0; Op: 8; Val: 116), (Bits: 0; Op: 8; Val: 52),
    (Bits: 0; Op: 9; Val: 200), (Bits: 17; Op: 7; Val: 13), (Bits: 0; Op: 8; Val: 100),
    (Bits: 0; Op: 8; Val: 36), (Bits: 0; Op: 9; Val: 168), (Bits: 0; Op: 8; Val: 4),
    (Bits: 0; Op: 8; Val: 132), (Bits: 0; Op: 8; Val: 68), (Bits: 0; Op: 9; Val: 232),
    (Bits: 16; Op: 7; Val: 8), (Bits: 0; Op: 8; Val: 92), (Bits: 0; Op: 8; Val: 28),
    (Bits: 0; Op: 9; Val: 152), (Bits: 20; Op: 7; Val: 83), (Bits: 0; Op: 8; Val: 124),
    (Bits: 0; Op: 8; Val: 60), (Bits: 0; Op: 9; Val: 216), (Bits: 18; Op: 7; Val: 23),
    (Bits: 0; Op: 8; Val: 108), (Bits: 0; Op: 8; Val: 44), (Bits: 0; Op: 9; Val: 184),
    (Bits: 0; Op: 8; Val: 12), (Bits: 0; Op: 8; Val: 140), (Bits: 0; Op: 8; Val: 76),
    (Bits: 0; Op: 9; Val: 248), (Bits: 16; Op: 7; Val: 3), (Bits: 0; Op: 8; Val: 82),
    (Bits: 0; Op: 8; Val: 18), (Bits: 21; Op: 8; Val: 163), (Bits: 19; Op: 7; Val: 35),
    (Bits: 0; Op: 8; Val: 114), (Bits: 0; Op: 8; Val: 50), (Bits: 0; Op: 9; Val: 196),
    (Bits: 17; Op: 7; Val: 11), (Bits: 0; Op: 8; Val: 98), (Bits: 0; Op: 8; Val: 34),
    (Bits: 0; Op: 9; Val: 164), (Bits: 0; Op: 8; Val: 2), (Bits: 0; Op: 8; Val: 130),
    (Bits: 0; Op: 8; Val: 66), (Bits: 0; Op: 9; Val: 228), (Bits: 16; Op: 7; Val: 7),
    (Bits: 0; Op: 8; Val: 90), (Bits: 0; Op: 8; Val: 26), (Bits: 0; Op: 9; Val: 148),
    (Bits: 20; Op: 7; Val: 67), (Bits: 0; Op: 8; Val: 122), (Bits: 0; Op: 8; Val: 58),
    (Bits: 0; Op: 9; Val: 212), (Bits: 18; Op: 7; Val: 19), (Bits: 0; Op: 8; Val: 106),
    (Bits: 0; Op: 8; Val: 42), (Bits: 0; Op: 9; Val: 180), (Bits: 0; Op: 8; Val: 10),
    (Bits: 0; Op: 8; Val: 138), (Bits: 0; Op: 8; Val: 74), (Bits: 0; Op: 9; Val: 244),
    (Bits: 16; Op: 7; Val: 5), (Bits: 0; Op: 8; Val: 86), (Bits: 0; Op: 8; Val: 22),
    (Bits: 64; Op: 8; Val: 0), (Bits: 19; Op: 7; Val: 51),(Bits: 0; Op: 8; Val: 118),
    (Bits: 0; Op: 8; Val: 54), (Bits: 0; Op: 9; Val: 204), (Bits: 17; Op: 7; Val: 15),
    (Bits: 0; Op: 8; Val: 102), (Bits: 0; Op: 8; Val: 38), (Bits: 0; Op: 9; Val: 172),
    (Bits: 0; Op: 8; Val: 6), (Bits: 0; Op: 8; Val: 134), (Bits: 0; Op: 8; Val: 70),
    (Bits: 0; Op: 9; Val: 236), (Bits: 16; Op: 7; Val: 9), (Bits: 0; Op: 8; Val: 94),
    (Bits: 0; Op: 8; Val: 30), (Bits: 0; Op: 9; Val: 156), (Bits: 20; Op: 7; Val: 99),
    (Bits: 0; Op: 8; Val: 126), (Bits: 0; Op: 8; Val: 62), (Bits: 0; Op: 9; Val: 220),
    (Bits: 18; Op: 7; Val: 27), (Bits: 0; Op: 8; Val: 110),(Bits: 0; Op: 8; Val: 46),
    (Bits: 0; Op: 9; Val: 188), (Bits: 0; Op: 8; Val: 14), (Bits: 0; Op: 8; Val: 142),
    (Bits: 0; Op: 8; Val: 78), (Bits: 0; Op: 9; Val: 252), (Bits: 96; Op: 7; Val: 0),
    (Bits: 0; Op: 8; Val: 81), (Bits: 0; Op: 8; Val: 17), (Bits: 21; Op: 8; Val: 131),
    (Bits: 18; Op: 7; Val: 31), (Bits: 0; Op: 8; Val: 113), (Bits: 0; Op: 8; Val: 49),
    (Bits: 0; Op: 9; Val: 194), (Bits: 16; Op: 7; Val: 10), (Bits: 0; Op: 8; Val: 97),
    (Bits: 0; Op: 8; Val: 33), (Bits: 0; Op: 9; Val: 162), (Bits: 0; Op: 8; Val: 1),
    (Bits: 0; Op: 8; Val: 129), (Bits: 0; Op: 8; Val: 65), (Bits: 0; Op: 9; Val: 226),
    (Bits: 16; Op: 7; Val: 6), (Bits: 0; Op: 8; Val: 89), (Bits: 0; Op: 8; Val: 25),
    (Bits: 0; Op: 9; Val: 146), (Bits: 19; Op: 7; Val: 59), (Bits: 0; Op: 8; Val: 121),
    (Bits: 0; Op: 8; Val: 57), (Bits: 0; Op: 9; Val: 210), (Bits: 17; Op: 7; Val: 17),
    (Bits: 0; Op: 8; Val: 105), (Bits: 0; Op: 8; Val: 41), (Bits: 0; Op: 9; Val: 178),
    (Bits: 0; Op: 8; Val: 9), (Bits: 0; Op: 8; Val: 137), (Bits: 0; Op: 8; Val: 73),
    (Bits: 0; Op: 9; Val: 242), (Bits: 16; Op: 7; Val: 4), (Bits: 0; Op: 8; Val: 85),
    (Bits: 0; Op: 8; Val: 21), (Bits: 16; Op: 8; Val: 258), (Bits: 19; Op: 7; Val: 43),
    (Bits: 0; Op: 8; Val: 117), (Bits: 0; Op: 8; Val: 53), (Bits: 0; Op: 9; Val: 202),
    (Bits: 17; Op: 7; Val: 13), (Bits: 0; Op: 8; Val: 101), (Bits: 0; Op: 8; Val: 37),
    (Bits: 0; Op: 9; Val: 170), (Bits: 0; Op: 8; Val: 5), (Bits: 0; Op: 8; Val: 133),
    (Bits: 0; Op: 8; Val: 69), (Bits: 0; Op: 9; Val: 234), (Bits: 16; Op: 7; Val: 8),
    (Bits: 0; Op: 8; Val: 93), (Bits: 0; Op: 8; Val: 29), (Bits: 0; Op: 9; Val: 154),
    (Bits: 20; Op: 7; Val: 83), (Bits: 0; Op: 8; Val: 125), (Bits: 0; Op: 8; Val: 61),
    (Bits: 0; Op: 9; Val: 218), (Bits: 18; Op: 7; Val: 23), (Bits: 0; Op: 8; Val: 109),
    (Bits: 0; Op: 8; Val: 45), (Bits: 0; Op: 9; Val: 186), (Bits: 0; Op: 8; Val: 13),
    (Bits: 0; Op: 8; Val: 141), (Bits: 0; Op: 8; Val: 77), (Bits: 0; Op: 9; Val: 250),
    (Bits: 16; Op: 7; Val: 3), (Bits: 0; Op: 8; Val: 83), (Bits: 0; Op: 8; Val: 19),
    (Bits: 21; Op: 8; Val: 195), (Bits: 19; Op: 7; Val: 35), (Bits: 0; Op: 8; Val: 115),
    (Bits: 0; Op: 8; Val: 51), (Bits: 0; Op: 9; Val: 198), (Bits: 17; Op: 7; Val: 11),
    (Bits: 0; Op: 8; Val: 99), (Bits: 0; Op: 8; Val: 35), (Bits: 0; Op: 9; Val: 166),
    (Bits: 0; Op: 8; Val: 3), (Bits: 0; Op: 8; Val: 131), (Bits: 0; Op: 8; Val: 67),
    (Bits: 0; Op: 9; Val: 230), (Bits: 16; Op: 7; Val: 7), (Bits: 0; Op: 8; Val: 91),
    (Bits: 0; Op: 8; Val: 27), (Bits: 0; Op: 9; Val: 150), (Bits: 20; Op: 7; Val: 67),
    (Bits: 0; Op: 8; Val: 123), (Bits: 0; Op: 8; Val: 59), (Bits: 0; Op: 9; Val: 214),
    (Bits: 18; Op: 7; Val: 19), (Bits: 0; Op: 8; Val: 107), (Bits: 0; Op: 8; Val: 43),
    (Bits: 0; Op: 9; Val: 182), (Bits: 0; Op: 8; Val: 11), (Bits: 0; Op: 8; Val: 139),
    (Bits: 0; Op: 8; Val: 75), (Bits: 0; Op: 9; Val: 246), (Bits: 16; Op: 7; Val: 5),
    (Bits: 0; Op: 8; Val: 87), (Bits: 0; Op: 8; Val: 23),(Bits: 64; Op: 8; Val: 0),
    (Bits: 19; Op: 7; Val: 51), (Bits: 0; Op: 8; Val: 119), (Bits: 0; Op: 8; Val: 55),
    (Bits: 0; Op: 9; Val: 206), (Bits: 17; Op: 7; Val: 15), (Bits: 0; Op: 8; Val: 103),
    (Bits: 0; Op: 8; Val: 39), (Bits: 0; Op: 9; Val: 174), (Bits: 0; Op: 8; Val: 7),
    (Bits: 0; Op: 8; Val: 135), (Bits: 0; Op: 8; Val: 71), (Bits: 0; Op: 9; Val: 238),
    (Bits: 16; Op: 7; Val: 9), (Bits: 0; Op: 8; Val: 95), (Bits: 0; Op: 8; Val: 31),
    (Bits: 0; Op: 9; Val: 158), (Bits: 20; Op: 7; Val: 99), (Bits: 0; Op: 8; Val: 127),
    (Bits: 0; Op: 8; Val: 63), (Bits: 0; Op: 9; Val: 222),(Bits: 18; Op: 7; Val: 27),
    (Bits: 0; Op: 8; Val: 111), (Bits: 0; Op: 8; Val: 47), (Bits: 0; Op: 9; Val: 190),
    (Bits: 0; Op: 8; Val: 15), (Bits: 0; Op: 8; Val: 143), (Bits: 0; Op: 8; Val: 79),
    (Bits: 0; Op: 9; Val: 254), (Bits: 96; Op: 7; Val: 0), (Bits: 0; Op: 8; Val: 80),
    (Bits: 0; Op: 8; Val: 16), (Bits: 20; Op: 8; Val: 115), (Bits: 18; Op: 7; Val: 31),
    (Bits: 0; Op: 8; Val: 112), (Bits: 0; Op: 8; Val: 48), (Bits: 0; Op: 9; Val: 193),
    (Bits: 16; Op: 7; Val: 10), (Bits: 0; Op: 8; Val: 96), (Bits: 0; Op: 8; Val: 32),
    (Bits: 0; Op: 9; Val: 161), (Bits: 0; Op: 8; Val: 0),(Bits: 0; Op: 8; Val: 128),
    (Bits: 0; Op: 8; Val: 64), (Bits: 0; Op: 9; Val: 225), (Bits: 16; Op: 7; Val: 6),
    (Bits: 0; Op: 8; Val: 88), (Bits: 0; Op: 8; Val: 24), (Bits: 0; Op: 9; Val: 145),
    (Bits: 19; Op: 7; Val: 59), (Bits: 0; Op: 8; Val: 120), (Bits: 0; Op: 8; Val: 56),
    (Bits: 0; Op: 9; Val: 209), (Bits: 17; Op: 7; Val: 17), (Bits: 0; Op: 8; Val: 104),
    (Bits: 0; Op: 8; Val: 40), (Bits: 0; Op: 9; Val: 177), (Bits: 0; Op: 8; Val: 8),
    (Bits: 0; Op: 8; Val: 136), (Bits: 0; Op: 8; Val: 72), (Bits: 0; Op: 9; Val: 241),
    (Bits: 16; Op: 7; Val: 4), (Bits: 0; Op: 8; Val: 84),(Bits: 0; Op: 8; Val: 20),
    (Bits: 21; Op: 8; Val: 227), (Bits: 19; Op: 7; Val: 43), (Bits: 0; Op: 8; Val: 116),
    (Bits: 0; Op: 8; Val: 52), (Bits: 0; Op: 9; Val: 201), (Bits: 17; Op: 7; Val: 13),
    (Bits: 0; Op: 8; Val: 100), (Bits: 0; Op: 8; Val: 36), (Bits: 0; Op: 9; Val: 169),
    (Bits: 0; Op: 8; Val: 4), (Bits: 0; Op: 8; Val: 132), (Bits: 0; Op: 8; Val: 68),
    (Bits: 0; Op: 9; Val: 233), (Bits: 16; Op: 7; Val: 8), (Bits: 0; Op: 8; Val: 92),
    (Bits: 0; Op: 8; Val: 28), (Bits: 0; Op: 9; Val: 153), (Bits: 20; Op: 7; Val: 83),
    (Bits: 0; Op: 8; Val: 124), (Bits: 0; Op: 8; Val: 60),(Bits: 0; Op: 9; Val: 217),
    (Bits: 18; Op: 7; Val: 23), (Bits: 0; Op: 8; Val: 108), (Bits: 0; Op: 8; Val: 44),
    (Bits: 0; Op: 9; Val: 185), (Bits: 0; Op: 8; Val: 12), (Bits: 0; Op: 8; Val: 140),
    (Bits: 0; Op: 8; Val: 76), (Bits: 0; Op: 9; Val: 249), (Bits: 16; Op: 7; Val: 3),
    (Bits: 0; Op: 8; Val: 82), (Bits: 0; Op: 8; Val: 18), (Bits: 21; Op: 8; Val: 163),
    (Bits: 19; Op: 7; Val: 35), (Bits: 0; Op: 8; Val: 114), (Bits: 0; Op: 8; Val: 50),
    (Bits: 0; Op: 9; Val: 197), (Bits: 17; Op: 7; Val: 11), (Bits: 0; Op: 8; Val: 98),
    (Bits: 0; Op: 8; Val: 34), (Bits: 0; Op: 9; Val: 165),(Bits: 0; Op: 8; Val: 2),
    (Bits: 0; Op: 8; Val: 130), (Bits: 0; Op: 8; Val: 66), (Bits: 0; Op: 9; Val: 229),
    (Bits: 16; Op: 7; Val: 7), (Bits: 0; Op: 8; Val: 90), (Bits: 0; Op: 8; Val: 26),
    (Bits: 0; Op: 9; Val: 149), (Bits: 20; Op: 7; Val: 67), (Bits: 0; Op: 8; Val: 122),
    (Bits: 0; Op: 8; Val: 58), (Bits: 0; Op: 9; Val: 213), (Bits: 18; Op: 7; Val: 19),
    (Bits: 0; Op: 8; Val: 106), (Bits: 0; Op: 8; Val: 42), (Bits: 0; Op: 9; Val: 181),
    (Bits: 0; Op: 8; Val: 10), (Bits: 0; Op: 8; Val: 138), (Bits: 0; Op: 8; Val: 74),
    (Bits: 0; Op: 9; Val: 245), (Bits: 16; Op: 7; Val: 5),(Bits: 0; Op: 8; Val: 86),
    (Bits: 0; Op: 8; Val: 22), (Bits: 64; Op: 8; Val: 0), (Bits: 19; Op: 7; Val: 51),
    (Bits: 0; Op: 8; Val: 118), (Bits: 0; Op: 8; Val: 54), (Bits: 0; Op: 9; Val: 205),
    (Bits: 17; Op: 7; Val: 15), (Bits: 0; Op: 8; Val: 102), (Bits: 0; Op: 8; Val: 38),
    (Bits: 0; Op: 9; Val: 173), (Bits: 0; Op: 8; Val: 6), (Bits: 0; Op: 8; Val: 134),
    (Bits: 0; Op: 8; Val: 70), (Bits: 0; Op: 9; Val: 237), (Bits: 16; Op: 7; Val: 9),
    (Bits: 0; Op: 8; Val: 94), (Bits: 0; Op: 8; Val: 30), (Bits: 0; Op: 9; Val: 157),
    (Bits: 20; Op: 7; Val: 99), (Bits: 0; Op: 8; Val: 126),(Bits: 0; Op: 8; Val: 62),
    (Bits: 0; Op: 9; Val: 221), (Bits: 18; Op: 7; Val: 27), (Bits: 0; Op: 8; Val: 110),
    (Bits: 0; Op: 8; Val: 46), (Bits: 0; Op: 9; Val: 189), (Bits: 0; Op: 8; Val: 14),
    (Bits: 0; Op: 8; Val: 142), (Bits: 0; Op: 8; Val: 78), (Bits: 0; Op: 9; Val: 253),
    (Bits: 96; Op: 7; Val: 0), (Bits: 0; Op: 8; Val: 81), (Bits: 0; Op: 8; Val: 17),
    (Bits: 21; Op: 8; Val: 131), (Bits: 18; Op: 7; Val: 31), (Bits: 0; Op: 8; Val: 113),
    (Bits: 0; Op: 8; Val: 49), (Bits: 0; Op: 9; Val: 195),
    (Bits: 16; Op: 7; Val: 10), (Bits: 0; Op: 8; Val: 97), (Bits: 0; Op: 8; Val: 33),
    (Bits: 0; Op: 9; Val: 163), (Bits: 0; Op: 8; Val: 1), (Bits: 0; Op: 8; Val: 129),
    (Bits: 0; Op: 8; Val: 65), (Bits: 0; Op: 9; Val: 227), (Bits: 16; Op: 7; Val: 6),
    (Bits: 0; Op: 8; Val: 89), (Bits: 0; Op: 8; Val: 25), (Bits: 0; Op: 9; Val: 147),
    (Bits: 19; Op: 7; Val: 59), (Bits: 0; Op: 8; Val: 121), (Bits: 0; Op: 8; Val: 57),
    (Bits: 0; Op: 9; Val: 211), (Bits: 17; Op: 7; Val: 17),(Bits: 0; Op: 8; Val: 105),
    (Bits: 0; Op: 8; Val: 41), (Bits: 0; Op: 9; Val: 179), (Bits: 0; Op: 8; Val: 9),
    (Bits: 0; Op: 8; Val: 137), (Bits: 0; Op: 8; Val: 73), (Bits: 0; Op: 9; Val: 243),
    (Bits: 16; Op: 7; Val: 4), (Bits: 0; Op: 8; Val: 85), (Bits: 0; Op: 8; Val: 21),
    (Bits: 16; Op: 8; Val: 258), (Bits: 19; Op: 7; Val: 43), (Bits: 0; Op: 8; Val: 117),
    (Bits: 0; Op: 8; Val: 53), (Bits: 0; Op: 9; Val: 203), (Bits: 17; Op: 7; Val: 13),
    (Bits: 0; Op: 8; Val: 101), (Bits: 0; Op: 8; Val: 37), (Bits: 0; Op: 9; Val: 171),
    (Bits: 0; Op: 8; Val: 5), (Bits: 0; Op: 8; Val: 133),(Bits: 0; Op: 8; Val: 69),
    (Bits: 0; Op: 9; Val: 235), (Bits: 16; Op: 7; Val: 8), (Bits: 0; Op: 8; Val: 93),
    (Bits: 0; Op: 8; Val: 29), (Bits: 0; Op: 9; Val: 155), (Bits: 20; Op: 7; Val: 83),
    (Bits: 0; Op: 8; Val: 125), (Bits: 0; Op: 8; Val: 61), (Bits: 0; Op: 9; Val: 219),
    (Bits: 18; Op: 7; Val: 23), (Bits: 0; Op: 8; Val: 109), (Bits: 0; Op: 8; Val: 45),
    (Bits: 0; Op: 9; Val: 187), (Bits: 0; Op: 8; Val: 13), (Bits: 0; Op: 8; Val: 141),
    (Bits: 0; Op: 8; Val: 77), (Bits: 0; Op: 9; Val: 251), (Bits: 16; Op: 7; Val: 3),
    (Bits: 0; Op: 8; Val: 83), (Bits: 0; Op: 8; Val: 19),(Bits: 21; Op: 8; Val: 195),
    (Bits: 19; Op: 7; Val: 35), (Bits: 0; Op: 8; Val: 115), (Bits: 0; Op: 8; Val: 51),
    (Bits: 0; Op: 9; Val: 199), (Bits: 17; Op: 7; Val: 11), (Bits: 0; Op: 8; Val: 99),
    (Bits: 0; Op: 8; Val: 35), (Bits: 0; Op: 9; Val: 167), (Bits: 0; Op: 8; Val: 3),
    (Bits: 0; Op: 8; Val: 131), (Bits: 0; Op: 8; Val: 67), (Bits: 0; Op: 9; Val: 231),
    (Bits: 16; Op: 7; Val: 7), (Bits: 0; Op: 8; Val: 91), (Bits: 0; Op: 8; Val: 27),
    (Bits: 0; Op: 9; Val: 151), (Bits: 20; Op: 7; Val: 67), (Bits: 0; Op: 8; Val: 123),
    (Bits: 0; Op: 8; Val: 59), (Bits: 0; Op: 9; Val: 215),(Bits: 18; Op: 7; Val: 19),
    (Bits: 0; Op: 8; Val: 107), (Bits: 0; Op: 8; Val: 43), (Bits: 0; Op: 9; Val: 183),
    (Bits: 0; Op: 8; Val: 11), (Bits: 0; Op: 8; Val: 139), (Bits: 0; Op: 8; Val: 75),
    (Bits: 0; Op: 9; Val: 247), (Bits: 16; Op: 7; Val: 5), (Bits: 0; Op: 8; Val: 87),
    (Bits: 0; Op: 8; Val: 23), (Bits: 64; Op: 8; Val: 0), (Bits: 19; Op: 7; Val: 51),
    (Bits: 0; Op: 8; Val: 119), (Bits: 0; Op: 8; Val: 55), (Bits: 0; Op: 9; Val: 207),
    (Bits: 17; Op: 7; Val: 15), (Bits: 0; Op: 8; Val: 103), (Bits: 0; Op: 8; Val: 39),
    (Bits: 0; Op: 9; Val: 175), (Bits: 0; Op: 8; Val: 7),(Bits: 0; Op: 8; Val: 135),
    (Bits: 0; Op: 8; Val: 71), (Bits: 0; Op: 9; Val: 239), (Bits: 16; Op: 7; Val: 9),
    (Bits: 0; Op: 8; Val: 95), (Bits: 0; Op: 8; Val: 31), (Bits: 0; Op: 9; Val: 159),
    (Bits: 20; Op: 7; Val: 99), (Bits: 0; Op: 8; Val: 127), (Bits: 0; Op: 8; Val: 63),
    (Bits: 0; Op: 9; Val: 223), (Bits: 18; Op: 7; Val: 27), (Bits: 0; Op: 8; Val: 111),
    (Bits: 0; Op: 8; Val: 47), (Bits: 0; Op: 9; Val: 191), (Bits: 0; Op: 8; Val: 15),
    (Bits: 0; Op: 8; Val: 143), (Bits: 0; Op: 8; Val: 79), (Bits: 0; Op: 9; Val: 255)
  );

  DistFix: array[0..31] of TCodeTag = (
    (16,5,1),(23,5,257),(19,5,17),(27,5,4097),(17,5,5),(25,5,1025),
    (21,5,65),(29,5,16385),(16,5,3),(24,5,513),(20,5,33),(28,5,8193),
    (18,5,9),(26,5,2049),(22,5,129),(64,5,0),(16,5,2),(23,5,385),
    (19,5,25),(27,5,6145),(17,5,7),(25,5,1537),(21,5,97),(29,5,24577),
    (16,5,4),(24,5,769),(20,5,49),(28,5,12289),(18,5,13),(26,5,3073),
    (22,5,193),(64,5,0)
  );


type
  TZLibStatus = (
    zsSuccess,
    zsHeaderError,
    zsDecodeError,
    zsOutputInsufficient,
    zsInputInsufficient,
    zsInvalidParameter
  );

  TZlibCodeType = (
    zcCodes,
    zcLens,
    zcDists
  );

  TZlibState = record
    LastError: byte;
    LastBlock: boolean;
    LenBits: byte;
    DistBits: byte;
    NCode: word;
    NLen: word;
    NDist: word;
    CodeLengths: word;
    Lengths: array[0..319] of byte;
    Work: array[0..287] of word;
    Codes: array[0..Enough] of TCodeTag;
  end;


implementation

var
  PreviousExitProc: PProc;

procedure Finalize;
begin
  ExitProc := PreviousExitProc;
end;

begin
  PreviousExitProc := ExitProc;
  ExitProc := @Finalize;
end.
