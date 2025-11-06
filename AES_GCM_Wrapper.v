//
// File: AES_GCM_Wrapper.v
// Description: Top-level wrapper for a full AES-GCM implementation.
//
module AES_GCM_Wrapper (
    input clk,
    input reset,
    input start,
    input [127:0] key,
    input [127:0] iv,             // GCM uses a 96-bit IV, padded to 128
    input [127:0] associated_data, // The AD to be authenticated
    input ad_valid,
    input [127:0] plaintext,
    input pt_valid,
    output reg [127:0] ciphertext,
    output reg [127:0] auth_tag
);

    wire [127:0] hash_key_H;
    wire [127:0] initial_counter;
    wire [127:0] encrypted_counter;
    wire [127:0] ghash_out;
    
    // --- Step 1: Generate the Hash Key H ---
    // H = E(K, 0^128)
    AES_Encrypt_checksum #(.N(128)) hash_key_gen (.in(128'b0), .key(key), .out(hash_key_H));

    // --- Step 2: Prepare the Initial Counter for CTR mode ---
    // Y0 = IV || 31'b0 || 1'b1
    assign initial_counter = {iv[95:0], 31'b0, 1'b1};

    // --- Step 3: Instantiate the CTR Encryption part ---
    // (Using a simplified version of your CTR wrapper logic)
    reg [127:0] ctr_counter;
    always @(posedge clk) begin
        if (start) ctr_counter <= initial_counter;
        else if (pt_valid) ctr_counter <= ctr_counter + 1;
    end
    AES_Encrypt_checksum #(.N(128)) ctr_encrypt (.in(ctr_counter), .key(key), .out(encrypted_counter));
    always @(*) begin
        if(pt_valid) ciphertext = plaintext ^ encrypted_counter;
        else ciphertext = 128'b0;
    end

    // --- Step 4: Instantiate the GHASH part ---
    // This state machine would be more complex to handle both AD and ciphertext blocks
    GHASH_Module ghash_inst (
        .clk(clk), .reset(reset), .start(start),
        .hash_key_H(hash_key_H),
        .data_in(ad_valid ? associated_data : ciphertext),
        .data_valid(ad_valid || pt_valid),
        .hash_out(ghash_out)
        // .ready() signal would be used by a state machine
    );
    
    // --- Step 5: Calculate the final Authentication Tag ---
    // T = Ghash_out XOR E(K, Y0)
    wire [127:0] encrypted_initial_counter;
    AES_Encrypt_checksum #(.N(128)) tag_encrypt (.in(initial_counter), .key(key), .out(encrypted_initial_counter));
    always @(*) begin
        // This should be triggered at the very end of the message
        auth_tag = ghash_out ^ encrypted_initial_counter;
    end

endmodule