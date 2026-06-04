`timescale 1ns/1ns

module TrafficLight_Berzarina
#(
    parameter ClockPeriod_ns  = 20,
    parameter RefreshTime_ns  = 200_000,

		parameter TIME_A = 52,
		parameter TIME_B = 3,
		parameter TIME_C = 25,
		parameter TIME_D = 3,
		parameter TIME_E = 19,
		parameter TIME_F = 2
)
(
    input  logic Clock,
    input  logic Reset,

    // Транспортный светофор I
    output logic T1_Red,
    output logic T1_Yellow,
    output logic T1_Green,

    // Транспортный светофор II
    output logic T2_Red,
    output logic T2_Yellow,
    output logic T2_Green,

    // Пешеходный светофор 1
    output logic P_Red,
    output logic P_Green,
	 
	 output logic P_Red_2,
    output logic P_Green_2,

    // Семисегментные индикаторы
    output logic [7:0] Indicators,
    output logic [7:0] Segments
);

    // ============================================================
    // Кодировка состояний
    // ============================================================

    typedef enum logic [2:0]
    {
        A = 3'd0,
        B = 3'd1,
        C = 3'd2,
        D = 3'd3,
        E = 3'd4,
        F = 3'd5
    } state_t;

    state_t State;
    state_t NextState;

    // ============================================================
    // Секундный счётчик текущей фазы
    // ============================================================

    logic [7:0] SecondsCounter;
    logic OneSecondEnable;
    logic ChangeState;

    assign ChangeState = (SecondsCounter == 0);

    // ============================================================
    // Переходы автомата
    // ============================================================

    always_comb begin
        NextState = State;

        if (ChangeState) begin
            case (State)
                A: NextState = B;
                B: NextState = C;
                C: NextState = D;
                D: NextState = E;
                E: NextState = F;
                F: NextState = A;
                default: NextState = A;
            endcase
        end
    end

    // ============================================================
    // Регистр состояния
    // Reset активный низким уровнем, как часто делают на Cyclone IV
    // ============================================================

    always_ff @(posedge Clock or negedge Reset) begin
        if (~Reset)
            State <= A;
        else if (OneSecondEnable)
            State <= NextState;
    end

    // ============================================================
    // Счётчик секунд фазы
    // ============================================================

    always_ff @(posedge Clock or negedge Reset) begin
        if (~Reset) begin
            SecondsCounter <= TIME_A;
        end
        else if (OneSecondEnable) begin
            if (ChangeState) begin
                case (NextState)
                    A: SecondsCounter <= TIME_A;
                    B: SecondsCounter <= TIME_B;
                    C: SecondsCounter <= TIME_C;
                    D: SecondsCounter <= TIME_D;
                    E: SecondsCounter <= TIME_E;
                    F: SecondsCounter <= TIME_F;
                    default: SecondsCounter <= TIME_A;
                endcase
            end
            else begin
                SecondsCounter <= SecondsCounter - 1'b1;
            end
        end
    end

    // ============================================================
    // Выходная логика автомата
    //
    // A: I Green,  II Red,    P Red
    // B: I Yellow, II Red,    P Red
    // C: I Red,    II Green,  P Red
    // D: I Red,    II Yellow, P Red
    // E: I Red,    II Red,    P Green
    // F: I Red,    II Red,    P Red
    // ============================================================

    logic T1_Red_int;
    logic T1_Yellow_int;
    logic T1_Green_int;

    logic T2_Red_int;
    logic T2_Yellow_int;
    logic T2_Green_int;

    logic P_Red_int;
    logic P_Green_int;

    always_comb begin
        T1_Red_int    = 1'b0;
        T1_Yellow_int = 1'b0;
        T1_Green_int  = 1'b0;

        T2_Red_int    = 1'b0;
        T2_Yellow_int = 1'b0;
        T2_Green_int  = 1'b0;

        P_Red_int     = 1'b0;
        P_Green_int   = 1'b0;

        case (State)
            A: begin
                T1_Green_int = 1'b1;
                T2_Red_int   = 1'b1;
                P_Red_int    = 1'b1;
            end

            B: begin
                T1_Yellow_int = 1'b1;
                T2_Red_int    = 1'b1;
                P_Red_int     = 1'b1;
            end

            C: begin
                T1_Red_int   = 1'b1;
                T2_Green_int = 1'b1;
                P_Red_int    = 1'b1;
            end

            D: begin
                T1_Red_int    = 1'b1;
                T2_Yellow_int = 1'b1;
                P_Red_int     = 1'b1;
            end

            E: begin
                T1_Red_int   = 1'b1;
                T2_Red_int   = 1'b1;
                P_Green_int  = 1'b1;
            end

            F: begin
                T1_Red_int  = 1'b1;
                T2_Red_int  = 1'b1;
                P_Red_int   = 1'b1;
            end

            default: begin
                T1_Red_int = 1'b1;
                T2_Red_int = 1'b1;
                P_Red_int  = 1'b1;
            end
        endcase
    end

    // ============================================================
    // Инверсия выходов
    //
    // На многих платах Cyclone IV светодиоды активны низким уровнем.
    // Поэтому здесь стоит инверсия.
    //
    // Если после прошивки всё будет гореть наоборот, нужно убрать "~".
    // ============================================================

    assign T1_Red    = ~T1_Red_int;
    assign T1_Yellow = ~T1_Yellow_int;
    assign T1_Green  = ~T1_Green_int;

    assign T2_Red    = ~T2_Red_int;
    assign T2_Yellow = ~T2_Yellow_int;
    assign T2_Green  = ~T2_Green_int;

    assign P_Red     = ~P_Red_int;
    assign P_Green   = ~P_Green_int;
	 
	 assign P_Red_2     = ~P_Red_int;
    assign P_Green_2   = ~P_Green_int;

    // ============================================================
    // Делитель частоты до 1 Гц
    //
    // ClockPeriod_ns = 20 нс
    // Частота Clock = 50 МГц
    // 1 секунда = 1_000_000_000 / 20 = 50_000_000 тактов
    // ============================================================

    localparam int SecondPeriod = 1_000_000_000 / ClockPeriod_ns;

    logic [clog2(SecondPeriod)-1:0] SecondDivider;

    assign OneSecondEnable = (SecondDivider == 0);

    always_ff @(posedge Clock or negedge Reset) begin
        if (~Reset) begin
            SecondDivider <= SecondPeriod - 1;
        end
        else begin
            if (OneSecondEnable)
                SecondDivider <= SecondPeriod - 1;
            else
                SecondDivider <= SecondDivider - 1'b1;
        end
    end

    // ============================================================
    // Вывод на семисегментные индикаторы
    //
    // Используем формат:
    //
    // [номер фазы] [пусто] [оставшееся время]
    //
    // Например:
    // фаза A, осталось 15 секунд -> "01    15"
    // фаза C, осталось 08 секунд -> "03    08"
    //
    // Цвета светофоров показываются светодиодами.
    // Сегменты показывают номер фазы и время фазы.
    // ============================================================

    logic [3:0] PhaseNumber;
    logic [7:0] PhaseBCD;
    logic [7:0] SecondsBCD;

    always_comb begin
        case (State)
            A: PhaseNumber = 4'd1;
            B: PhaseNumber = 4'd2;
            C: PhaseNumber = 4'd3;
            D: PhaseNumber = 4'd4;
            E: PhaseNumber = 4'd5;
            F: PhaseNumber = 4'd6;
            default: PhaseNumber = 4'd0;
        endcase
    end

    always_comb begin
        PhaseBCD   = Bin2BCD(PhaseNumber);
        SecondsBCD = Bin2BCD(SecondsCounter);
    end

    logic [2:0] IndicatorCounter;
    logic RefreshEnable;

    always_ff @(posedge Clock or negedge Reset) begin
        if (~Reset)
            IndicatorCounter <= 0;
        else if (RefreshEnable)
            IndicatorCounter <= IndicatorCounter + 1'b1;
    end

    always_comb begin
        Indicators = ~(8'b0000_0001 << IndicatorCounter);
        Segments   = 8'b1111_1111;

        case (IndicatorCounter)
            // Правые два разряда — секунды
            3'd0: Segments = BCD2ESC(SecondsBCD[3:0]);  // единицы секунд
            3'd1: Segments = BCD2ESC(SecondsBCD[7:4]);  // десятки секунд

            // Средние индикаторы пустые
            3'd2: Segments = 8'b1111_1111;
            3'd3: Segments = 8'b1111_1111;
            3'd4: Segments = 8'b1111_1111;
            3'd5: Segments = 8'b1111_1111;

            // Левые два разряда — номер фазы
            3'd6: Segments = BCD2ESC(PhaseBCD[3:0]);    // единицы номера фазы
            3'd7: Segments = BCD2ESC(PhaseBCD[7:4]);    // десятки номера фазы

            default: Segments = 8'b1111_1111;
        endcase
    end

    // ============================================================
    // Делитель частоты для динамической индикации
    // ============================================================

    localparam int RefreshPeriod = RefreshTime_ns / ClockPeriod_ns / 8;

    logic [clog2(RefreshPeriod)-1:0] RefreshDivider;

    assign RefreshEnable = (RefreshDivider == 0);

    always_ff @(posedge Clock or negedge Reset) begin
        if (~Reset) begin
            RefreshDivider <= RefreshPeriod - 1;
        end
        else begin
            if (RefreshEnable)
                RefreshDivider <= RefreshPeriod - 1;
            else
                RefreshDivider <= RefreshDivider - 1'b1;
        end
    end

    // ============================================================
    // Функция перевода BCD в код семисегментного индикатора
    //
    // Код рассчитан на индикаторы с активным низким уровнем:
    // 0 включает сегмент, 1 выключает.
    // ============================================================

    function automatic logic [7:0] BCD2ESC(input logic [3:0] value);
        case (value)
            4'd0: BCD2ESC = 8'b1100_0000;
            4'd1: BCD2ESC = 8'b1111_1001;
            4'd2: BCD2ESC = 8'b1010_0100;
            4'd3: BCD2ESC = 8'b1011_0000;
            4'd4: BCD2ESC = 8'b1001_1001;
            4'd5: BCD2ESC = 8'b1001_0010;
            4'd6: BCD2ESC = 8'b1000_0010;
            4'd7: BCD2ESC = 8'b1111_1000;
            4'd8: BCD2ESC = 8'b1000_0000;
            4'd9: BCD2ESC = 8'b1001_0000;
            default: BCD2ESC = 8'b1111_1111;
        endcase
    endfunction

    // ============================================================
    // Перевод числа 0...99 в BCD
    // ============================================================

    function automatic logic [7:0] Bin2BCD(input int value);
        int temp;
        begin
            temp = value;
            Bin2BCD[3:0] = temp % 10;
            temp = temp / 10;
            Bin2BCD[7:4] = temp % 10;
        end
    endfunction

    // ============================================================
    // Функция clog2
    // ============================================================

    function automatic int clog2(input int n);
        if (n < 1) begin
            clog2 = 1;
        end
        else begin
            for (clog2 = 0; n > 0; n = n >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

endmodule
