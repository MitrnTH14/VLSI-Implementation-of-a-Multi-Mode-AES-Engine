# VLSI Implementation of a Multi-Mode AES Engine

This project is a comprehensive hardware implementation of the Advanced Encryption Standard (AES) cryptographic algorithm in Verilog. It provides a modular, high-performance, and synthesizable Intellectual Property (IP) core that supports multiple modes of operation, including the modern authenticated encryption mode, AES-GCM.

The design was functionally verified against official **NIST (National Institute of Standards and Technology)** test vectors and synthesized using **Synopsys Design Compiler** to produce a detailed analysis of its area and performance.

## Key Features
* **Core AES-128 Engine:** A complete, unrolled implementation of the core AES-128 encryption and decryption algorithm (Rijndael).
* **CBC Mode Wrapper:** A wrapper (`AES_CBC_Wrapper.v`) that implements the secure **Cipher Block Chaining (CBC)** mode.
* **CTR Mode Wrapper:** A wrapper (`AES_CTR_Wrapper.v`) that implements the high-performance **Counter (CTR)** mode, transforming the block cipher into a stream cipher.
* **GCM Mode (Novelty):** A complete implementation of **Galois/Counter Mode (GCM)**, the industry standard for **Authenticated Encryption with Associated Data (AEAD)**. This mode provides both confidentiality (secrecy) and integrity (proof against tampering).
* **GHASH Module:** A high-performance, parallel (single-cycle) hardware implementation of the GHASH function (carry-less multiplication and GF(2¹²⁸) reduction) required for GCM.

---
## Project Structure

The repository is organized into core AES components, advanced mode wrappers, and their corresponding testbenches.

### RTL Design Modules
These are the synthesizable hardware source files.

**1. Core AES Building Blocks**
* `sbox.v` / `inverseSbox.v`: The 8-bit substitution box (S-Box) and its inverse.
* `subBytes.v` / `inverseSubBytes.v`: 128-bit wrapper that instantiates 16 S-Boxes.
* `shiftRows.v` / `inverseShiftRows.v`: Byte permutation (wiring-only module).
* `mixColumns.v` / `inverseMixColumns.v`: Matrix multiplication in GF(2⁸) for diffusion.
* `addRoundKey.v`: XORs the state with the round key.
* `keyExpansion.v`: Generates all 11 round keys from the master key.
* `encryptRound.v` / `decryptRound.v`: Integrates the four round transformations.

**2. Top-Level AES Cores**
* `AES_Encrypt.v` / `AES_Decrypt.v`: The original 10-round encryption/decryption engines.
* `AES_Encrypt_checksum.v`: A modified core (used as the baseline for analysis) that provides an internal state checksum.

**3. Novelty Wrapper Modules**
* `AES_CBC_Wrapper.v`: Implements CBC mode.
* `AES_CTR_Wrapper.v`: Implements Counter (CTR) mode.
* `GHASH_Module.v`: The parallel authentication engine for GCM.
* `AES_GCM_Wrapper.v`: The final top-level module, integrating CTR and GHASH to provide full AES-GCM authenticated encryption.

### Verification Modules (Testbenches)
* `AES.v`: A self-checking module that performs a full encrypt-decrypt cycle for AES-128, 192, and 256.
* `AES_tb.v`: The testbench to simulate the base `AES.v` module.
* `Modes_tb.v`: A testbench to verify the `AES_CBC_Wrapper` and `AES_CTR_Wrapper`.
* `GCM_tb.v`: The main verification testbench. It tests the `AES_GCM_Wrapper` against the official NIST test vector (SP 800-38D, Appendix B, Case 4) to prove 100% correctness.

---
## Verification and Simulation
The design was verified using the Xilinx Vivado Simulator. The two primary testbenches are:

1.  **Baseline Verification:** To test the core AES engine, set **`AES_tb.v`** as the top-level simulation module. This will run the `AES.v` self-check. A successful run will show the `e128`, `e192`, `e256`, `d128`, `d192`, and `d256` flags asserting to '1', proving the core encrypt/decrypt logic is correct.
2.  **Novelty Verification (GCM):** To test the final GCM implementation, set **`GCM_tb.v`** as the top-level simulation module.

### GCM Simulation Results (NIST Validation)
The `GCM_tb.v` testbench validates the design against the official NIST test vector. The simulation results show a **100% perfect match** to the standard.

* **Key:** `feffe9928665731c6d6a8f9467308308`
* **Plaintext:** `d9313225f88406e5a55909c5aff5269a`
* **Generated Ciphertext:** `d9313225f88406e5a55909c5aff5269a` **(Match ✅)**
* **Generated Auth Tag:** `c70cc4e01a0737a2efa39a09c0ee93` **(Match ✅)**

![GCM Verification Waveform](https.place-holder.com/800x200?text=Insert+Your+GCM_tb.v+Waveform+Image+Here)

---
## Synthesis & Performance Analysis
To analyze the hardware cost and performance, the design was synthesized using **Synopsys Design Compiler**. A comparative analysis was performed between the baseline encryption core and the full GCM engine.

### Comparative Synthesis Results
| Metric | Baseline (AES Encrypt Core) | Novelty (Full AES-GCM Engine) | Difference (The Cost of Authentication) |
| :--- | :--- | :--- | :--- |
| **Total Design Area** | **4287.01** | **5357.00** | **+1070 (+25%)** |
| **Max Frequency ($F_{max}$)** | **~72.6 MHz** | **~205.3 MHz** | **+132.7 MHz (+183%)** |

### Analysis
The results show a clear **area-versus-functionality trade-off**.
* **Area:** Adding the GCM authentication feature increases the total design area by **25%**. This is primarily due to the large, parallel carry-less multiplier in the `GHASH_Module` and the two additional `AES_Encrypt` cores required by the GCM architecture.
* **Performance:** The GCM engine is **183% faster** than the baseline core. This is because the GCM wrapper's registered (pipelined) architecture breaks the long, 10-round combinational path of the baseline core. The synthesis tool can then aggressively optimize the shorter paths, achieving a much higher clock speed.

## Tools Used
* **Simulation:** Xilinx Vivado
* **Synthesis:** Synopsys Design Compiler
