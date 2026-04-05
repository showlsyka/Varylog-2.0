module rsff (
    input  clk,
    input  enable,
    input  r,
    input  s,
    output reg q = 0
);
    always @(posedge clk) begin
        if (enable) begin
            if (r & s) q <= 1'bx;
        else if (r) q <= 1'b0;
        else if (s) q <= 1'b1;
        end
    end
endmodule

module freq_divider #(parameter NUMBER = 125_000) (
    input  clock,
    output reg enable = 0
);
    reg [31:0] cnt = 0;

    always @(posedge clock) begin
        if (cnt == NUMBER - 1) begin
            cnt    <= 0;
            enable <= 1'b1;
        end
        else begin
            cnt    <= cnt + 1'b1;
            enable <= 1'b0;
        end
    end
endmodule

module count_gray_v2 #(parameter mode="SUM") (
    input clk,
    input enable,
    input  dir,
    output [3:0] c
);

    wire [3:0] q;
    reg  [3:0] R, S;

    assign c = q;

generate

// =========================
// SUM
// =========================

if (mode == "SUM") begin

    always @*
        case (q)
      4'b0000 : {R,S} = 8'bxxx00001;
      4'b0001 : {R,S} = 8'bxx00001x;
      4'b0011 : {R,S} = 8'bx00001xx;
      4'b0111 : {R,S} = 8'b00001xxx;
      4'b1111 : {R,S} = 8'b0001xxx0;
      4'b1110 : {R,S} = 8'b001xxx00;
      4'b1100 : {R,S} = 8'b01xxx000;
      4'b1000 : {R,S} = 8'b1xxx0000;
      default : {R,S} = 8'bxxxxxxxx;
        endcase

end

// =========================
// SUB
// =========================

else if (mode == "SUB") begin

    always @*
        case (q)
    4'b0000 : {R,S} = 8'b00001111;
      4'b0001 : {R,S} = 8'bxxx10000;
      4'b0010 : {R,S} = 8'bxx100001;
      4'b0011 : {R,S} = 8'bxx0100x0;
      4'b0100 : {R,S} = 8'bx1000011;
      4'b0101 : {R,S} = 8'bx0x10x00;
      4'b0110 : {R,S} = 8'bx0100x01;
      4'b0111 : {R,S} = 8'bx0010xx0;
      4'b1000 : {R,S} = 8'b10000111;
      4'b1001 : {R,S} = 8'b0xx1x000;
      4'b1010 : {R,S} = 8'b0x10x001;
      4'b1011 : {R,S} = 8'b0x01x0x0;
      4'b1100 : {R,S} = 8'b0100x011;
      4'b1101 : {R,S} = 8'b00x1xx00;
      4'b1110 : {R,S} = 8'b0010xx01;
      4'b1111 : {R,S} = 8'b0001xxx0;
      default : {R,S} = 8'bxxxxxxxx;
        endcase

end

else begin

    always @* begin
        if (dir == 1'b0) begin
        case (q)
      4'b0000 : {R,S} = 8'bxxx00001;
      4'b0001 : {R,S} = 8'bxx00001x;
      4'b0011 : {R,S} = 8'bx00001xx;
      4'b0111 : {R,S} = 8'b00001xxx;
      4'b1111 : {R,S} = 8'b0001xxx0;
      4'b1110 : {R,S} = 8'b001xxx00;
      4'b1100 : {R,S} = 8'b01xxx000;
      4'b1000 : {R,S} = 8'b1xxx0000;
      default : {R,S} = 8'bxxxxxxxx;
        endcase
        end
        else begin
        case (q)
    4'b0000 : {R,S} = 8'b00001111;
      4'b0001 : {R,S} = 8'bxxx10000;
      4'b0010 : {R,S} = 8'bxx100001;
      4'b0011 : {R,S} = 8'bxx0100x0;
      4'b0100 : {R,S} = 8'bx1000011;
      4'b0101 : {R,S} = 8'bx0x10x00;
      4'b0110 : {R,S} = 8'bx0100x01;
      4'b0111 : {R,S} = 8'bx0010xx0;
      4'b1000 : {R,S} = 8'b10000111;
      4'b1001 : {R,S} = 8'b0xx1x000;
      4'b1010 : {R,S} = 8'b0x10x001;
      4'b1011 : {R,S} = 8'b0x01x0x0;
      4'b1100 : {R,S} = 8'b0100x011;
      4'b1101 : {R,S} = 8'b00x1xx00;
      4'b1110 : {R,S} = 8'b0010xx01;
      4'b1111 : {R,S} = 8'b0001xxx0;
      default : {R,S} = 8'bxxxxxxxx;
        endcase

        end
    end

end

endgenerate

// =========================
// JK-триггеры
// =========================

    rsff ff0 (.clk(clk), .enable(enable), .r(R[0]), .s(S[0]), .q(q[0]));
    rsff ff1 (.clk(clk), .enable(enable), .r(R[1]), .s(S[1]), .q(q[1]));
    rsff ff2 (.clk(clk), .enable(enable), .r(R[2]), .s(S[2]), .q(q[2]));
    rsff ff3 (.clk(clk), .enable(enable), .r(R[3]), .s(S[3]), .q(q[3]));

endmodule

module count_gray_v2_segment_driver (
    input  [3:0] counter,
    input        clock,
    input        enable_clock,
    output reg [7:0] indicator_select,
    output reg [7:0] segments
);
    reg [1:0] scan = 0;
    reg current_bit;

    always @(posedge clock) begin
        if (enable_clock)
            scan <= scan + 1'b1;
    end

    always @* begin
        indicator_select = 8'b1111_1111;
        current_bit = 1'b0;
case (scan)
            2'd0: begin
                indicator_select = 8'b1111_1110;
                current_bit = counter[3];
            end
            2'd1: begin
                indicator_select = 8'b1111_1101;
                current_bit = counter[2];
            end
            2'd2: begin
                indicator_select = 8'b1111_1011;
                current_bit = counter[1];
            end
            default: begin
                indicator_select = 8'b1111_0111;
                current_bit = counter[0];
            end
        endcase

        case (current_bit)
            1'b0: segments = 8'b1100_0000; // 0
            1'b1: segments = 8'b1111_1001; // 1
            default: segments = 8'b1111_1111;
        endcase
    end
endmodule

module counter_top (
    input        clock,
    input        dir_button,
    output [3:0] leds,
    output [7:0] indicator_select,
    output [7:0] segments
);
    wire clock_count_en;
    wire clock_ind_en;
    wire [3:0] c;

    // если кнопка на плате активная LOW, раскомментируй это:
    // wire dir = ~dir_button;

    // если кнопка активная HIGH:
    wire dir = dir_button;

    freq_divider #(.NUMBER(25_000_000)) fd_step1 (
        .clock(clock),
        .enable(clock_count_en)
    );

    freq_divider #(.NUMBER(5_000)) fd_step2 (
        .clock(clock),
        .enable(clock_ind_en)
    );

    count_gray_v2 #(.mode("REVERSE")) cnt (
        .clk(clock),
        .enable(clock_count_en),
        .dir(dir),
        .c(c)
    );

    assign leds = c;

    count_gray_v2_segment_driver segment_driver (
        .counter(c),
        .clock(clock),
        .enable_clock(clock_ind_en),
        .indicator_select(indicator_select),
        .segments(segments)
    );
endmodule
