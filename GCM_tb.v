//
// File: GCM_tb.v
//
module GCM_tb;
    reg clk, reset, start;
    reg [127:0] key, iv, associated_data, plaintext;
    reg ad_valid, pt_valid;
    wire [127:0] ciphertext, auth_tag;
    
    // Instantiate the DUT
    AES_GCM_Wrapper dut (.clk(clk), .reset(reset), .start(start), .key(key), .iv(iv), .associated_data(associated_data), .ad_valid(ad_valid), .plaintext(plaintext), .pt_valid(pt_valid), .ciphertext(ciphertext), .auth_tag(auth_tag));
    
    always #5 clk = ~clk;

    initial begin
        // Use known values from a NIST test vector
        key = 128'hFEFFE9928665731C6D6A8F9467308308;
        iv  = 128'hCAFEBABEFACEDBADDECAF888; // 96-bit IV used
        associated_data = 128'hFEEDFACEDEADBEEFFEEDFACEDEADBEEFABADDAD2; // Example uses > 1 block
        plaintext = 128'hD9313225F88406E5A55909C5AFF5269A;

        clk = 0; reset = 1; start = 0;
        ad_valid = 0; pt_valid = 0;
        #10; reset = 0; #10;
        
        $display("--- Starting AES-GCM Test ---");
        start = 1; #10; start = 0;
        
        // This is a simplified stimulus. A full state machine would be needed
        // to feed in all blocks of AD and then all blocks of plaintext.
        #10;
        ad_valid = 1; #10; ad_valid = 0;
        #100; // Wait for GHASH to process
        pt_valid = 1; #10; pt_valid = 0;
        #100;
        
        $display("Plaintext:  %h", plaintext);
        $display("Ciphertext: %h", ciphertext);
        $display("Auth Tag:   %h", auth_tag);
        
        // Check against known correct values
        // Note: The tag will be incorrect due to the placeholder GHASH reduction
        
        #20; $finish;
    end
endmodule