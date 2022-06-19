module bitcoin_hash (input logic        clk, reset_n, start,
                     input logic [15:0] message_addr, output_addr,
                    output logic        done, mem_clk, mem_we,
                    output logic [15:0] mem_addr,
                    output logic [31:0] mem_write_data,
                     input logic [31:0] mem_read_data);

parameter num_nonces = 16;

// Local variables
logic   [31:0] w_bit[64];
logic 	[31:0] message_bit_full[32];

logic 	[15:0] cur_addr; 
logic 	[31:0] cur_write_data;
logic 	[15:0] offset_bit;

logic          cur_we; 
logic          done_sha[num_nonces];
logic   	   start_bit; 


logic   [31:0] h[16][0:7]; // hash output form sha256

logic   [31:0] fhash[0:7]; // initial hash
logic   [31:0] hash_bit[16][0:7]; // hash input to sha256
logic 	[31:0] message_bit[16][0:15]; // message input to sha256

//INSTANTIATE 16 SHA256 MODULES
simplified_sha256 block0 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[0]),
	.output_hash(h[0]),
	.input_hash(hash_bit[0]),
	.input_message(message_bit[0])	
);

simplified_sha256 block1 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[1]),
	.output_hash(h[1]),
	.input_hash(hash_bit[1]),
	.input_message(message_bit[1])	
);

simplified_sha256 block2 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[2]),
	.output_hash(h[2]),
	.input_hash(hash_bit[2]),
	.input_message(message_bit[2])	
);

simplified_sha256 block3 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[3]),
	.output_hash(h[3]),
	.input_hash(hash_bit[3]),
	.input_message(message_bit[3])	
);

simplified_sha256 block4 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[4]),
	.output_hash(h[4]),
	.input_hash(hash_bit[4]),
	.input_message(message_bit[4])	
);

simplified_sha256 block5 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[5]),
	.output_hash(h[5]),
	.input_hash(hash_bit[5]),
	.input_message(message_bit[5])	
);

simplified_sha256 block6 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[6]),
	.output_hash(h[6]),
	.input_hash(hash_bit[6]),
	.input_message(message_bit[6])	
);

simplified_sha256 block7 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[7]),
	.output_hash(h[7]),
	.input_hash(hash_bit[7]),
	.input_message(message_bit[7])	
);

simplified_sha256 block8 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[8]),
	.output_hash(h[8]),
	.input_hash(hash_bit[8]),
	.input_message(message_bit[8])	
);

simplified_sha256 block9 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[9]),
	.output_hash(h[9]),
	.input_hash(hash_bit[9]),
	.input_message(message_bit[9])	
);

simplified_sha256 block10 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[10]),
	.output_hash(h[10]),
	.input_hash(hash_bit[10]),
	.input_message(message_bit[10])	
);

simplified_sha256 block11 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[11]),
	.output_hash(h[11]),
	.input_hash(hash_bit[11]),
	.input_message(message_bit[11])	
);

simplified_sha256 block12 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[12]),
	.output_hash(h[12]),
	.input_hash(hash_bit[12]),
	.input_message(message_bit[12])	
);

simplified_sha256 block13 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[13]),
	.output_hash(h[13]),
	.input_hash(hash_bit[13]),
	.input_message(message_bit[13])	
);

simplified_sha256 block14 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[14]),
	.output_hash(h[14]),
	.input_hash(hash_bit[14]),
	.input_message(message_bit[14])	
);

simplified_sha256 block15 (
	.clk(clk),
	.reset_n(reset_n),
	.start(start_bit),
	.done(done_sha[15]),
	.output_hash(h[15]),
	.input_hash(hash_bit[15]),
	.input_message(message_bit[15])	
);

//genvar q;
//generate 
//	for (q = 0; q < num_nonces; q++) begin : generate_sha256_blocks
//		simplified_sha256 block (
//			.clk(clk),
//			.reset_n(reset_n),
//			.start(start_bit[q]),
//			.done(done_sha[q]),
//			.output_hash(h[q]), // <--how to make this work?
//			.input_hash(hash[q]),
//			.input_message(message_bit[q])	
//		);
//	end : generate_sha256_blocks
//endgenerate
			

enum logic [ 4:0] {IDLE, READ, BUFFER1, PHASE1, BUFFER2, PHASE2, BUFFER3, PHASE3, WRITE} state_bit;
logic [31:0] hout[num_nonces];

