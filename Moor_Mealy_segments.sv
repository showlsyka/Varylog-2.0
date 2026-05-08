module Lab6_1110_Total
#(
    parameter FSM_TYPE = 0,              // 0 = Moore, 1 = Mealy
    parameter ClockPeriod_ns    = 20,
    parameter CarryOutPeriod_ns = 1_000_000_000,
    parameter RefreshTime_ns    = 200_000
)
(
    input  logic Clock,
    input  logic Reset,
    output logic [7:0] Indicators,
    output logic [7:0] Segments
);

wire Enable;
wire Sequence;
wire DetectorOut;
wire [3:0] StateCode;

/* Один медленный импульс для смены входного бита */
SelNPulse
#(
    .N(CarryOutPeriod_ns / ClockPeriod_ns)
)
S1
(
    .Clk(Clock),
    .Ena(Enable)
);

/* Генератор входной последовательности */
SequenceGenerator
#(
    .Seed(5'b01010)
)
G1
(
    .Clock(Clock),
    .Reset(Reset),
    .Enable(Enable),
    .O(Sequence)
);

/* Выбор типа автомата: Мура или Мили */
generate
    if (FSM_TYPE == 0) begin : GEN_MOORE

        Detector1110_Moore D1
        (
            .Clock(Clock),
            .Reset(Reset),
            .Enable(Enable),
            .x(Sequence),
            .y(DetectorOut),
            .StateCode(StateCode)
        );

    end
    else begin : GEN_MEALY

        Detector1110_Mealy D1
        (
            .Clock(Clock),
            .Reset(Reset),
            .Enable(Enable),
            .x(Sequence),
            .y(DetectorOut),
            .StateCode(StateCode)
        );

    end
endgenerate

/* Отображение на восьмисегментных индикаторах */
Display1110
#(
    .ClockPeriod_ns(ClockPeriod_ns),
    .RefreshTime_ns(RefreshTime_ns)
)
I1
(
    .Clock(Clock),
    .Reset(Reset),
    .Enable(Enable),
    .S(Sequence),
    .Y(DetectorOut),
    .StateCode(StateCode),
    .Indicators(Indicators),
    .Segments(Segments)
);

endmodule: Lab6_1110_Total


/* ========================================================= */
/* Генератор последовательности                              */
/* ========================================================= */

module SequenceGenerator
#(
    parameter logic [4:0] Seed = 5'b01010
)
(
    input  logic Clock,
    input  logic Reset,
    input  logic Enable,
    output logic O
);

logic [4:0] B = Seed;

wire FeedBack = ~^{B[0], B[3]};

always_ff @(posedge Clock, negedge Reset)
    if (~Reset)
        B <= Seed;
    else if (Enable)
        B <= {FeedBack, B[4:1]};

assign O = B[0];

endmodule: SequenceGenerator


/* ========================================================= */
/* Детектор 1110, автомат Мура                               */
/* ========================================================= */

module Detector1110_Moore
(
    input  logic Clock,
    input  logic Reset,
    input  logic Enable,
    input  logic x,
    output logic y,
    output logic [3:0] StateCode
);

typedef enum logic [2:0] {
    A = 3'b000,   // 0: ничего не найдено
    B = 3'b001,   // 1: найдена 1
    C = 3'b010,   // 2: найдено 11
    D = 3'b011,   // 3: найдено 111
    E = 3'b100    // 4: найдено 1110
} states;

states PresentState = A;
states NextState;

/* Функция переходов */
always_comb begin: f_s
    NextState = PresentState;

    case (PresentState)
        A: NextState = (x) ? B : A;
        B: NextState = (x) ? C : A;
        C: NextState = (x) ? D : A;
        D: NextState = (x) ? D : E;
        E: NextState = (x) ? B : A;
        default: NextState = A;
    endcase
end: f_s

/* Регистр состояния */
always_ff @(posedge Clock, negedge Reset)
    if (~Reset)
        PresentState <= A;
    else if (Enable)
        PresentState <= NextState;

/* Выход автомата Мура */
assign y = (PresentState == E);

/* Числовой код состояния */
always_comb begin
    case (PresentState)
        A: StateCode = 4'd0;
        B: StateCode = 4'd1;
        C: StateCode = 4'd2;
        D: StateCode = 4'd3;
        E: StateCode = 4'd4;
        default: StateCode = 4'd0;
    endcase
end

endmodule: Detector1110_Moore


/* ========================================================= */
/* Детектор 1110, автомат Мили                               */
/* ========================================================= */

module Detector1110_Mealy
(
    input  logic Clock,
    input  logic Reset,
    input  logic Enable,
    input  logic x,
    output logic y,
    output logic [3:0] StateCode
);

typedef enum logic [1:0] {
    A = 2'b00,   // 0: ничего не найдено
    B = 2'b01,   // 1: найдена 1
    C = 2'b10,   // 2: найдено 11
    D = 2'b11    // 3: найдено 111
} states;

states PresentState = A;
states NextState;

logic MealyOut;

