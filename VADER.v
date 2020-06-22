`timescale 1ns / 1ps

// defines for system parameters
`define dictionarySize 3
`define dictionaryStart 1
`define bruteAttempts 10

module VADER(
    input clk, //100 MHz clock. 
    input reset, // Reset button
    input start, // Start button
    //input btnR, //Left button
    //input btnL, //Right button
    //output wire [7:0]seg, //Seg display, to be linked with state (active low)
    //output wire [7:0]segdriv, //Seg driv (active low)
    output reg [2:0]led, //RGB led (to be linked state in HW)
    output reg [2:0]state
    );
    // State (wait - 0/decrypt - 1/dictionary - 2/brute - 3/success - 4/failure - 5)
    // Monitor in test bench
    reg [7:0] arr [15:0]; // The array with the data
    reg [7:0] key [15:0]; // The array with the key
    reg invert = 1;
    reg [7:0] in;
    wire [7:0] out;
    // ----------          ----- FUNCTION DECLARATIONS -----         ----------//
    sbox mut(clk,invert, in, out);
    
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
    
    function subBytes;
        input inv;
        input incoming_byte;
        begin
            invert = inv;
            in = incoming_byte;
            subBytes = out;
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
                    if (inv == 1) begin
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
        input[7:0] a;
        input[7:0] b;
        reg[7:0] p;
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
                for (i=0; i < 16; i = i + 1) begin
                    dump = subBytes(inv, arr[i]);
                end
            end
            else begin
                for (i=0; i < 16; i = i + 1) begin
                    dump = subBytes(inv, arr[i]);
                end
                dump = shiftRows(inv);
                dump = mixColumns(inv);
                dump = addKey(inv);
            end
        end 
    endfunction

    function cyrpt; // 1 will decrypt, 0 will encrypt
        input inv;
        integer r,i,dump;
        begin
            if (inv == 1) begin
                dump = addKey(inv);
                dump = shiftRows(inv);
                for (i=0; i < 16; i = i + 1) begin
                    dump = subBytes(inv, arr[i]);
                end
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
                for (i=0; i < 16; i = i + 1) begin
                    dump = subBytes(inv, arr[i]);
                end
                dump = shiftRows(inv);
                dump = addKey(inv);
            end
        end
        
    endfunction


    // ----------          ----- ----    -----    ---- -----         ----------//
    //Internal variables
    wire resState;	// Resets our system to the beginning
    // Delayed_Res resetter(clk, reset, resState);
    wire startState; // Starts our system once resetted
    // Debounce Debounce(clk, start, startState);
    
    // Memory IO
    reg ena = 1; // Enable reading memory
    reg wea = 0; // Not current writing anything
    reg [7:0] addra=0;
    reg [127:0] dina=0; //We're not putting data in, so we can leave this unassigned
    //To-do: Alternate dina for BLOCK where we want to write data in
    wire [127:0] douta;
    
    //BRAM Blocks
    //1. SD Card simulation
    // SD_SIM sd(
    //     .clka(clk),    // input wire clka
    //     .ena(ena),      // input wire ena
    //     .wea(wea),      // input wire [0 : 0] wea
    //     .addra(addra),  // input wire [3 : 0] addra
    //     .dina(dina),    // input wire [255 : 0] dina
    //     .douta(douta)  // output wire [255 : 0] douta
    // );
    
    // Store hashed password
    reg [127:0] hPass;
    
    // Keep track of brute attempts
    reg [31:0] bruteCounter;
    
    initial begin
        // Set all flags to 0
        bruteCounter <= 0;
        addra <= 0;
        state = 0;
        // Turn off LED
        led = 3'b000;
        // input hashed password to be guessed. Example below
    end
    
    always @(posedge start) begin
        if (state == 0) begin // So we cant go back to decrypt state mid cracking attempt.
            // Ensure that can only start once reset to wait state
            hPass <= douta;
            addra = 2;
            state = 1;
        end
    end
    
	// Resetting the system back to the beginning to allow for a different password
	// to be guessed
    always @(posedge resState) begin
        bruteCounter <= 0;
        addra <= 0;
        state = 0;
        // Turn off LED
        led = 3'b000;
        // reinput same or another hashed password to be guessed
        hPass <= douta;
    end

    always @(posedge clk) begin
        if (state == 0) begin // Check for wait status
            led <= 3'b011; // Do wait stuff i.e Flash Yellow LED
        end
        
        if (state == 1) begin
            // EXAMPLE DECRYPTION DUE TO ENCRYPTION NOT FINISHED AT THIS TIME
            if (hPass == douta) begin
                state <= 4;
            end else begin
                addra = 1; // Set address to whatever the first dictionary input is
                state = 2; // Change state to dictionary attack
            end
        end 
        
        if (state == 2) begin
            // Start dictionary attack
            // if (hPass == encrypt(douta) begin
            //      success <= 1;
            //      dictionary <= 0;
            // end
            
            addra <= addra + 1;
            
            // End loop check
            // Give up on dictionary once all passwords have been attempted.
            if (addra - `dictionaryStart >= `dictionarySize) begin 
                addra = 0;
                state = 3; // Proceed to brute force attack
            end
        end
        
        if (state == 3) begin
            // Start brute force method
            // if (hPass == encrypt(bruteGen()) begin
            //      success <= 1;
            //      brute <= 0;
            // end
            
            bruteCounter <= bruteCounter + 1;
            
            // End Loop Check
            // Give up on brute force once a certain amount of tries have elapsed.
            if (bruteCounter >= `bruteAttempts) begin 
                state = 5;
            end
        end
        
        // Check for ending conditions
        if (state == 4) begin // Check for success state
            led <= 3'b010; // Do Success state stuff. i.e Flash Green LED
        end
        
        if (state == 5) begin // check for failure state
            led <= 3'b001; // Do Failure state stuff. i.e Flash Red LED
        end
    end
endmodule
