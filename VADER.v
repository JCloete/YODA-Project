`timescale 1ns / 1ps

// defines for system parameters
`define dictionarySize 4
`define dictionaryStart 3

module VADER(
    input clk, //100 MHz clock. 
    input resetB, // Reset button
    input startB, // Start button
    output reg [2:0]led, //RGB led (to be linked state in HW)
    output reg [2:0]state
    );
    // State (wait - 0/decrypt - 1/dictionary - 2/success - 3/failure - 4)
    
    //Internal variables
    wire reset;	// Resets our system to the beginning
    Delayed_Res resetter(clk, resetB, reset);
    wire start; // Starts our system once resetted
    Debounce Debounce(clk, startB, start);
    
    // Variables to interface with encryption module
    reg [127:0]data_in;
    reg [127:0]key_in;
    reg start_AES;
    reg decrypt;
    wire [127:0]data_out;
    
    // Instantiate the encrypter module
    encrypter encrypter(data_in, key_in, start_AES, decrypt, data_out);
    
    // Memory IO
    reg ena = 1; // Enable reading memory
    reg wea = 0; // Not current writing anything
    reg [7:0] addra=0;
    reg [127:0] dina=0; //We're not putting data in, so we can leave this unassigned
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
    
    initial begin
        $display("Initializing");
        // Set all flags to 0
        addra <= 0;
        start_AES <= 0;
        decrypt <= 1; // Set this to 1 because the first operation is a decryption operation
        state = 0;
        // Turn off LED
        led = 3'b000;
        #60
        // input hashed password to be guessed. Example below
        data_in = douta;
        addra = 1;
        #60
        key_in = douta;
        addra = 0; #60;
    end
    
    /*always @(posedge start) begin
        if (state == 0) begin // So we cant go back to decrypt state mid cracking attempt.
            // Ensure that can only start once reset to wait state
            hPass <= douta;
            addra = 2;
            #60
            state = 1;
            $display("Starting Decryption");
        end
    end*/
    
	// Resetting the system back to the beginning to allow for a different password
	// to be guessed
    /*always @(posedge resState) begin
        addra <= 0;
        #60
        state = 0;
        // Turn off LED
        led = 3'b000;
        // reinput same or another hashed password to be guessed
        hPass <= douta;
        $display("Resetting ");
    end*/

    always @(posedge clk or posedge reset or posedge start) begin
        if (reset) begin
            addra <= 0;
            #60
            state = 0;
            // Turn off LED
            led = 3'b000;
            // reinput same or another hashed password to be guessed
            hPass <= douta;
            $display("Resetting ");
        end
        
        else if (start) begin
            if (state == 0) begin // So we cant go back to decrypt state mid cracking attempt.
                // Ensure that can only start once reset to wait state
                hPass <= douta;
                addra = 2;
                #60
                state = 1;
                $display("Starting Decryption");
            end
        end
        
        else begin
            if (state == 0) begin // Check for wait status
                led <= 3'b011; // Do wait stuff i.e Flash Yellow LED
                $display("Waiting State 0 Reached");
            end
            
            if (state == 1) begin
                // EXAMPLE DECRYPTION DUE TO ENCRYPTION NOT FINISHED AT THIS TIME
                $display("Decryption State 1 Reached");
                start_AES = 1;
                #60;
                start_AES = 0;
                if ("Discombobulateme" == data_out) begin
                    $display("Decryption Sucess.");
                    state <= 3;
                end else begin
                    $display("Decryption Failed.");
                    addra = `dictionaryStart; // Set address to whatever the first dictionary input is
                    #60
                    state = 2; // Change state to dictionary attack
                    decrypt = 0;
                end
            end 
            
            if (state == 2) begin
                // Start dictionary attack
                $display("Dictionary State 2 Reached");
                data_in = douta;
                start_AES = 1;
                #60;
                start_AES = 0;
                $display("Encrypted Guess: %s", data_out);
                $display("Hashed Password: %s", hPass);
                // End loop check
                // Give up on dictionary once all passwords have been attempted.
                if (addra - `dictionaryStart >= `dictionarySize) begin 
                    $display("Dictionary Attack Failed.");
                    addra = 0;
                    #60;
                    state = 4; // Proceed to Failure State
                end
                else if (hPass == data_out) begin
                    $display("Dictionary Attack Succeeded.");
                    state = 3;
                    addra = 0;
                    #60;
                end
                else begin
                    addra <= addra + 1;
                    #60;
                end            
            end
    
            // Check for ending conditions
            if (state == 3) begin // Check for success state
                led <= 3'b010; // Do Success state stuff. i.e Flash Green LED
                $display("Success State: PW = Discombobulateme");
                $finish;
            end
            
            if (state == 4) begin // check for failure state
                led <= 3'b001; // Do Failure state stuff. i.e Flash Red LED
                $display("Failure State");
                $finish;
            end
        end
    end
endmodule