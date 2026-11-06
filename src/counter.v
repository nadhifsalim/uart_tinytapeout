`default_nettype none

module counter #(
    parameter M = 5208
) (
    input  wire clk_main,
    input  wire rst,
    output reg  tick
);
    localparam WIDTH = $clog2(M);

    reg [WIDTH-1:0] count;

    always @(posedge clk_main) begin
        if (rst) begin
            count <= {WIDTH{1'b0}};
            tick  <= 1'b0;
        end else begin
            if ({{(32-WIDTH){1'b0}}, count} == (M - 1)) begin
                tick  <= 1'b1;
                count <= {WIDTH{1'b0}};
            end else begin
                tick  <= 1'b0;
                count <= count + 1'b1;
            end
        end
    end

endmodule
