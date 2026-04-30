module Detector1110_Mealy_binary (
    input  logic Clock,
    input  logic x,
    output logic y
);
    typedef enum logic [1:0] {
        A = 2'b00,
        B = 2'b01,
        C = 2'b10,
        D = 2'b11
    } states;

    states PresentState = A, NextState;

    always_comb begin : f_s_f_y
        NextState = PresentState;
        y = 1'b0;

        case (PresentState)
            A: begin
                NextState = (x) ? B : A;
                y = 1'b0;
            end

            B: begin
                NextState = (x) ? C : A;
                y = 1'b0;
            end

            C: begin
                NextState = (x) ? D : A;
                y = 1'b0;
            end

            D: begin
                if (x) begin
                    NextState = D;
                    y = 1'b0;
                end
                else begin
                    NextState = A;
                    y = 1'b1;
                end
            end
        endcase
    end : f_s_f_y

    always_ff @(posedge Clock)
        PresentState <= NextState;

endmodule


module Detector1110_Mealy_one_hot (
    input  logic Clock,
    input  logic x,
    output logic y
);
    typedef enum logic [3:0] {
        A = 4'b0001,
        B = 4'b0010,
        C = 4'b0100,
        D = 4'b1000
    } states;

    states PresentState = A, NextState;

    always_comb begin : f_s_f_y
        NextState = PresentState;
        y = 1'b0;

        unique case (1'b1)
            PresentState[0]: begin
                NextState = (x) ? B : A;
                y = 1'b0;
            end

            PresentState[1]: begin
                NextState = (x) ? C : A;
                y = 1'b0;
            end

            PresentState[2]: begin
                NextState = (x) ? D : A;
                y = 1'b0;
            end

            PresentState[3]: begin
                if (x) begin
                    NextState = D;
                    y = 1'b0;
                end
                else begin
                    NextState = A;
                    y = 1'b1;
                end
            end
        endcase
    end : f_s_f_y

    always_ff @(posedge Clock)
        PresentState <= NextState;

endmodule


module Detector1110_Mealy_gray (
    input  logic Clock,
    input  logic x,
    output logic y
);
    typedef enum logic [1:0] {
        A = 2'b00,
        B = 2'b01,
        C = 2'b11,
        D = 2'b10
    } states;

    states PresentState = A, NextState;

    always_comb begin : f_s_f_y
        NextState = PresentState;
        y = 1'b0;

        case (PresentState)
            A: begin
                NextState = (x) ? B : A;
                y = 1'b0;
            end

            B: begin
                NextState = (x) ? C : A;
                y = 1'b0;
            end

            C: begin
                NextState = (x) ? D : A;
                y = 1'b0;
            end

            D: begin
                if (x) begin
                    NextState = D;
                    y = 1'b0;
                end
                else begin
                    NextState = A;
                    y = 1'b1;
                end
            end
        endcase
    end : f_s_f_y

    always_ff @(posedge Clock)
        PresentState <= NextState;

endmodule


module Detector1110_Mealy_johnson (
    input  logic Clock,
    input  logic x,
    output logic y
);
    typedef enum logic [1:0] {
        A = 2'b00,
        B = 2'b01,
        C = 2'b11,
        D = 2'b10
    } states;

    states PresentState = A, NextState;

    always_comb begin : f_s_f_y
        NextState = PresentState;
        y = 1'b0;

        case (PresentState)
            A: begin
                NextState = (x) ? B : A;
                y = 1'b0;
            end

            B: begin
                NextState = (x) ? C : A;
                y = 1'b0;
            end

            C: begin
                NextState = (x) ? D : A;
                y = 1'b0;
            end

            D: begin
                if (x) begin
                    NextState = D;
                    y = 1'b0;
                end
                else begin
                    NextState = A;
                    y = 1'b1;
                end
            end
        endcase
    end : f_s_f_y

    always_ff @(posedge Clock)
        PresentState <= NextState;

endmodule

`timescale 1ns/1ns
`include "mealy.sv"

module Detector1110_Mealy_all_tb ();

    logic Clock = 0;
    logic x = 0;

    logic y_binary;
    logic y_one_hot;
    logic y_gray;
    logic y_johnson;

    Detector1110_Mealy_binary  U1 (Clock, x, y_binary);
    Detector1110_Mealy_one_hot U2 (Clock, x, y_one_hot);
    Detector1110_Mealy_gray    U3 (Clock, x, y_gray);
    Detector1110_Mealy_johnson U4 (Clock, x, y_johnson);

    initial
        repeat (80) #5 Clock = ~Clock;

    initial begin : testbench
        integer i;
        $urandom(5);
        for (i = 0; i < 30; i = i + 1)
            #12 x = $urandom_range(1,0);
    end

endmodule
