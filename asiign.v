`timescale 1ns/1ns

module jkff(clock, j, k, q);
    input clock, j, k;
    output reg q = 0;

    always @(posedge clock)
        if (j && k)      q <= ~q;
        else if (j)      q <= 1'b1;
        else if (k)      q <= 1'b0;
endmodule


// =====================================================
// SUM
// =====================================================
module count4gray_sum_jk(clock, b);
    input clock;
    output [3:0] b;

    wire [3:0] j, k, q;

    assign j[3] =  q[2] & ~q[1] & ~q[0];
    assign k[3] = ~q[2] & ~q[1] & ~q[0];

    assign j[2] =  q[1] & ~q[3] & ~q[0];
    assign k[2] =  q[1] &  q[3] & ~q[0];

    assign j[1] = (q[0] & ~q[2] & ~q[3]) |
                  (q[0] &  q[2] &  q[3]);

    assign k[1] = (q[0] &  q[2] & ~q[3]) |
                  (q[0] &  q[3] & ~q[2]);

    assign j[0] = ( q[1] &  q[2] & ~q[3]) |
                  ( q[1] &  q[3] & ~q[2]) |
                  ( q[2] &  q[3] & ~q[1]) |
                  (~q[1] & ~q[2] & ~q[3]);

    assign k[0] = ( q[1] &  q[2] &  q[3]) |
                  ( q[1] & ~q[2] & ~q[3]) |
                  ( q[2] & ~q[1] & ~q[3]) |
                  ( q[3] & ~q[1] & ~q[2]);

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1)
            jkff jkffi(clock, j[i], k[i], q[i]);
    endgenerate

    assign b = q;
endmodule


// =====================================================
// SUB
// =====================================================
module count4gray_sub_jk(clock, b);
    input clock;
    output [3:0] b;

    wire [3:0] j, k, q;

    assign j[3] = ~q[2] & ~q[1] & ~q[0];
    assign k[3] =  q[2] & ~q[1] & ~q[0];

    assign j[2] =  q[1] &  q[3] & ~q[0];
    assign k[2] =  q[1] & ~q[3] & ~q[0];

    assign j[1] = (q[0] &  q[2] & ~q[3]) |
                  (q[0] &  q[3] & ~q[2]);

    assign k[1] = (q[0] & ~q[2] & ~q[3]) |
                  (q[0] &  q[2] &  q[3]);

    assign j[0] = ( q[1] &  q[2] &  q[3]) |
                  ( q[1] & ~q[2] & ~q[3]) |
                  ( q[2] & ~q[1] & ~q[3]) |
                  ( q[3] & ~q[1] & ~q[2]);

    assign k[0] = ( q[1] &  q[2] & ~q[3]) |
                  ( q[1] &  q[3] & ~q[2]) |
                  ( q[2] &  q[3] & ~q[1]) |
                  (~q[1] & ~q[2] & ~q[3]);

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1)
            jkff jkffi(clock, j[i], k[i], q[i]);
    endgenerate

    assign b = q;
endmodule

module count4gray_reverse_jk(clock, dir, b);
    input clock;
    output dir;
    output [3:0] b;

    wire [4:0] q;
    wire [4:0] j, k;

    wire d;
    assign d   = q[4];
    assign dir = q[4];
    assign b   = q[3:0];

    // ---------------------------------
    // ????????? ????????? ?????????
    // ---------------------------------
    wire Tsum = ~d &  q[3] & ~q[2] & ~q[1] & ~q[0]; // 0,1000
    wire Tsub =  d & ~q[3] & ~q[2] & ~q[1] & ~q[0]; // 1,0000

    // ---------------------------------
    // dir
    // ---------------------------------
    assign j[4] = Tsum;
    assign k[4] = Tsub;

    // ---------------------------------
    // q3
    // SUM/SUB + ???????? ?? ????????
    // ---------------------------------
    assign j[3] = (~d &  q[2] & ~q[1] & ~q[0]) |
                  ( d & ~q[2] & ~q[1] & ~q[0] & ~Tsub);

    assign k[3] = (~d & ~q[2] & ~q[1] & ~q[0] & ~Tsum) |
                  ( d &  q[2] & ~q[1] & ~q[0]);

    // ---------------------------------
    // q2
    // ---------------------------------
    assign j[2] = (~d &  q[1] & ~q[3] & ~q[0]) |
                  ( d &  q[1] &  q[3] & ~q[0]);

    assign k[2] = (~d &  q[1] &  q[3] & ~q[0]) |
                  ( d &  q[1] & ~q[3] & ~q[0]);

    // ---------------------------------
    // q1
    // ---------------------------------
    assign j[1] = (~d & ((q[0] & ~q[2] & ~q[3]) |
                         (q[0] &  q[2] &  q[3]))) |
                  ( d & ((q[0] &  q[2] & ~q[3]) |
                         (q[0] &  q[3] & ~q[2])));

    assign k[1] = (~d & ((q[0] &  q[2] & ~q[3]) |
                         (q[0] &  q[3] & ~q[2]))) |
                  ( d & ((q[0] & ~q[2] & ~q[3]) |
                         (q[0] &  q[2] &  q[3])));

    // ---------------------------------
    // q0
    // ?? ?????????? ??? ???? ????????????? ??????? ? 1
    // ---------------------------------
    assign j[0] = (~d & (( q[1] &  q[2] & ~q[3]) |
                         ( q[1] &  q[3] & ~q[2]) |
                         ( q[2] &  q[3] & ~q[1]) |
                         (~q[1] & ~q[2] & ~q[3]))) |
                  ( d & (( q[1] &  q[2] &  q[3]) |
                         ( q[1] & ~q[2] & ~q[3]) |
                         ( q[2] & ~q[1] & ~q[3]) |
                         ( q[3] & ~q[1] & ~q[2]))) |
                  Tsum | Tsub;

    assign k[0] = (~d & (( q[1] &  q[2] &  q[3]) |
                         ( q[1] & ~q[2] & ~q[3]) |
                         ( q[2] & ~q[1] & ~q[3]) |
                         ( q[3] & ~q[1] & ~q[2]))) |
                  ( d & (( q[1] &  q[2] & ~q[3]) |
                         ( q[1] &  q[3] & ~q[2]) |
                         ( q[2] &  q[3] & ~q[1]) |
                         (~q[1] & ~q[2] & ~q[3])));

    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1)
            jkff jkffi(clock, j[i], k[i], q[i]);
    endgenerate

endmodule
`timescale 1ns/1ns
`include "asiign.v"

module gray_jk_sum_sub_tb();

    reg clock = 0;
    wire dir;
    wire [3:0] b;
    wire dir;
    wire [3:0] b;


    count4gray_reverse_jk counter(clock, dir, b);
    count4gray_sum_jk sum_counter(clock, b_sum);
    count4gray_sub_jk sub_counter(clock, b_sub);

    initial
        repeat (80) #5 clock = ~clock;

endmodule
