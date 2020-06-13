`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/12/2020 08:48:53 PM
// Design Name: 
// Module Name: TB_VADER
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


module TB_VADER();
    reg clk;
    reg reset;
    reg start;
    wire [2:0] state;
    
    VADER VADER(clk, reset, start, state);
    
    initial begin
        clk <= 0;
        reset <= 0;
        start <= 0;
        #10
        reset <= 1;
        clk <= 1;
        #10
        clk <= 0;
        #10
        clk <= 1;
        #10
        clk <= 0;
        reset <= 0;
        #10
        clk <= 1;
        #10
        clk <= 0;
        #10
        clk <= 1;
        start <= 1;
        #10
        clk <= 0;
        #10
        clk <= 1;
    end
    
    always 
        begin
            #10 clk <= ~clk;
        end
    
endmodule