parameter int k[64] = '{
    32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
    32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
    32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
    32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
    32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,32'h650a7354,32'h766a0abb,32'h81c2c92e,32'h92722c85,
    32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
    32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
    32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
};

assign mem_clk = clk;
assign mem_addr = cur_addr + offset_bit;
assign mem_we = cur_we;
assign mem_write_data = cur_write_data;


always_ff@(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		state_bit <= IDLE;
	end
	else
		case (state_bit)
			IDLE:begin
				if(start) begin

				fhash[0] <= 32'h6a09e667;
				fhash[1] <= 32'hbb67ae85;
				fhash[2] <= 32'h3c6ef372;
				fhash[3] <= 32'ha54ff53a;
				fhash[4] <= 32'h510e527f;
				fhash[5] <= 32'h9b05688c;
				fhash[6] <= 32'h1f83d9ab;
				fhash[7] <= 32'h5be0cd19;
				
				offset_bit <= 0;
				
				cur_addr <= message_addr;
				
				state_bit <= READ;
				end
			
			end
			READ: begin
				if (offset_bit < 20) begin  //read first 19 words
					message_bit_full[offset_bit-1] <= mem_read_data;
					offset_bit++;
					state_bit <= READ;
				end
				else begin // pad the rest
					message_bit_full[20] <= 32'h80000000; // leading 1 bit
					for (int m = 21; m < 31; m++) begin
						message_bit_full[m] <= 32'h00000000; // pad zeros
					end
					message_bit_full[31] <= 32'd640; // SIZE = 640 BITS
					
					
					for (int n = 0; n < 16; n++) begin // input message in 0 sha256
						for (int m = 0; m < 16; m++) message_bit[n][m] <= message_bit_full[m];
					end
					
					// input hash to 0 sha256
					for (int m = 0; m < 8; m++) hash_bit[0][m] <= fhash[m];


					offset_bit <= 0;
					start_bit <= 1;
					state_bit <= BUFFER1;
				end	
			end
			BUFFER1: begin // stay in buffer until first input processed
				if (!done_sha[0]) state_bit<=PHASE1;
			end
			PHASE1: begin
				if (done_sha[0]) begin
				
					for (int n = 0; n < 16; n++) begin
					for (int m = 0; m < 8; m++) hash_bit[n][m] <= h[0][m];
						for (int m = 0; m < 16; m++) begin
							//hash_bit[n][m] <= h[0][m]; // add output of 0 sha256 to 16 sha256 modules
							if (m == 3) begin
								message_bit[n][m] <= n; // assign nonce valve								
							end
							else message_bit[n][m] <= message_bit_full[m+16]; // add message to 16 sha256 modules
						end
					end
					start_bit <= 1;
					state_bit <= BUFFER2;
				end
				else state_bit <= PHASE1;
			end
			BUFFER2: begin // wait until finished
				if (!done_sha[0]) state_bit<=PHASE2;
			end
			PHASE2: begin
				if (done_sha[0]) begin

					for (int n = 0; n < 16; n++) begin
						for (int m = 0; m < 8; m++) hash_bit[n][m] <= fhash[m]; // add initial hash
						for (int m = 0; m < 8; m++) message_bit[n][m] <= h[n][m]; //add output hash to message
						
						//padding
						message_bit[n][8] <= 32'h80000000; // leading 1 bit
						for (int m = 9; m < 15; m++) message_bit[n][m] <= 32'h00000000; // pad zeros
						message_bit[n][15] <= 32'd256; // SIZE = 256 BITS
					end
				
					start_bit <= 1;
					state_bit <= BUFFER3;
				end
				else state_bit <= PHASE2;
			end
			BUFFER3: begin  //wait until finished
				if (!done_sha[0]) state_bit<=PHASE3;
			end
			PHASE3: begin
				if (done_sha[0]) begin // read first hash from each sha256 output
					for (int n = 0; n < num_nonces; n++) begin
						hash_bit[n][0] <= h[n][0];
					end
									
					start_bit <= 0;
					state_bit <= WRITE;
				end
			end
			WRITE: begin
				cur_we <= 1;
				cur_addr <= output_addr -1;
				if(offset_bit < 16) begin // write first hash from each sha256 output
					cur_write_data <= hash_bit[offset_bit][0]; 
					offset_bit++;
				end
				else begin
					state_bit <= IDLE;
					offset_bit <= 0;
				end
			end
		endcase
end

assign done = (state_bit == IDLE);

endmodule
