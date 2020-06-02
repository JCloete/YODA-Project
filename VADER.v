`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.06.2020 17:45:15
// Design Name: 
// Module Name: VADER
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module VADER(
    input clk, //100 MHz clock
    input reset, //Reset button
    input btnR, //Left button
    input btnL, //Right button
    //output wire [7:0]seg, //Seg display, to be linked with state (active low)
    //output wire [7:0]segdriv, //Seg driv (active low)
    //output wire [2:0]led, //RGB led (to be linked state in HW)
    output reg [2:0]state //State (wait/busy/success/success) <- monitor in test bench
    );
    
    //Internal variables
    wire resState;
    Delayed_Res resetter(clk, reset, resState);
    wire pressState;
    Debounce(clk, btnR, pressState);
    
    // Memory IO
    reg ena = 1;
    reg wea = 0;
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
    
    always @(posedge resState) begin
        state <= 0;
    end
    
    always @(posedge clk) begin
        //RELEVANT CODE GOES HERE
    end
    
endmodule
