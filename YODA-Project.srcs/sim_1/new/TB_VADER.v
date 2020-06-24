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
//    reg reset;
//    reg start;
//    wire [2:0] led;
//    wire [2:0] state;
//    wire done;
    reg [127:0]data_in;
    reg decrypt;
    wire [127:0]data_out;
    
    //VADER VADER(clk, reset, start, led, state);
    encrypter encrypter(data_in, decrypt, data_out);
    
    initial 
    begin
        // $display("clock\treset\tstart\tled\tstate\tdone");
        // $monitor("%d\t%d\t%d\t%d\t%d\t%d",clk,reset,start, led, state, done);
        //        clk <= 0;
        //        reset <= 0;
        //        start <= 0;
        //        #10
        //        reset <= 1;
        //        clk <= 1;
        //        #10
        //        clk <= 0;
        //        #10
        //        clk <= 1;
        //        #10
        //        clk <= 0;
        //        reset <= 0;
        //        #10
        //        clk <= 1;
        //        #10
        //        clk <= 0;
        //        #10
        //        clk <= 1;
        //        start <= 1;
        //        #10
        //        clk <= 0;
        //        #10
        //        clk <= 1;
        //        #10
        //        clk <= 0;
        //        start <= 0;

        decrypt = 0;
        #10
        data_in = {8'd204, 8'd110, 8'd219, 8'd177, 8'd21, 8'd152, 8'd49, 8'd113, 8'd39, 8'd162, 8'd150, 8'd37, 8'd144, 8'd24, 8'd51, 8'd210};
        $display("WHAT I PASSED IN: %s", data_in);
        #10
        decrypt = 1;
        //$finish
    end
    
    always 
        begin
            #10 clk <= ~clk;
        end
    
endmodule
