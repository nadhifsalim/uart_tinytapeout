`default_nettype none

module transmitter #(
    parameter N = 8,
    parameter M = 5208
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         tx_ready,
    input  wire [N-1:0] dout,
    output reg          line,
    output wire         tx_busy
);

    localparam [1:0] IDLE     = 2'd0;
    localparam [1:0] START    = 2'd1;
    localparam [1:0] TRANSMIT = 2'd2;
    localparam [1:0] STOP     = 2'd3;

    localparam BIT_INDEX_WIDTH = $clog2(N);

    wire tick;
    reg  rst_tick;

    counter #(
        .M(M)
    ) baud (
        .clk_main(clk),
        .tick    (tick),
        .rst     (rst | rst_tick)
    );

    reg [1:0] state;
    reg [1:0] state_next;

    reg [BIT_INDEX_WIDTH-1:0] d;
    reg [BIT_INDEX_WIDTH-1:0] d_next;

    reg [N-1:0] data;
    reg [N-1:0] data_next;

    reg tx_ready_latch;

    reg line_next;

    always @(posedge clk) begin
        if (rst) begin
            line           <= 1'b1;
            state          <= IDLE;
            d              <= {BIT_INDEX_WIDTH{1'b0}};
            tx_ready_latch <= 1'b0;
            data           <= {N{1'b0}};
        end else begin
            line           <= line_next;
            state          <= state_next;
            d              <= d_next;
            tx_ready_latch <= tx_ready;
            data           <= data_next;
        end
    end

    always @(*) begin
        state_next = state;
        line_next  = line;
        d_next     = d;
        data_next  = data;
        rst_tick   = 1'b0;

        case (state)
            IDLE: begin
                line_next = 1'b1;
                if (tx_ready_latch == 1'b1) begin
                    line_next  = 1'b0;
                    rst_tick   = 1'b1;
                    state_next = START;
                    d_next     = {BIT_INDEX_WIDTH{1'b0}};
                    data_next  = dout;
                end
            end
            START: begin
                if (tick == 1'b1) begin
                    line_next  = data[d];
                    d_next     = d + 1'b1;
                    state_next = TRANSMIT;
                end
            end
            TRANSMIT: begin
                if (tick == 1'b1) begin
                    line_next = data[d];
                    if ({{(32-BIT_INDEX_WIDTH){1'b0}}, d} == (N - 1)) begin
                        state_next = STOP;
                    end else begin
                        d_next = d + 1'b1;
                    end
                end
            end
            STOP: begin
                if (tick == 1'b1) begin
                    line_next  = 1'b1;
                    state_next = IDLE;
                end
            end
            default: begin
                state_next = IDLE;
            end
        endcase
    end

    assign tx_busy = (state != IDLE);

endmodule
