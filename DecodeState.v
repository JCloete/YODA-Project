`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.06.2020 18:28:44
// Design Name: 
// Module Name: DecodeState
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


module DecodeState(
    input [2:0] state,
    output reg [6:0] display
    );
    
    always @(state) begin //Current sets all digits to the same thing
        case (state)
            3'b001:
                display <= 7'b1110110;
            3'b010:
                display <= 7'b1110011;
            3'b011:
                display <= 7'b1101101;
            3'b100:
                display <= 7'b1110001;
        endcase
    end
endmodule