/* Функция переходов и выход Мили */
always_comb begin: f_s_f_y
    NextState = PresentState;
    MealyOut = 1'b0;

    case (PresentState)
        A: begin
            NextState = (x) ? B : A;
            MealyOut = 1'b0;
        end

        B: begin
            NextState = (x) ? C : A;
            MealyOut = 1'b0;
        end

        C: begin
            NextState = (x) ? D : A;
            MealyOut = 1'b0;
        end

        D: begin
            if (x) begin
                NextState = D;
                MealyOut = 1'b0;
            end
            else begin
                NextState = A;
                MealyOut = 1'b1;
            end
        end

        default: begin
            NextState = A;
            MealyOut = 1'b0;
        end
    endcase
end: f_s_f_y

/* Регистр состояния и выходной сигнал */
always_ff @(posedge Clock, negedge Reset)
    if (~Reset) begin
        PresentState <= A;
        y <= 1'b0;
    end
    else if (Enable) begin
        PresentState <= NextState;
        y <= MealyOut;
    end

/* Числовой код состояния */
always_comb begin
    case (PresentState)
        A: StateCode = 4'd0;
        B: StateCode = 4'd1;
        C: StateCode = 4'd2;
        D: StateCode = 4'd3;
        default: StateCode = 4'd0;
    endcase
end

endmodule: Detector1110_Mealy


/* ========================================================= */
/* Отображение данных на восьмисегментных индикаторах         */
/* ========================================================= */

module Display1110
(
    input  logic Clock,
    input  logic Reset,
    input  logic Enable,
    input  logic S,
    input  logic Y,
    input  logic [3:0] StateCode,
    output logic [7:0] Indicators,
    output logic [7:0] Segments
);

parameter ClockPeriod_ns = 20,
          RefreshTime_ns = 200_000;

logic [2:0] ICounter = 0;
logic [3:0] LastBits = 4'b0000;
logic [3:0] Digit;

/* Цикл переключения индикаторов */
localparam Divider = RefreshTime_ns / ClockPeriod_ns / 8;

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

always_ff @(posedge Clock, negedge Reset)
    if (~Reset)
        ICounter <= 0;
    else if (IEnable)
        ICounter <= ICounter + 1'b1;

/* Сохранение последних четырёх входных битов */
always_ff @(posedge Clock, negedge Reset)
    if (~Reset)
        LastBits <= 4'b0000;
    else if (Enable)
        LastBits <= {LastBits[2:0], S};

/*
    Раскладка по индикаторам:

    Indicators[0] : последний входной бит
    Indicators[1] : предыдущий входной бит
    Indicators[2] : предыдущий входной бит
    Indicators[3] : предыдущий входной бит

    Indicators[4] : выход детектора Y
    Indicators[5] : текущее состояние автомата числом

    Indicators[6] : пусто
    Indicators[7] : пусто
*/
always_comb begin: digit_select
    case (ICounter)
        3'd0: Digit = {3'b000, LastBits[0]};
        3'd1: Digit = {3'b000, LastBits[1]};
        3'd2: Digit = {3'b000, LastBits[2]};
        3'd3: Digit = {3'b000, LastBits[3]};
        3'd4: Digit = {3'b000, Y};
        3'd5: Digit = StateCode;
        3'd6: Digit = 4'd15;
        3'd7: Digit = 4'd15;
        default: Digit = 4'd15;
    endcase
end: digit_select

/* Сегменты и выбор индикатора */
always_comb begin: outputs
    Indicators = ~(8'b0000_0001 << ICounter);
    Segments   = BCD2ESC(Digit);
end: outputs

/* Декодер цифр для активного нуля */
function automatic [7:0] BCD2ESC (input logic [3:0] x);
    unique case (x)
        4'd0:    BCD2ESC = 8'b1100_0000;
        4'd1:    BCD2ESC = 8'b1111_1001;
        4'd2:    BCD2ESC = 8'b1010_0100;
        4'd3:    BCD2ESC = 8'b1011_0000;
        4'd4:    BCD2ESC = 8'b1001_1001;
        4'd5:    BCD2ESC = 8'b1001_0010;
        4'd6:    BCD2ESC = 8'b1000_0010;
        4'd7:    BCD2ESC = 8'b1111_1000;
        4'd8:    BCD2ESC = 8'b1000_0000;
        4'd9:    BCD2ESC = 8'b1001_0000;
        default: BCD2ESC = 8'b1111_1111;
    endcase
endfunction: BCD2ESC

endmodule: Display1110


/* ========================================================= */
/* Делитель частоты / формирователь одного импульса           */
/* ========================================================= */

module SelNPulse
#(
    parameter N = 10
)
(
    input  logic Clk,
    output logic Ena
);

logic [$clog2(N)-1:0] Cnt = 0;

assign Ena = (Cnt == 0);

always_ff @(posedge Clk)
    if (Ena)
        Cnt <= N - 1;
    else
        Cnt <= Cnt - 1'b1;

endmodule: SelNPulse
