module encrypter(
    input [127:0]data_in,
    input [127:0]key_in,
    input start,
    input encrypt,
    output reg [127:0]data_out
);
// Control Registers
    reg start_AES;
    reg reset_AES;

// key = [113, 113, 113, 113, 119, 119, 119, 119, 101, 101, 101, 101, 114, 114, 116, 121]
// arr = [68, 105, 115, 99, 111, 109, 98, 111, 98, 117, 108, 97, 116, 101, 109, 101]
    reg [7:0] arr [15:0]; // The array with the data
    reg [7:0] key [15:0]; // The array with the key
    integer d = 0;
    integer e = 0;
    reg [7:0] sbox [255:0];
    reg [7:0] isbox [255:0];
    
    // ---------- Utility Function Declarations ---------//
        function key_input;
        input [127:0]data_string;
        integer i,j,k;
        begin
            k = 0;
            for (i=15; i > -1; i = i - 1) begin
                for (j=0; j < 8; j = j + 1) begin
                    key[i][j] = data_string[k];
                    k = k + 1;
                end
            end
        end
    endfunction
    
    function data_input;
        input [127:0]data_string;
        integer i,j,k;
        begin
            k = 0;
            for (i=15; i > -1; i = i - 1) begin
                for (j=0; j < 8; j = j + 1) begin
                    arr[i][j] = data_string[k];
                    k = k + 1;
                end
            end
        end
    endfunction
    
    function [127:0]data_output;
        input invalid;
        integer i,j,k;
        begin
            k = 0;
            for (i=15; i > -1; i = i - 1) begin
                for (j=0; j < 8; j = j + 1) begin
                    data_output[k] = arr[i][j];
                    k = k + 1;
                end
            end
        end
    endfunction
    
    // ----------          ----- FUNCTION DECLARATIONS -----         ----------//
    
    function subBytes;
        input inv;
        integer i;
        begin
            if (inv == 0) begin
                for (i=0; i < 16; i = i + 1) begin
                    arr[i] = sbox[arr[i]]; 
                end
            end
            else begin
                for (i=0; i < 16; i = i + 1) begin
                    arr[i] = isbox[arr[i]]; 
                end
            end
        end
    endfunction

    function addKey;
        input inv;
        integer i;
        begin
            i = 0;
            while (i < 128) begin
                arr[i] = arr[i] ^ key[i];
                i = i + 1;
            end
        end
    endfunction

    function shiftRows;
        input inv;
        integer f,j,t;
        integer c;
        begin
            c = 1;
            for (f = 0; f < 4; f = f + 1)
                begin
                    if (inv == 0) begin
                        while (c < f) begin
                            t = arr[f*4];
                            arr[(f*4) + 0] = arr[(f*4) + 1]; arr[(f*4) + 1] = arr[(f*4) + 2]; arr[(f*4) + 2] = arr[(f*4) + 3]; arr[(f*4) + 3] = t;
                            c = c + 1;
                        end
                        c = 0;
                    end else begin
                        for (j = 0;j < 3 ;j = j + 1 ) begin
                            while (c < f) begin
                            t = arr[f*4];
                            arr[(f*4) + 0] = arr[(f*4) + 1]; arr[(f*4) + 1] = arr[(f*4) + 2]; arr[(f*4) + 2] = arr[(f*4) + 3]; arr[(f*4) + 3] = t;
                            c = c + 1;
                        end
                        c = 0;
                        end
                    end
                end
        end
    endfunction
    
    function [7:0]galois;
        input[31:0] a;
        input[7:0] b;
        reg[31:0] p;
        reg[7:0] highBit;
        begin
            p = 0;
            highBit = 0;
            repeat (8) begin
                if ((b & 1) == 1) begin
                    p = p ^ a;
                end
                highBit = a & 8'h80;
                a = a << 1;
                if (highBit == 8'h80) begin
                    a = a ^ 8'h1b;
                end
                b = b >> 1;
            end
            galois = p % 256;
        end
    endfunction

    function mixColumns;
        input inv;
        reg [7:0] temp [3:0];
        integer count;
        reg [3:0] a,b,c,d;
        begin
            if (inv == 0) begin
                for (count = 0; count < 4; count = count + 1) begin
                    a = count + 0; b = count + 4; c = count + 8; d = count + 12;
                    temp[0] = arr[a]; temp[1] = arr[b]; temp[2] = arr[c]; temp[3] = arr[d];
                    arr[a] = galois(temp[0], 2) ^ galois(temp[3], 1) ^ galois(temp[2], 1) ^ galois(temp[1], 3);
                    arr[b] = galois(temp[1], 2) ^ galois(temp[0], 1) ^ galois(temp[3], 1) ^ galois(temp[2], 3);
                    arr[c] = galois(temp[2], 2) ^ galois(temp[1], 1) ^ galois(temp[0], 1) ^ galois(temp[3], 3);
                    arr[d] = galois(temp[3], 2) ^ galois(temp[2], 1) ^ galois(temp[1], 1) ^ galois(temp[0], 3);
                end
            end else begin
                for (count = 0; count < 4; count = count + 1) begin
                    a = count + 0; b = count + 4; c = count + 8; d = count + 12;
                    temp[0] = arr[a]; temp[1] = arr[b]; temp[2] = arr[c]; temp[3] = arr[d];
                    arr[a] = galois(temp[0], 14) ^ galois(temp[3], 9) ^ galois(temp[2], 13) ^ galois(temp[1], 11);
                    arr[b] = galois(temp[1], 14) ^ galois(temp[0], 9) ^ galois(temp[3], 13) ^ galois(temp[2], 11);
                    arr[c] = galois(temp[2], 14) ^ galois(temp[1], 9) ^ galois(temp[0], 13) ^ galois(temp[3], 11);
                    arr[d] = galois(temp[3], 14) ^ galois(temp[2], 9) ^ galois(temp[1], 13) ^ galois(temp[0], 11);
            end
            end
        end
    endfunction

    function round;
        input inv;
        integer dump, i;
        begin
            if (inv == 1) begin
                dump = addKey(inv);
                dump = mixColumns(inv);
                dump = shiftRows(inv);
                dump = subBytes(inv);
            end
            else begin
                dump = subBytes(inv);
                dump = shiftRows(inv);
                dump = mixColumns(inv);
                dump = addKey(inv);
            end
        end 
    endfunction

    function crypt; // 1 will decrypt, 0 will encrypt
        input inv;
        integer r,i,dump;
        begin
            if (inv == 1) begin
                dump = addKey(inv);
                dump = shiftRows(inv);
                dump = subBytes(inv);
                for (r = 0; r < 9; r = r+1) begin
                    dump = round(inv);
                end
                dump = addKey(inv);
            end
            else begin
                dump = addKey(inv);
                for (r = 0; r < 9; r = r+1) begin
                    dump = round(inv);
                end
                dump = subBytes(inv);
                dump = shiftRows(inv);
                dump = addKey(inv);
            end
        end
        
    endfunction
    
    initial begin
        data_out = 0;
        reset_AES = 0;
        #10
        reset_AES = 1;
        #10
        reset_AES = 0;
    end
    
    always @(posedge start) begin
        e = data_input(data_in);
        e = key_input(key_in);
        start_AES = 1;
    end

    always @(posedge reset_AES) begin
        sbox[  0] =  99; sbox[  1] = 124; sbox[  2] = 119; sbox[  3] = 123; sbox[  4] = 242; sbox[  5] = 107; sbox[  6] = 111; sbox[  7] = 197; 
        sbox[  8] =  48; sbox[  9] =   1; sbox[ 10] = 103; sbox[ 11] =  43; sbox[ 12] = 254; sbox[ 13] = 215; sbox[ 14] = 171; sbox[ 15] = 118; 
        sbox[ 16] = 202; sbox[ 17] = 130; sbox[ 18] = 201; sbox[ 19] = 125; sbox[ 20] = 250; sbox[ 21] =  89; sbox[ 22] =  71; sbox[ 23] = 240; 
        sbox[ 24] = 173; sbox[ 25] = 212; sbox[ 26] = 162; sbox[ 27] = 175; sbox[ 28] = 156; sbox[ 29] = 164; sbox[ 30] = 114; sbox[ 31] = 192; 
        sbox[ 32] = 183; sbox[ 33] = 253; sbox[ 34] = 147; sbox[ 35] =  38; sbox[ 36] =  54; sbox[ 37] =  63; sbox[ 38] = 247; sbox[ 39] = 204; 
        sbox[ 40] =  52; sbox[ 41] = 165; sbox[ 42] = 229; sbox[ 43] = 241; sbox[ 44] = 113; sbox[ 45] = 216; sbox[ 46] =  49; sbox[ 47] =  21; 
        sbox[ 48] =   4; sbox[ 49] = 199; sbox[ 50] =  35; sbox[ 51] = 195; sbox[ 52] =  24; sbox[ 53] = 150; sbox[ 54] =   5; sbox[ 55] = 154; 
        sbox[ 56] =   7; sbox[ 57] =  18; sbox[ 58] = 128; sbox[ 59] = 226; sbox[ 60] = 235; sbox[ 61] =  39; sbox[ 62] = 178; sbox[ 63] = 117; 
        sbox[ 64] =   9; sbox[ 65] = 131; sbox[ 66] =  44; sbox[ 67] =  26; sbox[ 68] =  27; sbox[ 69] = 110; sbox[ 70] =  90; sbox[ 71] = 160; 
        sbox[ 72] =  82; sbox[ 73] =  59; sbox[ 74] = 214; sbox[ 75] = 179; sbox[ 76] =  41; sbox[ 77] = 227; sbox[ 78] =  47; sbox[ 79] = 132; 
        sbox[ 80] =  83; sbox[ 81] = 209; sbox[ 82] =   0; sbox[ 83] = 237; sbox[ 84] =  32; sbox[ 85] = 252; sbox[ 86] = 177; sbox[ 87] =  91; 
        sbox[ 88] = 106; sbox[ 89] = 203; sbox[ 90] = 190; sbox[ 91] =  57; sbox[ 92] =  74; sbox[ 93] =  76; sbox[ 94] =  88; sbox[ 95] = 207; 
        sbox[ 96] = 208; sbox[ 97] = 239; sbox[ 98] = 170; sbox[ 99] = 251; sbox[100] =  67; sbox[101] =  77; sbox[102] =  51; sbox[103] = 133; 
        sbox[104] =  69; sbox[105] = 249; sbox[106] =   2; sbox[107] = 127; sbox[108] =  80; sbox[109] =  60; sbox[110] = 159; sbox[111] = 168; 
        sbox[112] =  81; sbox[113] = 163; sbox[114] =  64; sbox[115] = 143; sbox[116] = 146; sbox[117] = 157; sbox[118] =  56; sbox[119] = 245; 
        sbox[120] = 188; sbox[121] = 182; sbox[122] = 218; sbox[123] =  33; sbox[124] =  16; sbox[125] = 255; sbox[126] = 243; sbox[127] = 210; 
        sbox[128] = 205; sbox[129] =  12; sbox[130] =  19; sbox[131] = 236; sbox[132] =  95; sbox[133] = 151; sbox[134] =  68; sbox[135] =  23; 
        sbox[136] = 196; sbox[137] = 167; sbox[138] = 126; sbox[139] =  61; sbox[140] = 100; sbox[141] =  93; sbox[142] =  25; sbox[143] = 115; 
        sbox[144] =  96; sbox[145] = 129; sbox[146] =  79; sbox[147] = 220; sbox[148] =  34; sbox[149] =  42; sbox[150] = 144; sbox[151] = 136; 
        sbox[152] =  70; sbox[153] = 238; sbox[154] = 184; sbox[155] =  20; sbox[156] = 222; sbox[157] =  94; sbox[158] =  11; sbox[159] = 219; 
        sbox[160] = 224; sbox[161] =  50; sbox[162] =  58; sbox[163] =  10; sbox[164] =  73; sbox[165] =   6; sbox[166] =  36; sbox[167] =  92; 
        sbox[168] = 194; sbox[169] = 211; sbox[170] = 172; sbox[171] =  98; sbox[172] = 145; sbox[173] = 149; sbox[174] = 228; sbox[175] = 121; 
        sbox[176] = 231; sbox[177] = 200; sbox[178] =  55; sbox[179] = 109; sbox[180] = 141; sbox[181] = 213; sbox[182] =  78; sbox[183] = 169; 
        sbox[184] = 108; sbox[185] =  86; sbox[186] = 244; sbox[187] = 234; sbox[188] = 101; sbox[189] = 122; sbox[190] = 174; sbox[191] =   8; 
        sbox[192] = 186; sbox[193] = 120; sbox[194] =  37; sbox[195] =  46; sbox[196] =  28; sbox[197] = 166; sbox[198] = 180; sbox[199] = 198; 
        sbox[200] = 232; sbox[201] = 221; sbox[202] = 116; sbox[203] =  31; sbox[204] =  75; sbox[205] = 189; sbox[206] = 139; sbox[207] = 138; 
        sbox[208] = 112; sbox[209] =  62; sbox[210] = 181; sbox[211] = 102; sbox[212] =  72; sbox[213] =   3; sbox[214] = 246; sbox[215] =  14; 
        sbox[216] =  97; sbox[217] =  53; sbox[218] =  87; sbox[219] = 185; sbox[220] = 134; sbox[221] = 193; sbox[222] =  29; sbox[223] = 158; 
        sbox[224] = 225; sbox[225] = 248; sbox[226] = 152; sbox[227] =  17; sbox[228] = 105; sbox[229] = 217; sbox[230] = 142; sbox[231] = 148; 
        sbox[232] = 155; sbox[233] =  30; sbox[234] = 135; sbox[235] = 233; sbox[236] = 206; sbox[237] =  85; sbox[238] =  40; sbox[239] = 223; 
        sbox[240] = 140; sbox[241] = 161; sbox[242] = 137; sbox[243] =  13; sbox[244] = 191; sbox[245] = 230; sbox[246] =  66; sbox[247] = 104; 
        sbox[248] =  65; sbox[249] = 153; sbox[250] =  45; sbox[251] =  15; sbox[252] = 176; sbox[253] =  84; sbox[254] = 187; sbox[255] =  22; 
        
        isbox[  0] =  82; isbox[  1] =   9; isbox[  2] = 106; isbox[  3] = 213; isbox[  4] =  48; isbox[  5] =  54; isbox[  6] = 165; isbox[  7] =  56; 
        isbox[  8] = 191; isbox[  9] =  64; isbox[ 10] = 163; isbox[ 11] = 158; isbox[ 12] = 129; isbox[ 13] = 243; isbox[ 14] = 215; isbox[ 15] = 251; 
        isbox[ 16] = 124; isbox[ 17] = 227; isbox[ 18] =  57; isbox[ 19] = 130; isbox[ 20] = 155; isbox[ 21] =  47; isbox[ 22] = 255; isbox[ 23] = 135; 
        isbox[ 24] =  52; isbox[ 25] = 142; isbox[ 26] =  67; isbox[ 27] =  68; isbox[ 28] = 196; isbox[ 29] = 222; isbox[ 30] = 233; isbox[ 31] = 203; 
        isbox[ 32] =  84; isbox[ 33] = 123; isbox[ 34] = 148; isbox[ 35] =  50; isbox[ 36] = 166; isbox[ 37] = 194; isbox[ 38] =  35; isbox[ 39] =  61; 
        isbox[ 40] = 238; isbox[ 41] =  76; isbox[ 42] = 149; isbox[ 43] =  11; isbox[ 44] =  66; isbox[ 45] = 250; isbox[ 46] = 195; isbox[ 47] =  78; 
        isbox[ 48] =   8; isbox[ 49] =  46; isbox[ 50] = 161; isbox[ 51] = 102; isbox[ 52] =  40; isbox[ 53] = 217; isbox[ 54] =  36; isbox[ 55] = 178; 
        isbox[ 56] = 118; isbox[ 57] =  91; isbox[ 58] = 162; isbox[ 59] =  73; isbox[ 60] = 109; isbox[ 61] = 139; isbox[ 62] = 209; isbox[ 63] =  37; 
        isbox[ 64] = 114; isbox[ 65] = 248; isbox[ 66] = 246; isbox[ 67] = 100; isbox[ 68] = 134; isbox[ 69] = 104; isbox[ 70] = 152; isbox[ 71] =  22; 
        isbox[ 72] = 212; isbox[ 73] = 164; isbox[ 74] =  92; isbox[ 75] = 204; isbox[ 76] =  93; isbox[ 77] = 101; isbox[ 78] = 182; isbox[ 79] = 146; 
        isbox[ 80] = 108; isbox[ 81] = 112; isbox[ 82] =  72; isbox[ 83] =  80; isbox[ 84] = 253; isbox[ 85] = 237; isbox[ 86] = 185; isbox[ 87] = 218; 
        isbox[ 88] =  94; isbox[ 89] =  21; isbox[ 90] =  70; isbox[ 91] =  87; isbox[ 92] = 167; isbox[ 93] = 141; isbox[ 94] = 157; isbox[ 95] = 132; 
        isbox[ 96] = 144; isbox[ 97] = 216; isbox[ 98] = 171; isbox[ 99] =   0; isbox[100] = 140; isbox[101] = 188; isbox[102] = 211; isbox[103] =  10; 
        isbox[104] = 247; isbox[105] = 228; isbox[106] =  88; isbox[107] =   5; isbox[108] = 184; isbox[109] = 179; isbox[110] =  69; isbox[111] =   6; 
        isbox[112] = 208; isbox[113] =  44; isbox[114] =  30; isbox[115] = 143; isbox[116] = 202; isbox[117] =  63; isbox[118] =  15; isbox[119] =   2; 
        isbox[120] = 193; isbox[121] = 175; isbox[122] = 189; isbox[123] =   3; isbox[124] =   1; isbox[125] =  19; isbox[126] = 138; isbox[127] = 107; 
        isbox[128] =  58; isbox[129] = 145; isbox[130] =  17; isbox[131] =  65; isbox[132] =  79; isbox[133] = 103; isbox[134] = 220; isbox[135] = 234; 
        isbox[136] = 151; isbox[137] = 242; isbox[138] = 207; isbox[139] = 206; isbox[140] = 240; isbox[141] = 180; isbox[142] = 230; isbox[143] = 115; 
        isbox[144] = 150; isbox[145] = 172; isbox[146] = 116; isbox[147] =  34; isbox[148] = 231; isbox[149] = 173; isbox[150] =  53; isbox[151] = 133; 
        isbox[152] = 226; isbox[153] = 249; isbox[154] =  55; isbox[155] = 232; isbox[156] =  28; isbox[157] = 117; isbox[158] = 223; isbox[159] = 110; 
        isbox[160] =  71; isbox[161] = 241; isbox[162] =  26; isbox[163] = 113; isbox[164] =  29; isbox[165] =  41; isbox[166] = 197; isbox[167] = 137; 
        isbox[168] = 111; isbox[169] = 183; isbox[170] =  98; isbox[171] =  14; isbox[172] = 170; isbox[173] =  24; isbox[174] = 190; isbox[175] =  27; 
        isbox[176] = 252; isbox[177] =  86; isbox[178] =  62; isbox[179] =  75; isbox[180] = 198; isbox[181] = 210; isbox[182] = 121; isbox[183] =  32; 
        isbox[184] = 154; isbox[185] = 219; isbox[186] = 192; isbox[187] = 254; isbox[188] = 120; isbox[189] = 205; isbox[190] =  90; isbox[191] = 244; 
        isbox[192] =  31; isbox[193] = 221; isbox[194] = 168; isbox[195] =  51; isbox[196] = 136; isbox[197] =   7; isbox[198] = 199; isbox[199] =  49; 
        isbox[200] = 177; isbox[201] =  18; isbox[202] =  16; isbox[203] =  89; isbox[204] =  39; isbox[205] = 128; isbox[206] = 236; isbox[207] =  95; 
        isbox[208] =  96; isbox[209] =  81; isbox[210] = 127; isbox[211] = 169; isbox[212] =  25; isbox[213] = 181; isbox[214] =  74; isbox[215] =  13; 
        isbox[216] =  45; isbox[217] = 229; isbox[218] = 122; isbox[219] = 159; isbox[220] = 147; isbox[221] = 201; isbox[222] = 156; isbox[223] = 239; 
        isbox[224] = 160; isbox[225] = 224; isbox[226] =  59; isbox[227] =  77; isbox[228] = 174; isbox[229] =  42; isbox[230] = 245; isbox[231] = 176; 
        isbox[232] = 200; isbox[233] = 235; isbox[234] = 187; isbox[235] =  60; isbox[236] = 131; isbox[237] =  83; isbox[238] = 153; isbox[239] =  97; 
        isbox[240] =  23; isbox[241] =  43; isbox[242] =   4; isbox[243] = 126; isbox[244] = 186; isbox[245] = 119; isbox[246] = 214; isbox[247] =  38; 
        isbox[248] = 225; isbox[249] = 105; isbox[250] =  20; isbox[251] =  99; isbox[252] =  85; isbox[253] =  33; isbox[254] =  12; isbox[255] = 125;
        reset_AES = 0;
    end

    integer i;
    always @(posedge start_AES) begin
        $display("START OF ENCRYPTER LOOP");   
        $display("-- KEY --");
        for (i = 0; i < 16; i = i + 1)
        begin
            $write("%c",key[i]);
        end
        $write("\n");
        
        $display("-- Password array Before --");
        for (i = 0; i < 16; i = i + 1)
        begin
            $write("%c",arr[i]);
        end
        $write("\n");
        
        if (encrypt) begin
            d = crypt(1);
        end 
        else begin
            d = crypt(0);
        end
        
        data_out = data_output(0);
        
        start_AES = 0;
        reset_AES = 1;
    end
    // ----------          ----- ----    -----    ---- -----         ----------//
endmodule
