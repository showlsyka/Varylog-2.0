module LFSR_Total
(
    input  logic Clock,
    input  logic Reset,
    output logic [7:0] Indicators,
    output logic [7:0] Segments
);
    parameter ClockPeriod_ns   = 20;
    parameter CarryOutPeriod_ns = 250_000_000;
    parameter RefreshTime_ns    = 200_000;

    wire Enable;
    wire Sequence;

    SelNPulse
    #(
        .N(CarryOutPeriod_ns / ClockPeriod_ns)
    )
    S1
    (
        .Clk(Clock),
        .Ena(Enable)
    );

    LFSR5
    #(
        .Seed(5'b01010)
    )
    L1
    (
        .Clock(Clock),
        .Enable(Enable),
        .Reset(Reset),
        .O(Sequence)
    );

    LFSR_Indicators
    #(
        .ClockPeriod_ns(ClockPeriod_ns),
        .RefreshTime_ns(RefreshTime_ns)
    )
    L2
    (
        .Clock(Clock),
        .Reset(Reset),
        .Enable(Enable),
        .S(Sequence),
        .Indicators(Indicators),
        .Segments(Segments)
    );

endmodule : LFSR_Total


module LFSR5
#(
    parameter logic [4:0] Seed = 5'b01010
)
(
    input  logic Clock,
    input  logic Enable,
    input  logic Reset,
    output logic O
);

    logic [4:0] B = Seed;
    wire FeedBack = ~^{B[0], B[3]};

    always_ff @(posedge Clock, negedge Reset) begin
        if (~Reset)
            B <= Seed;
        else if (Enable)
            B <= {FeedBack, B[4:1]};
    end

    assign O = B[0];

endmodule : LFSR5


module LFSR_Indicators
(
    input  logic Clock,
    input  logic Reset,
    input  logic Enable,
    input  logic S,
    output logic [7:0] Indicators,
    output logic [7:0] Segments
);
    parameter ClockPeriod_ns = 20;
    parameter RefreshTime_ns = 200_000;

    /* ============= Internal registers ============ */
    logic [2:0]  ICounter = 0;
    logic [31:0] BCD      = '1;

    /* ============== Indicators Cycle ============= */
    localparam integer Divider = RefreshTime_ns / ClockPeriod_ns / 8;
    wire IEnable;

    SelNPulse
    #(
        .N(Divider)
    )
    S1
    (
        .Clk(Clock),
        .Ena(IEnable)
    );

    always_ff @(posedge Clock) begin
        if (IEnable)
            ICounter <= ICounter + 1'b1;
    end

    /* =================== Data ==================== */
    logic PreviousEnable = 0;
    wire Shift;

    always_ff @(posedge Clock)
        PreviousEnable <= Enable;

    assign Shift = (~Enable & PreviousEnable);

    always_ff @(posedge Clock, negedge Reset) begin
        if (~Reset)
            BCD <= '1;
        else if (Shift)
            BCD <= {BCD[27:0], {3'b0, S}};
    end

    /* ================== Outputs ================== */
    always_comb begin : outputs
        Indicators = ~(8'b0000_0001 << ICounter);
        Segments   = BCD2ESC(BCD[4*ICounter +: 4]);
    end : outputs

    function automatic [7:0] BCD2ESC (input logic [3:0] x);
        unique case (x)
            4'd0:    BCD2ESC = 8'b1100_0000;
            4'd1:    BCD2ESC = 8'b1111_1001;
            default: BCD2ESC = 8'b1111_1111;
        endcase
    endfunction : BCD2ESC

endmodule : LFSR_Indicators


module SelNPulse
#(
    parameter integer N = 10
)
(
    input  logic Clk,
    output logic Ena
);
    logic [$clog2(N)-1:0] Cnt = 0;

    assign Ena = (Cnt == 0);

    always_ff @(posedge Clk) begin
        if (Ena)
            Cnt <= N - 1;
        else
            Cnt <= Cnt - 1'b1;
    end

endmodule : SelNPulse
