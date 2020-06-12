`timescale 1ns / 1ps

// defines for system parameters
`define dictionarySize 10
`define dictionaryStart 1
`define bruteAttempts 100

module VADER(
    input clk, //100 MHz clock. 
    input reset, // Reset button
    input start, // Start button
    input btnR, //Left button
    input btnL, //Right button
    //output wire [7:0]seg, //Seg display, to be linked with state (active low)
    //output wire [7:0]segdriv, //Seg driv (active low)
    //output wire [2:0]led, //RGB led (to be linked state in HW)
    output reg [2:0]state //State (wait - 0/dictionary - 1/brute - 2/success - 3/failure - 4) <- monitor in test bench
    );
    
    //Internal variables
    wire resState;	// Resets our system to the beginning
    Delayed_Res resetter(clk, reset, resState);
    wire startState; // Starts our system once resetted
    Debounce(clk, start, startState);
    
    // Memory IO
    reg ena = 1; // Enable reading memory
    reg wea = 0; // Not current writing anything
    reg [7:0] addra=0;
    reg [10:0] dina=0; //We're not putting data in, so we can leave this unassigned
    //To-do: Alternate dina for BLOCK where we want to write data in
    wire [10:0] douta;
    
    //BRAM Blocks
    //1. SD Card simulation
    SD_Sim sd(
        .clka(clk),    // input wire clka
        .ena(ena),      // input wire ena
        .wea(wea),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [3 : 0] addra
        .dina(dina),    // input wire [255 : 0] dina
        .douta(douta)  // output wire [255 : 0] douta
    );
    
    // Flags to set
    reg dictionary; // Flag Used for transition to a dictionary attack state
    reg brute; //  Flag to transition to a brute force attack state
    
    // Store hashed password
    reg [127:0] hPass;
    
    // Keep track of brute attempts
    reg [31:0] bruteCounter;
    
    initial begin
        // Set all flags to 0
        dictionary <= 0;
        brute <= 0;
        bruteCounter <= 0;
        addra <= 0;
        state = 0;
        // input hashed password to be guessed
    end
    
    always @(posedge startState) begin
        if (state == 0) begin // So we cant go back to dictionary mid cracking attempt
            dictionary = 1; // Ensure that can only start once reset to wait state
        end
    end
    
	// Resetting the system back to the beginning to allow for a different password to be guessed
    always @(posedge resState) begin
        dictionary <= 0;
        brute <= 0;
        bruteCounter <= 0;
        addra <= 0;
        state = 0;
        // reinput same or another hashed password to be guessed
    end
    
    // Proceed to dictionary attack
    always @(posedge dictionary) begin
        addra = 1; // Set address to whatever the first dictionary input is
        state = 1; // Change state to dictionary attack
    end
    
    // Proceed to brute force attack
    always @(posedge brute) begin
        addra = 0;
        state = 2;
    end
    
    // Check for ending conditions
    always @(state) begin
        if (state == 3) begin
            // Do Success state stuff. i.e Flash Green LED
        end
        else if (state == 4) begin
            // Do Failure state stuff. i.e Flash Red LED
        end
    end
    
    always @(posedge clk) begin
        if (state == 1) begin
            // Start dictionary attack
            // if (hPass == encrypt(douta) begin
            //      success <= 1;
            //      dictionary <= 0;
            // end
            
            addra <= addra + 1;
        end
        if (state == 2) begin
            // Start brute force method
            // if (hPass == encrypt(bruteGen()) begin
            //      success <= 1;
            //      brute <= 0;
            // end
            
            bruteCounter <= bruteCounter + 1;
        end
    end
    
    // Stop after a number of attempts have been made
    always @(bruteCounter) begin
        if (bruteCounter >= `bruteAttempts) begin // Give up on brute force once a certain amount of tries have elapsed.
            brute = 0;
            state = 4;
        end
    end
    
    // Stop once end of dictionary has been reached
    always @(addra) begin
        if (addra - `dictionaryStart >= `dictionarySize) begin // Give up on dictionary once all passwords have been attempted.
            dictionary = 0;
            brute = 1;
        end
    end  
endmodule
