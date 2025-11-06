module AES_CBC_Wrapper (
    input clk,
    input reset,
    input start,                  // Begin a new message
    input encrypt_n_decrypt,      // 1 for encrypt, 0 for decrypt
    input [127:0] key,            // AES key
    input [127:0] iv,             // Initialization Vector
    input [127:0] data_in,        // Data block to process
    input data_valid,             // Signals that data_in is valid
    output reg [127:0] data_out,
    output reg ready              // Signals that the module is ready
);

    wire [127:0] encrypt_out;
    wire [127:0] decrypt_out;
    wire [127:0] core_input;
    reg [127:0] feedback_reg;
    
    // Instantiate your MODIFIED AES cores
    AES_Encrypt_checksum #(.N(128)) aes_encrypt_core (.in(core_input), .key(key), .out(encrypt_out));
    AES_Decrypt_checksum #(.N(128)) aes_decrypt_core (.in(data_in), .key(key), .out(decrypt_out));

    assign core_input = data_in ^ feedback_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            feedback_reg <= 128'b0;
            ready <= 1'b1;
            data_out <= 128'b0;
        end else begin
            if (start) begin
                feedback_reg <= iv;
                ready <= 1'b1;
            end else if (data_valid && ready) begin
                ready <= 1'b0;
                if (encrypt_n_decrypt) begin
                    data_out <= encrypt_out;
                    feedback_reg <= encrypt_out;
                end else begin
                    data_out <= decrypt_out ^ feedback_reg;
                    feedback_reg <= data_in;
                end
                ready <= 1'b1;
            end
        end
    end
endmodule