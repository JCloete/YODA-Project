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
    output reg [2:0]state //State (wait - 0/decrypt - 1/dictionary - 2/brute - 3/success - 4/failure - 5) <- monitor in test bench
    );
    
    //Internal variables
    wire resState;	// Resets our system to the beginning
    Delayed_Res resetter(clk, reset, resState);
    wire startState; // Starts our system once resetted
    Debounce Debounce(clk, start, startState);
    
    // Memory IO
    reg ena = 1; // Enable reading memory
    reg wea = 0; // Not current writing anything
    reg [7:0] addra=0;
    reg [127:0] dina=0; //We're not putting data in, so we can leave this unassigned
    //To-do: Alternate dina for BLOCK where we want to write data in
    wire [127:0] douta;
    
    //BRAM Blocks
    //1. SD Card simulation
    SD_SIM sd(
        .clka(clk),    // input wire clka
        .ena(ena),      // input wire ena
        .wea(wea),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [3 : 0] addra
        .dina(dina),    // input wire [255 : 0] dina
        .douta(douta)  // output wire [255 : 0] douta
    );
    
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
    
	// Resetting the system back to the beginning to allow for a different password to be guessed
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
            if (addra - `dictionaryStart >= `dictionarySize) begin // Give up on dictionary once all passwords have been attempted.
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
            if (bruteCounter >= `bruteAttempts) begin // Give up on brute force once a certain amount of tries have elapsed.
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
