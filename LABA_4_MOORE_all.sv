module Detector1110_Moore_binary (
    input  logic Clock,
    input  logic x,
    output logic y
);
    typedef enum logic [2:0] {
        A = 3'b000,
        B = 3'b001,
        C = 3'b010,
        D = 3'b011,
        E = 3'b100
    } states;

    states PresentState = A, NextState;

    always_comb begin : f_s
        NextState = PresentState;
        case (PresentState)
            A: NextState = (x) ? B : A;
            B: NextState = (x) ? C : A;
            C: NextState = (x) ? D : A;
            D: NextState = (x) ? D : E;
            E: NextState = (x) ? B : A;
        endcase
    end : f_s

    always_ff @(posedge Clock)
        PresentState <= NextState;

    assign y = (PresentState == E);
endmodule

module Detector1110_Moore_one_hot (
    input  logic Clock,
    input  logic x,
    output logic y
);
    typedef enum logic [4:0] {
        A = 5'b00001,
        B = 5'b00010,
        C = 5'b00100,
        D = 5'b01000,
        E = 5'b10000
    } states;

    states PresentState = A, NextState;

    always_comb begin : f_s
        NextState = PresentState;
        unique case (1'b1)
            PresentState[0]: NextState = (x) ? B : A;
            PresentState[1]: NextState = (x) ? C : A;
            PresentState[2]: NextState = (x) ? D : A;
            PresentState[3]: NextState = (x) ? D : E;
            PresentState[4]: NextState = (x) ? B : A;
        endcase
    end : f_s

    always_ff @(posedge Clock)
        PresentState <= NextState;

    always_comb begin : f_y
        y = PresentState[4];
    end : f_y
endmodule

module Detector1110_Moore_gray (
    input  logic Clock,
    input  logic x,
    output logic y
);
    typedef enum logic [2:0] {
        A = 3'b000,
        B = 3'b001,
        C = 3'b011,
        D = 3'b010,
        E = 3'b110
    } states;

    states PresentState = A, NextState;

    always_comb begin : f_s
        NextState = PresentState;
        case (PresentState)
            A: NextState = (x) ? B : A;
            B: NextState = (x) ? C : A;
            C: NextState = (x) ? D : A;
            D: NextState = (x) ? D : E;
            E: NextState = (x) ? B : A;
        endcase
    end : f_s

    always_ff @(posedge Clock)
        PresentState <= NextState;

    assign y = (PresentState == E);
endmodule

module Detector1110_Moore_johnson (
    input  logic Clock,
    input  logic x,
    output logic y
);
    typedef enum logic [2:0] {
        A = 3'b000,
        B = 3'b001,
        C = 3'b011,
        D = 3'b010,
        E = 3'b110
    } states;

    states PresentState = A, NextState;

    always_comb begin : f_s
        NextState = PresentState;
        case (PresentState)
            A: NextState = (x) ? B : A;
            B: NextState = (x) ? C : A;
            C: NextState = (x) ? D : A;
            D: NextState = (x) ? D : E;
            E: NextState = (x) ? B : A;
        endcase
    end : f_s

    always_ff @(posedge Clock)
        PresentState <= NextState;

    assign y = (PresentState == E);
endmodule

`timescale 1ns/1ns
`include "Detector1110_Moore.sv"

module Detector1110_Moore_all_tb ();

    logic Clock = 0;
    logic x = 0;

    logic y_binary;
    logic y_one_hot;
    logic y_gray;
    logic y_johnson;

    Detector1110_Moore_binary  U1 (Clock, x, y_binary);
    Detector1110_Moore_one_hot U2 (Clock, x, y_one_hot);
    Detector1110_Moore_gray    U3 (Clock, x, y_gray);
    Detector1110_Moore_johnson U4 (Clock, x, y_johnson);

    initial
        repeat (80) #5 Clock = ~Clock;

    initial begin : testbench
        integer i;
        $urandom(5);
        for (i = 0; i < 30; i = i + 1)
            #12 x = $urandom_range(1,0);
    end

endmodule
