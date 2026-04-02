module SelectNPulse #(parameter N = 10) (
    input  logic Clock,
    output logic Pulse
);
    logic [$clog2(N)-1:0] Counter = 0;

    always_ff @(posedge Clock) begin
        if (Pulse)
            Counter <= 0;
        else
            Counter <= Counter + 1'b1;
    end

    assign Pulse = (Counter == N - 1);
endmodule



module Filter #(
    parameter Size = 4,
    parameter ClockPeriod_ns = 20,
    parameter FilterPeriod_ns = 1_000_000
)(
    input  logic Clock,
    input  logic [Size-1:0] I,
    output logic [Size-1:0] O
);
    localparam integer Number   = 4;
    localparam integer Prescale = FilterPeriod_ns / ClockPeriod_ns / (Number - 1);

    logic Enable;
    logic [Number-1:0] Register [Size-1:0];
    integer i;

    initial begin
        O = {Size{1'b1}};
        for (i = 0; i < Size; i = i + 1)
            Register[i] = {Number{1'b1}};
    end

    generate
        if (Prescale > 1)
            SelectNPulse #(.N(Prescale)) S1 (.Clock(Clock), .Pulse(Enable));
        else
            assign Enable = 1'b1;
    endgenerate

    always_ff @(posedge Clock) begin
        if (Enable) begin
            for (i = 0; i < Size; i = i + 1)
                Register[i] <= {Register[i][Number-2:0], I[i]};
        end
    end

    always_ff @(posedge Clock) begin
        if (Enable) begin
            for (i = 0; i < Size; i = i + 1) begin
                if ((Register[i] == {Number{1'b0}} && O[i] == 1'b1) ||
                    (Register[i] == {Number{1'b1}} && O[i] == 1'b0))
                    O[i] <= ~O[i];
            end
        end
    end
endmodule



module PulseGenerator #(
    parameter ClockPeriod_ns     = 20,
    parameter PauseInterval_ns   = 450_000_000,
    parameter RepeatsInterval_ns = 150_000_000
)(
    input  logic Clock,
    input  logic iUp,
    input  logic iDown,
    output logic oUp,
    output logic oDown
);
    localparam integer MaxPause    = PauseInterval_ns   / ClockPeriod_ns;
    localparam integer MaxRepeats  = RepeatsInterval_ns / ClockPeriod_ns;
    localparam integer MaxInterval = (MaxPause > MaxRepeats) ? MaxPause : MaxRepeats;
    localparam integer Size        = $clog2(MaxInterval + 1);

    typedef enum logic [1:0] {Idle, Pause, Repeats} state_t;

    logic [Size-1:0] Counter = 0;
    logic Pulse = 0;
    logic Pressed;
    state_t State = Idle;

    assign Pressed = ~(iUp & iDown);

    always_comb begin
        oUp   = Pulse & ~iUp;
        oDown = Pulse & ~iDown;
    end

    always_ff @(posedge Clock) begin
        if (Pressed) begin
            case (State)
                Idle: begin
                    State <= Pause;
                    Pulse <= 1'b1;
                end

                Pause: begin
                    if (Counter == MaxPause) begin
                        State   <= Repeats;
                        Pulse   <= 1'b1;
                        Counter <= 0;
                    end
                    else begin
                        Pulse   <= 1'b0;
                        Counter <= Counter + 1'b1;
                    end
                end

                Repeats: begin
                    if (Counter == MaxRepeats) begin
                        Pulse   <= 1'b1;
                        Counter <= 0;
                    end
                    else begin
                        Pulse   <= 1'b0;
                        Counter <= Counter + 1'b1;
                    end
                end
            endcase
        end
        else begin
            State   <= Idle;
            Counter <= 0;
            Pulse   <= 1'b0;
        end
    end
endmodule



module DataCounter #(
    parameter Size = 5,
    parameter Signed = 1   // 0 = No, 1 = Yes
)(
    input  logic Clock,
    input  logic Up,
    input  logic Reset,
    input  logic Down,
    input  logic Reverse,
    output logic [Size-1:0] Data
);
    localparam integer MAX_UNSIGNED = 2**Size - 1;
    localparam integer MAX_SIGNED   = 2**(Size-1) - 1;

    logic sign_bit;
    logic [Size-2:0] magnitude;

    always_comb begin
        sign_bit  = Data[Size-1];
        magnitude = Data[Size-2:0];
    end

    always_ff @(posedge Clock) begin
        if (!Reset) begin
            Data <= '0;
        end
        else if (!Signed) begin
            if (Up) begin
                if (Data < MAX_UNSIGNED)
                    Data <= Data + 1'b1;
            end
            else if (Down) begin
                if (Data != 0)
                    Data <= Data - 1'b1;
            end
        end
        else begin
            // sign-magnitude:
            // Data[Size-1]   = sign
            // Data[Size-2:0] = magnitude

            if (Reverse) begin
                if (Data != 0)
                    Data[Size-1] <= ~Data[Size-1];
            end

            else if (Up) begin
                if (sign_bit == 1'b0) begin
                    // +0 -> +1 -> ... -> +MAX
                    if (magnitude < MAX_SIGNED)
                        Data <= {1'b0, magnitude + 1'b1};
                end
                else begin
                    // -MAX ... -2 -> -1 -> 0
                    if (magnitude > 1)
                        Data <= {1'b1, magnitude - 1'b1};
                    else if (magnitude == 1)
                        Data <= '0;
                end
            end

            else if (Down) begin
                if (sign_bit == 1'b0) begin
                    // +MAX ... +1 -> 0 -> -1
                    if (magnitude > 0)
                        Data <= {1'b0, magnitude - 1'b1};
                    else
                        Data <= {1'b1, {{(Size-2){1'b0}}, 1'b1}}; // 0 -> -1
                end
                else begin
                    // -1 -> -2 -> ... -> -MAX
                    if (magnitude < MAX_SIGNED)
                        Data <= {1'b1, magnitude + 1'b1};
                end
            end
        end
    end
endmodule



module DataGenerator #(
    parameter Size               = 5,
    parameter Signed             = 1,
    parameter ClockPeriod_ns     = 20,
    parameter FilterPeriod_ns    = 1_000_000,
    parameter PauseInterval_ns   = 450_000_000,
    parameter RepeatsInterval_ns = 150_000_000
)(
    input  logic Clock,
    input  logic Button_Up,
    input  logic Button_Reset,
    input  logic Button_Down,
    input  logic Button_Reverse,
    output logic [Size-1:0] Data
);
    logic FilteredUp, FilteredReset, FilteredDown, FilteredReverse;
    logic Up, Down;
    logic ReversePulse;
    logic ReverseDelay = 1'b1;

    Filter #(
        .Size(4),
        .ClockPeriod_ns(ClockPeriod_ns),
        .FilterPeriod_ns(FilterPeriod_ns)
    ) F1 (
        .Clock(Clock),
        .I({Button_Up, Button_Reset, Button_Down, Button_Reverse}),
        .O({FilteredUp, FilteredReset, FilteredDown, FilteredReverse})
    );

    PulseGenerator #(
        .ClockPeriod_ns(ClockPeriod_ns),
        .PauseInterval_ns(PauseInterval_ns),
        .RepeatsInterval_ns(RepeatsInterval_ns)
    ) PG1 (
        .Clock(Clock),
        .iUp(FilteredUp),
        .iDown(FilteredDown),
        .oUp(Up),
        .oDown(Down)
    );

    always_ff @(posedge Clock) begin
        ReverseDelay <= FilteredReverse;
    end

    assign ReversePulse = ReverseDelay & ~FilteredReverse;

    DataCounter #(
        .Size(Size),
        .Signed(Signed)
    ) DCnt1 (
        .Clock(Clock),
        .Up(Up),
        .Reset(FilteredReset),
        .Down(Down),
        .Reverse(ReversePulse),
        .Data(Data)
    );
endmodule



module Data2Segments #(
    parameter Size = 4,
    parameter Signed = 1,
    parameter ClockPeriod_ns = 20,
    parameter RefreshTime_ns = 20_000
)(
    input  logic Clock,
    input  logic [Size-1:0] Data,
    output logic [((Signed==0)?clog10_func(1<<Size):(clog10_func(1<<(Size-1))+1))-1:0] Indicators,
    output logic [7:0] Segments
);
    function automatic integer clog10_func(input integer n);
        integer t;
        begin
            if (n < 1) clog10_func = 1;
            else begin
                t = 0;
                while (n > 0) begin
                    t = t + 1;
                    n = n / 10;
                end
                clog10_func = t;
            end
        end
    endfunction

    function automatic [31:0] Bin2BCD_func(input [31:0] B, input integer Digits4);
        integer i;
        reg [31:0] tmp;
        reg [31:0] X;
        begin
            if (Digits4 == 4)
                Bin2BCD_func = B;
            else begin
                X = B;
                tmp = 0;
                for (i = 0; i < Digits4; i = i + 4) begin
                    tmp[i +: 4] = X % 10;
                    X = X / 10;
                end
                Bin2BCD_func = tmp;
            end
        end
    endfunction

    function automatic [7:0] BCD2ESC_func(input [3:0] x);
        begin
            case (x)
                4'd0  : BCD2ESC_func = 8'b1100_0000;
                4'd1  : BCD2ESC_func = 8'b1111_1001;
                4'd2  : BCD2ESC_func = 8'b1010_0100;
                4'd3  : BCD2ESC_func = 8'b1011_0000;
                4'd4  : BCD2ESC_func = 8'b1001_1001;
                4'd5  : BCD2ESC_func = 8'b1001_0010;
                4'd6  : BCD2ESC_func = 8'b1000_0010;
                4'd7  : BCD2ESC_func = 8'b1111_1000;
                4'd8  : BCD2ESC_func = 8'b1000_0000;
                4'd9  : BCD2ESC_func = 8'b1001_0000;
                4'ha  : BCD2ESC_func = 8'b1011_1111; // minus
                default: BCD2ESC_func = 8'b1111_1111; // empty
            endcase
        end
    endfunction

    localparam integer ISize        = (Signed == 0) ? clog10_func(1<<Size)
                                                    : (clog10_func(1<<(Size-1)) + 1);
    localparam integer BCDSize      = 4*ISize;
    localparam integer Prescale     = RefreshTime_ns / ClockPeriod_ns / ISize;
    localparam integer ICounterSize = (ISize > 1) ? $clog2(ISize) : 1;

    logic [BCDSize-1:0] BCD;
    logic [ICounterSize-1:0] ICounter = 0;
    logic Enable;

    generate
        if (ISize > 1)
            SelectNPulse #(.N(Prescale)) S1 (.Clock(Clock), .Pulse(Enable));
        else
            assign Enable = 1'b1;
    endgenerate

    always_comb begin
        if (Signed == 0) begin
            BCD = BCDSize'(Bin2BCD_func(Data, BCDSize));
        end
        else begin
            BCD = {
                (Data[Size-1] == 1'b0) ? 4'hf : 4'ha,
                (BCDSize-4)'(Bin2BCD_func(Data[Size-2:0], BCDSize-4))
            };
        end
    end

    always_ff @(posedge Clock) begin
        if (Enable) begin
            if (ICounter == ISize - 1)
                ICounter <= 0;
            else
                ICounter <= ICounter + 1'b1;
        end
    end

    always_comb begin
        if (ISize > 1) begin
            Indicators = ~(1'b1 << ICounter);
            Segments   = BCD2ESC_func(BCD[4*ICounter +: 4]);
        end
        else begin
            Indicators = 1'b0;
            Segments   = BCD2ESC_func(BCD[3:0]);
        end
    end
endmodule



module DGandD2S #(
    parameter Size               = 5,
    parameter Signed             = 1,
    parameter ClockPeriod_ns     = 20,
    parameter FilterPeriod_ns    = 1_000_000,
    parameter PauseInterval_ns   = 450_000_000,
    parameter RepeatsInterval_ns = 150_000_000,
    parameter RefreshTime_ns     = 200_000
)(
    input  logic Clock,
    input  logic Button_Up,
    input  logic Button_Reset,
    input  logic Button_Down,
    input  logic Button_Reverse,
    output logic [((Signed==0)?clog10_func_top(1<<Size):(clog10_func_top(1<<(Size-1))+1))-1:0] Indicators,
    output logic [7:0] Segments
);
    function automatic integer clog10_func_top(input integer n);
        integer t;
        begin
            if (n < 1) clog10_func_top = 1;
            else begin
                t = 0;
                while (n > 0) begin
                    t = t + 1;
                    n = n / 10;
                end
                clog10_func_top = t;
            end
        end
    endfunction

    logic [Size-1:0] Data;

    DataGenerator #(
        .Size(Size),
        .Signed(Signed),
        .ClockPeriod_ns(ClockPeriod_ns),
        .FilterPeriod_ns(FilterPeriod_ns),
        .PauseInterval_ns(PauseInterval_ns),
        .RepeatsInterval_ns(RepeatsInterval_ns)
    ) B1 (
        .Clock(Clock),
        .Button_Up(Button_Up),
        .Button_Reset(Button_Reset),
        .Button_Down(Button_Down),
        .Button_Reverse(Button_Reverse),
        .Data(Data)
    );

    Data2Segments #(
        .Size(Size),
        .Signed(Signed),
        .ClockPeriod_ns(ClockPeriod_ns),
        .RefreshTime_ns(RefreshTime_ns)
    ) B2 (
        .Clock(Clock),
        .Data(Data),
        .Indicators(Indicators),
        .Segments(Segments)
    );
endmodule
