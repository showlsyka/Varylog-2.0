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


module Detector1110_param #(
    parameter TRIG_TYPE = 0,   // 0=D, 1=T, 2=RS, 3=JK
    parameter FSM_TYPE  = 0    // 0=Moore, 1=Mealy
)
(
    input  Clock,
    input  x,
    output y
);

generate

    // =====================================================
    // FSM_TYPE = 0 — автомат Мура
    // =====================================================
    if (FSM_TYPE == 0) begin : MOORE

        wire [2:0] b;

        wire [2:0] Dv;
        wire [2:0] Tv;
        wire [2:0] Sv;
        wire [2:0] Rv;
        wire [2:0] Jv;
        wire [2:0] Kv;

        // ---------- МДНФ для автомата Мура 1110 ----------

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

        // Для автомата Мура выход зависит только от состояния E = 100
        assign y = b[2];

    end


    // =====================================================
    // FSM_TYPE = 1 — автомат Мили
    // =====================================================
    else begin : MEALY

        wire [1:0] b;

        wire [1:0] Dv;
        wire [1:0] Tv;
        wire [1:0] Sv;
        wire [1:0] Rv;
        wire [1:0] Jv;
        wire [1:0] Kv;

        assign Dv[1] = (b[0] & x) | (b[1] & x);
        assign Dv[0] = (~b[0] & x) | (b[1] & x);

        // T
        assign Tv[1] = (b[1] & ~x) | (~b[1] & b[0] & x);
        assign Tv[0] = (~b[0] & x) | (b[0] & ~x) | (~b[1] & b[0]);

        // RS
        assign Sv[1] = b[0] & x;
        assign Sv[0] = ~b[0] & x;

        assign Rv[1] = ~x;
        assign Rv[0] = ~x | (~b[1] & b[0]);

        // JK
        assign Jv[1] = b[0] & x;
        assign Jv[0] = x;

        assign Kv[1] = ~x;
        assign Kv[0] = ~x | ~b[1];

        if (TRIG_TYPE == 0) begin : GEN_D
            D_FlipFlop FF1 (.Clock(Clock), .D(Dv[1]), .Q(b[1]));
            D_FlipFlop FF0 (.Clock(Clock), .D(Dv[0]), .Q(b[0]));
        end
        else if (TRIG_TYPE == 1) begin : GEN_T
            T_FlipFlop FF1 (.Clock(Clock), .T(Tv[1]), .Q(b[1]));
            T_FlipFlop FF0 (.Clock(Clock), .T(Tv[0]), .Q(b[0]));
        end
        else if (TRIG_TYPE == 2) begin : GEN_RS
            RS_FlipFlop FF1 (.Clock(Clock), .R(Rv[1]), .S(Sv[1]), .Q(b[1]));
            RS_FlipFlop FF0 (.Clock(Clock), .R(Rv[0]), .S(Sv[0]), .Q(b[0]));
        end
        else begin : GEN_JK
            JK_FlipFlop FF1 (.Clock(Clock), .J(Jv[1]), .K(Kv[1]), .Q(b[1]));
            JK_FlipFlop FF0 (.Clock(Clock), .J(Jv[0]), .K(Kv[0]), .Q(b[0]));
        end

        // Для автомата Мили выход зависит от состояния и входа
        assign y = b[1] & b[0] & x;

    end

endgenerate

endmodule
