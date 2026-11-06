`default_nettype none

module receiver #(
    parameter N = 8,
    parameter M = 326
) (
    input  wire         line,
    input  wire         clk,
    input  wire         rst,
    output reg          rx_done,
    output reg  [N-1:0] din
);

    localparam [1:0] IDLE    = 2'b00;
    localparam [1:0] START   = 2'b01;
    localparam [1:0] RECEIVE = 2'b10;
    localparam [1:0] STOP    = 2'b11;

    localparam BIT_INDEX_WIDTH = $clog2(N);

    reg [3:0] state_tick;
    reg [3:0] state_tick_next;

    reg [BIT_INDEX_WIDTH-1:0] d;
    reg [BIT_INDEX_WIDTH-1:0] d_next;

    reg [1:0] state;
    reg [1:0] state_next;

    reg rx_done_next;

    reg [N-1:0] din_next;

    wire tick_16;
    reg  rst_tick;

    counter #(
        .M(M)
    ) baud (
        .rst     (rst | rst_tick),
        .clk_main(clk),
        .tick    (tick_16)
    );

    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            d          <= {BIT_INDEX_WIDTH{1'b0}};
            state_tick <= 4'd0;
            din        <= {N{1'b0}};
            rx_done    <= 1'b0;
        end else begin
            state      <= state_next;
            d          <= d_next;
            state_tick <= state_tick_next;
            din        <= din_next;
            rx_done    <= rx_done_next;
        end
    end

    always @(*) begin
        state_next      = state;
        state_tick_next = state_tick;
        din_next        = din;
        rx_done_next    = 1'b0;
        d_next          = d;
        rst_tick        = 1'b0;

        case (state)
            IDLE: begin
                if (line == 1'b0) begin
                    state_tick_next = 4'd0;
                    rst_tick        = 1'b1;
                    state_next      = START;
                end
            end
            START: begin
                if (tick_16 == 1'b1) begin
                    if (state_tick == 4'd7) begin
                        state_tick_next = 4'd0;
                        if (line == 1'b0) begin
                            d_next     = {BIT_INDEX_WIDTH{1'b0}};
                            state_next = RECEIVE;
                        end else begin
                            state_next = IDLE;
                        end
                    end else begin
                        state_tick_next = state_tick + 4'd1;
                    end
                end
            end
            RECEIVE: begin
                if (tick_16 == 1'b1) begin
                    if (state_tick == 4'd15) begin
                        state_tick_next = 4'd0;
                        din_next[d]     = line;

                        if ({{(32-BIT_INDEX_WIDTH){1'b0}}, d} == (N - 1)) begin
                            d_next     = {BIT_INDEX_WIDTH{1'b0}};
                            state_next = STOP;
                        end else begin
                            d_next = d + 1'b1;
                        end
                    end else begin
                        state_tick_next = state_tick + 4'd1;
                    end
                end
            end
            STOP: begin
                if (tick_16 == 1'b1) begin
                    if (state_tick == 4'd15) begin
                        if (line == 1'b1) begin
                            rx_done_next = 1'b1;
                        end
                        state_next      = IDLE;
                        state_tick_next = 4'd0;
                    end else begin
                        state_tick_next = state_tick + 4'd1;
                    end
                end
            end
            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule
