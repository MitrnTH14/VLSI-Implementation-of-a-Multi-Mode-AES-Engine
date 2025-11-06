//
// File: GHASH_Module.v (Final Syntax Correction 2)
//
module GHASH_Module (
    input clk,
    input reset,
    input start,
    input [127:0] hash_key_H,
    input [127:0] data_in,
    input data_valid,
    output [127:0] hash_out,
    output reg ready
);

    reg [127:0] Y; // The accumulator register

    wire [127:0] next_Y;
    wire [254:0] mult_result;
    wire [127:0] reduced_result;
    
    // --- FIX: Replaced illegal XOR reduction with a standard combinational 'for' loop ---
    reg [254:0] temp_mult_result;
    wire [127:0] product_input = Y ^ data_in;
    integer i;

    always @(*) begin
        temp_mult_result = 255'b0;
        for (i = 0; i < 128; i = i + 1) begin
            if (product_input[i]) begin
                temp_mult_result = temp_mult_result ^ ({127'b0, hash_key_H} << i);
            end
        end
    end
    assign mult_result = temp_mult_result;
    // --- END FIX ---


    // --- Combinational GF(2^128) Reduction ---
    // Reduces the 255-bit multiplication result to 128 bits.
    assign reduced_result = {mult_result[127:0]}
                          ^ {1'b0, mult_result[254:128]}
                          ^ {2'b0, mult_result[253:128], 1'b0}
                          ^ {7'b0, mult_result[248:128], 6'b0}
                          ^ {8'b0, mult_result[247:128], 7'b0}
                          ^ {1'b0, mult_result[254], 126'b0}
                          ^ {2'b0, mult_result[253], 1'b0, 125'b0}
                          ^ {7'b0, mult_result[248], 6'b0, 121'b0}
                          ^ {8'b0, mult_result[247], 7'b0, 120'b0};

    assign next_Y = reduced_result;
    assign hash_out = Y;

    // --- Sequential Logic to Latch the Result ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            Y <= 128'b0;
            ready <= 1'b1;
        end else begin
            if (start) begin
                Y <= 128'b0;
                ready <= 1'b1;
            end else if (ready && data_valid) begin
                Y <= next_Y;
                ready <= 1'b1;
            end else begin
                ready <= 1'b1;
            end
        end
    end

endmodule