//
// File: AES_Encrypt_checksum.v (Modified from your original)
//
module AES_Encrypt_checksum#(parameter N=128,parameter Nr=10,parameter Nk=4)(
    input [127:0] in,
    input [N-1:0] key,
    output [127:0] out,
    output reg [31:0] state_checksum // New output
);

    wire [(128*(Nr+1))-1 :0] fullkeys;
    wire [127:0] states [Nr+1:0] ;
    wire [127:0] afterSubBytes;
    wire [127:0] afterShiftRows;

    keyExpansion #(Nk,Nr) ke (key,fullkeys);
    addRoundKey addrk1 (in,states[0],fullkeys[((128*(Nr+1))-1)-:128]);

    genvar i;
    generate
        for(i=1; i<Nr ;i=i+1)begin : loop
            encryptRound er(states[i-1],fullkeys[(((128*(Nr+1))-1)-128*i)-:128],states[i]);
        end
        subBytes sb(states[Nr-1],afterSubBytes);
        shiftRows sr(afterSubBytes,afterShiftRows);
        addRoundKey addrk2(afterShiftRows,states[Nr],fullkeys[127:0]);
        assign out=states[Nr];
    endgenerate
    
    // --- Added Checksum Logic ---
    integer j;
    always @(*) begin
        state_checksum = 32'b0;
        for (j=0; j <= Nr; j=j+1) begin
            state_checksum = state_checksum ^ states[j][127:96] ^ states[j][95:64] ^ states[j][63:32] ^ states[j][31:0];
        end
    end

endmodule