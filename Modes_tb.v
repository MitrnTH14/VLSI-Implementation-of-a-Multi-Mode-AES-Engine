//
// File: Modes_tb.v (Final Corrected Version)
//
module Modes_tb;
    reg clk, reset, start, data_valid;
    reg [127:0] key, iv, plaintext, cbc_data_in, ctr_data_in;
    reg [127:0] initial_counter_block;
    reg encrypt_n_decrypt;
    wire [127:0] cbc_data_out, ctr_data_out;
    wire cbc_ready, ctr_ready;

    localparam [127:0] EXPECTED_CTR_CIPHERTEXT = 128'h874d6191b620e3261bef6864990db6ce;
    
    // --- FIX: Add a register to store the encryption result ---
    reg [127:0] temp_ctr_ciphertext;

    // Instantiate CBC Wrapper (unchanged)
    AES_CBC_Wrapper cbc_dut (.clk(clk), .reset(reset), .start(start), .encrypt_n_decrypt(encrypt_n_decrypt), .key(key), .iv(iv), .data_in(cbc_data_in), .data_valid(data_valid), .data_out(cbc_data_out), .ready(cbc_ready));

    // Instantiate CTR Wrapper (unchanged)
    AES_CTR_Wrapper ctr_dut (.clk(clk), .reset(reset), .start(start), .key(key), .initial_counter_block(initial_counter_block), .data_in(ctr_data_in), .data_valid(data_valid), .data_out(ctr_data_out), .ready(ctr_ready));

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1; start = 0; data_valid = 0;
        key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        iv  = 128'h000102030405060708090a0b0c0d0e0f;
        plaintext = 128'h6bc1bee22e409f96e93d7e117393172a;
        initial_counter_block = 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;
        
        #10; reset = 0; #10;

        // --- Test CBC Mode ---
        $display("\n--- Testing CBC Mode ---");
        // ... (This part is correct and remains the same) ...
        start = 1; #10; start = 0; encrypt_n_decrypt = 1; cbc_data_in = plaintext; data_valid = 1; #10; data_valid = 0; wait(cbc_ready); #2;
        start = 1; #10; start = 0; encrypt_n_decrypt = 0; cbc_data_in = cbc_data_out; data_valid = 1; #10; data_valid = 0; wait(cbc_ready); #2;
        if (cbc_data_out == plaintext) $display("SUCCESS: CBC test passed!"); else $display("FAILURE: CBC test failed!");


        // --- Test CTR Mode ---
        $display("\n--- Testing CTR Mode ---");
        // --- Step 1: Encrypt ---
        start = 1; #10; start = 0;
        ctr_data_in = plaintext;
        data_valid = 1; #10; data_valid = 0;
        wait(ctr_ready); 
        #2; 
        
        // --- FIX: Save the encryption result immediately ---
        temp_ctr_ciphertext = ctr_data_out;
        $display("Plaintext:           %h", plaintext);
        $display("Generated Ciphertext:  %h", temp_ctr_ciphertext);
        $display("Expected Ciphertext:   %h", EXPECTED_CTR_CIPHERTEXT);

        // --- Step 2: Verify Encryption ---
        if (temp_ctr_ciphertext == EXPECTED_CTR_CIPHERTEXT) $display("SUCCESS: VERIFIED - CTR ciphertext matches official NIST vector!");
        else $display("FAILURE: ERROR - CTR ciphertext does NOT match official NIST vector!");

        // --- Step 3: Decrypt ---
        start = 1; #10; start = 0;
        ctr_data_in = temp_ctr_ciphertext; // Use the SAVED ciphertext for decryption
        data_valid = 1; #10; data_valid = 0;
        wait(ctr_ready);
        #2;
        
        // --- Step 4: Verify Decryption ---
        $display("Decrypted Plaintext:   %h", ctr_data_out);
        if (ctr_data_out == plaintext) $display("SUCCESS: CTR decryption recovered the original plaintext!");
        else $display("FAILURE: CTR decryption failed!");
        
        #20; $finish;
    end
endmodule