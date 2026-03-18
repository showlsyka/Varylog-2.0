`timescale 1ns/1ns

module JKff(q, clK, J, K);
    output reg q = 0;
    input clK, J, K;

    always @(posedge clK)
        if (J && K) q <= ~q;
        else if (J) q <= 1'b1;
        else if (K) q <= 1'b0;
endmodule


// =====================================================
// SUM / SUB
// =====================================================
module zad53 #(parameter mode="SUM") (clocK, q);
    input clocK;
    output [3:0] q;

    reg [3:0] K, J;
    genvar i;

    generate
        if (mode == "SUM") begin
            always @*
                case (q)
                    4'b0000 : {K,J} = 8'bxxxx0001;
                    4'b0001 : {K,J} = 8'bxxx0001x;
                    4'b0011 : {K,J} = 8'bxx0100xx;
                    4'b0010 : {K,J} = 8'bxx0x01x0;
                    4'b0110 : {K,J} = 8'bx00x0xx1;
                    4'b0111 : {K,J} = 8'bx0100xxx;
                    4'b0101 : {K,J} = 8'bx0x10x0x;
                    4'b0100 : {K,J} = 8'bx0xx1000;
                    4'b1100 : {K,J} = 8'b00xxxx01;
                    4'b1101 : {K,J} = 8'b00x0xx1x;
                    4'b1111 : {K,J} = 8'b0001xxxx;
                    4'b1110 : {K,J} = 8'b010xxxx0;
                    4'b1010 : {K,J} = 8'b0x0xx0x1;
                    4'b1011 : {K,J} = 8'b0x1000xx;
                    4'b1001 : {K,J} = 8'b0xx10x0x;
                    4'b1000 : {K,J} = 8'b1xxxx000;
                    default : {K,J} = 8'bxxxxxxxx;
                endcase
        end
        else if (mode == "SUB") begin
            always @*
                case (q)
                    4'b0000 : {K,J} = 8'bxxxx1000;
                    4'b0001 : {K,J} = 8'bxxx1000x;
                    4'b0011 : {K,J} = 8'bxx1000xx;
                    4'b0010 : {K,J} = 8'bxx0x00x1;
                    4'b0110 : {K,J} = 8'bx10x0xx0;
                    4'b0111 : {K,J} = 8'bx0010xxx;
                    4'b0101 : {K,J} = 8'bx0x00x1x;
                    4'b0100 : {K,J} = 8'bx0xx0x01;
                    4'b1100 : {K,J} = 8'b10xxxx00;
                    4'b1101 : {K,J} = 8'b00x1xx0x;
                    4'b1111 : {K,J} = 8'b0010xxxx;
                    4'b1110 : {K,J} = 8'b000xxxx1;
                    4'b1010 : {K,J} = 8'b0x0xx1x0;
                    4'b1011 : {K,J} = 8'b0x01x0xx;
                    4'b1001 : {K,J} = 8'b0xx0x01x;
                    4'b1000 : {K,J} = 8'b0xxxx001;
                    default : {K,J} = 8'bxxxxxxxx;
                endcase
        end
    endgenerate

    generate
        for (i = 0; i < 4; i = i + 1) begin: registers
            JKff JKffi(q[i], clocK, J[i], K[i]);
        end
    endgenerate

endmodule


// =====================================================
// REVERSE
// dir = 0 -> SUM
// dir = 1 -> SUB
// =====================================================
module zad53_reverse(clocK, q, dir);
    input clocK;
    output [3:0] q;
    output dir;

    wire d;
    assign dir = d;

    reg [3:0] K, J;
    reg Kd, Jd;

always @*
    case ({d, q})

        // dir = 0  -> SUM
        5'b00000 : {Kd,K,Jd,J} = 10'bxxxxx00001;
        5'b00001 : {Kd,K,Jd,J} = 10'bxxxx00001x;
        5'b00011 : {Kd,K,Jd,J} = 10'bxxx1000xx;
        5'b00010 : {Kd,K,Jd,J} = 10'bxxx0x001x0;
        5'b00110 : {Kd,K,Jd,J} = 10'bxx00x00xx1;
        5'b00111 : {Kd,K,Jd,J} = 10'bxx01000xxx;
        5'b00101 : {Kd,K,Jd,J} = 10'bxx0x100x0x;
        5'b00100 : {Kd,K,Jd,J} = 10'bxx0xx01x00;
        5'b01100 : {Kd,K,Jd,J} = 10'bx00xx0xx01;
        5'b01101 : {Kd,K,Jd,J} = 10'bx000x0xx1x;
        5'b01111 : {Kd,K,Jd,J} = 10'bx00010xxxx;
        5'b01110 : {Kd,K,Jd,J} = 10'bx010x0xxx0;
        5'b01010 : {Kd,K,Jd,J} = 10'bx0x0x0x0x1;
        5'b01011 : {Kd,K,Jd,J} = 10'bx0x100x0xx;
        5'b01001 : {Kd,K,Jd,J} = 10'bx0xx10x00x;

	5'b01000 : {Kd,K,Jd,J} = 10'bx0xx01x001; // 0,1000 -> 1,1001
	5'b10000 : {Kd,K,Jd,J} = 10'b1xxxx0001;  // 1,0000 -> 0,0001

        5'b10001 : {Kd,K,Jd,J} = 10'b0xxx1x000x;
        5'b10011 : {Kd,K,Jd,J} = 10'b0xx10x00xx;
        5'b10010 : {Kd,K,Jd,J} = 10'b0xx0xx00x1;
        5'b10110 : {Kd,K,Jd,J} = 10'b0x10xx0xx0;
        5'b10111 : {Kd,K,Jd,J} = 10'b0x0010xxx;
        5'b10101 : {Kd,K,Jd,J} = 10'b0x0x0x0x1x;
        5'b10100 : {Kd,K,Jd,J} = 10'b0x0xxx0x01;
        5'b11100 : {Kd,K,Jd,J} = 10'b010xxxxx00;
        5'b11101 : {Kd,K,Jd,J} = 10'b000x1xxx0x;
        5'b11111 : {Kd,K,Jd,J} = 10'b00010xxxxx;
        5'b11110 : {Kd,K,Jd,J} = 10'b0000xxxxx1;
        5'b11010 : {Kd,K,Jd,J} = 10'b00x0xxx1x0;
        5'b11011 : {Kd,K,Jd,J} = 10'b00x01xx0xx;
        5'b11001 : {Kd,K,Jd,J} = 10'b00xx0xx01x;
        5'b11000 : {Kd,K,Jd,J} = 10'b00xxxx001;

        default  : {Kd,K,Jd,J} = 10'bxxxxxxxxxx;
    endcase

    JKff ff0(q[0], clocK, J[0], K[0]);
    JKff ff1(q[1], clocK, J[1], K[1]);
    JKff ff2(q[2], clocK, J[2], K[2]);
    JKff ff3(q[3], clocK, J[3], K[3]);
    JKff ffd(d,    clocK, Jd,   Kd);

endmodule

`timescale 1ns/1ns
`define TD 10
`include "lr5zd5.v"

module zad53_tb ();

    reg clock = 0;

    wire [3:0] q_sum;
    wire [3:0] q_sub;
    wire [3:0] q_rev;
    wire dir_rev;

    zad53         #(.mode("SUM")) sum_counter (.q(q_sum), .clocK(clock));
    zad53         #(.mode("SUB")) sub_counter (.q(q_sub), .clocK(clock));
    zad53_reverse                  rev_counter (.q(q_rev), .dir(dir_rev), .clocK(clock));

    initial
        repeat (64) #5 clock = ~clock;

endmodule
