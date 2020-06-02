module Seg_Driver( //In-work code to display state to display
    input clk, reset, //Using Prac 4 provided code
    input [2:0] state, //Don't look
    output reg [7:0] seg,
    output reg [7:0] segdriv
);

wire [6:0]SS[7:0];
DecodeState decode0(state, SS[0]);
DecodeState decode1(state, SS[1]);
DecodeState decode2(state, SS[2]);
DecodeState decode3(state, SS[3]);

// Counter to reduce the 100 MHz clock to 762.939 Hz (100 MHz / 2^17)
reg [16:0]count;

// Scroll through the digits, switching one on at a time
always @(posedge clk) begin
    count <= count + 1'b1;
    if (reset) begin
        segdriv <= 4'hE;
    end
    else if(&count) begin
        segdriv <= {segdriv[2:0], segdriv[3]};
    end
end

//------------------------------------------------------------------------------
always @(*) begin // This describes a purely combinational circuit
    seg[7] <= 1'b1; // Decimal point always off
    if (reset) begin
        seg[6:0] <= 7'h7F; // All off during Reset
    end else begin
        case(~segdriv) // Connect the correct signals,
            4'h1 : seg[6:0] <= ~SS[0]; // depending on which digit is on at
            4'h2 : seg[6:0] <= ~SS[1]; // this point
            4'h4 : seg[6:0] <= ~SS[2];
            4'h8 : seg[6:0] <= ~SS[3];
            default: seg[6:0] <= 7'h7F;
        endcase
    end
end

endmodule