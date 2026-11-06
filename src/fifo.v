`default_nettype none

module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 8
) (
    input  wire             clk,
    input  wire             en_write,
    input  wire             en_read,
    input  wire             rst,
    input  wire [WIDTH-1:0] din,
    output wire             empty,
    output wire             full,
    output reg  [WIDTH-1:0] dout
);
    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    reg [ADDR_WIDTH:0] p_write;
    reg [ADDR_WIDTH:0] p_read;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            p_read  <= {(ADDR_WIDTH+1){1'b0}};
            p_write <= {(ADDR_WIDTH+1){1'b0}};
            dout    <= {WIDTH{1'b0}};
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {WIDTH{1'b0}};
            end
        end else begin
            if (!empty && en_read) begin
                dout   <= mem[p_read[ADDR_WIDTH-1:0]];
                p_read <= p_read + 1'b1;
            end
            if (!full && en_write) begin
                mem[p_write[ADDR_WIDTH-1:0]] <= din;
                p_write <= p_write + 1'b1;
            end
        end
    end

    assign full  = (p_write[ADDR_WIDTH-1:0] == p_read[ADDR_WIDTH-1:0]) && (p_write[ADDR_WIDTH] != p_read[ADDR_WIDTH]);
    assign empty = (p_write == p_read);

endmodule
