module D_FlipFlop (
    input  Clock,
    input  D,
    output reg Q = 0
);
    always @(posedge Clock)
        Q <= D;
endmodule


module T_FlipFlop (
    input  Clock,
    input  T,
    output reg Q = 0
);
    always @(posedge Clock)
        if (T)
            Q <= ~Q;
endmodule


module RS_FlipFlop (
    input  Clock,
    input  R,
    input  S,
    output reg Q = 0
);
    always @(posedge Clock) begin
        case ({R,S})
            2'b00: Q <= Q;
            2'b01: Q <= 1'b1;
            2'b10: Q <= 1'b0;
            2'b11: Q <= Q;
        endcase
    end
endmodule


module JK_FlipFlop (
    input  Clock,
    input  J,
    input  K,
    output reg Q = 0
);
    always @(posedge Clock) begin
        case ({J,K})
            2'b00: Q <= Q;
            2'b01: Q <= 1'b0;
            2'b10: Q <= 1'b1;
            2'b11: Q <= ~Q;
        endcase
    end
endmodule


module Detector1110_Moore_param #(parameter TRIG_TYPE = 0)
(
    input  Clock,
    input  x,
    output y
);

    // ??????? ????????? ????????
    wire [2:0] b;

    // ??????? ??????????? ?????????
    wire [2:0] Dv;
    wire [2:0] Tv;
    wire [2:0] Sv;
    wire [2:0] Rv;
    wire [2:0] Jv;
    wire [2:0] Kv;

    /* ---------- ??????? ???????? ???? 1110 ---------- */

    // D
    assign Dv[2] =  b[1] &  b[0] & ~x;
    assign Dv[1] =  x & (b[0] | b[1]);
    assign Dv[0] =  x & (~b[0] | b[1]);

    // T
    assign Tv[2] =  b[2] | (b[1] & b[0] & ~x);
    assign Tv[1] = (b[1] & ~x) | (~b[1] & b[0] & x);
    assign Tv[0] = (b[0] & ~x) | (~b[0] & x) | (~b[1] & x);

    // RS
    assign Sv[2] =  b[1] &  b[0] & ~x;
    assign Sv[1] =  b[0] & x;
    assign Sv[0] = ~b[0] & x;

    assign Rv[2] = ~b[1];
    assign Rv[1] = ~x;
    assign Rv[0] = ~x | (~b[1] & b[0]);

    // JK
    assign Jv[2] =  b[1] &  b[0] & ~x;
    assign Jv[1] =  b[0] & x;
    assign Jv[0] = (~b[1] & x) | (b[1] & ~x);

    assign Kv[2] = 1'b1;
    assign Kv[1] = ~x;
    assign Kv[0] = ~x | ~b[1];

    /* ---------- ????? ???? ???????? ---------- */
    generate
        if (TRIG_TYPE == 0) begin : GEN_D
            D_FlipFlop FF2 (.Clock(Clock), .D(Dv[2]), .Q(b[2]));
            D_FlipFlop FF1 (.Clock(Clock), .D(Dv[1]), .Q(b[1]));
            D_FlipFlop FF0 (.Clock(Clock), .D(Dv[0]), .Q(b[0]));
        end
        else if (TRIG_TYPE == 1) begin : GEN_T
            T_FlipFlop FF2 (.Clock(Clock), .T(Tv[2]), .Q(b[2]));
            T_FlipFlop FF1 (.Clock(Clock), .T(Tv[1]), .Q(b[1]));
            T_FlipFlop FF0 (.Clock(Clock), .T(Tv[0]), .Q(b[0]));
        end
        else if (TRIG_TYPE == 2) begin : GEN_RS
            RS_FlipFlop FF2 (.Clock(Clock), .R(Rv[2]), .S(Sv[2]), .Q(b[2]));
            RS_FlipFlop FF1 (.Clock(Clock), .R(Rv[1]), .S(Sv[1]), .Q(b[1]));
            RS_FlipFlop FF0 (.Clock(Clock), .R(Rv[0]), .S(Sv[0]), .Q(b[0]));
        end
        else begin : GEN_JK
            JK_FlipFlop FF2 (.Clock(Clock), .J(Jv[2]), .K(Kv[2]), .Q(b[2]));
            JK_FlipFlop FF1 (.Clock(Clock), .J(Jv[1]), .K(Kv[1]), .Q(b[1]));
            JK_FlipFlop FF0 (.Clock(Clock), .J(Jv[0]), .K(Kv[0]), .Q(b[0]));
        end
    endgenerate

    // ??? ???????? ???? ????? ??????? ?????? ?? ?????????
    assign y = b[2];

endmodule

`include "Detector_1110.sv"

`timescale 1ns/1ns

module Detector1110_Moore_param_tb ();

    reg Clock = 0;
    reg x = 0;
    wire y;

    Detector1110_Moore_param #(0) mut (Clock, x, y);

    initial repeat (80) #5 Clock = ~Clock;

    initial begin: testbench
        integer i;
        $urandom(5);
        for(i = 0; i < 30; i = i + 1)
            #12 x = $urandom_range(1,0);
    end

endmodule
