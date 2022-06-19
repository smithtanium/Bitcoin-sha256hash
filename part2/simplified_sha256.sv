module simplified_sha256 #(parameter integer NUM_OF_WORDS = 16) ( //20)(
 input logic  clk, reset_n, start,
 output logic done,
 output logic [31:0] output_hash[0:7],
 input logic [31:0] input_hash[0:7],
 input logic [31:0] input_message[0:15]);

// FSM state variables 
enum logic [2:0] {IDLE, BUFFER, BLOCK, COMPUTE, WRITE} state;

// Local variables
logic [31:0] w[64];
logic [31:0] a_message[16]; //[20];
logic [31:0] hash[8];
logic [31:0] a, b, c, d, e, f, g, h;
logic [ 7:0] i, j;
logic [15:0] offset; // in word address
logic [ 7:0] num_blocks;

// SHA256 K constants
parameter int k[0:63] = '{
   32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
   32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
   32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
   32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
   32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,32'h650a7354,32'h766a0abb,32'h81c2c92e,32'h92722c85,
   32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
   32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
   32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
};

assign num_blocks = 1; 


// Function to determine number of blocks in memory to fetch
function logic [15:0] determine_num_blocks(input logic [31:0] size);
    determine_num_blocks = (size/16) + ((size%16) < 14 ? 16'h1 : 16'h2); 
endfunction

//WORD EXPANSION
function logic [31:0] wtnew;
	logic [31:0] s0, s1; // internal signals
	begin
	s0 = rightrotate(w[1],7) ^ rightrotate(w[1],18) ^ (w[1] >> 3);
	s1 = rightrotate(w[14], 17) ^ rightrotate(w[14], 19) ^ (w[14] >> 10);
	wtnew = w[0] + s0 + w[9] + s1;
	end
endfunction


// SHA256 hash round
function logic [255:0] sha256_op(input logic [31:0] a, b, c, d, e, f, g, h, w,
                                 input logic [7:0] t);
    logic [31:0] S1, S0, ch, maj, t1, t2; // internal signals
	 
begin
    S1 = rightrotate(e, 6) ^ rightrotate(e, 11) ^ rightrotate(e, 25);
    ch = (e & f) ^ ((~e) & g);
    t1 = h + S1 + ch + k[t] + w; //kt + wt;
    S0 = rightrotate(a, 2) ^ rightrotate(a, 13) ^ rightrotate(a, 22);
    maj = (a & b) ^ (a & c) ^ (b & c);
    t2 = S0 + maj;
    sha256_op = {t1 + t2, a, b, c, d + t1, e, f, g};
end
endfunction

// Right rotation function
function logic [31:0] rightrotate(input logic [31:0] x,
                                  input logic [ 7:0] r);
   rightrotate = (x >> r) | (x << (32 - r));
endfunction


// SHA-256 FSM 
always_ff @(posedge clk, negedge reset_n)
begin
  if (!reset_n) begin
    state <= IDLE;
  end 
  else case (state)
    // Initialize hash values h0 to h7 and a to h, other variables and memory we, address offset, etc
    IDLE: begin 
        if(start) begin

		
		i <= 0; 
		j <= 0; 
		//$display("%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x", a, b, c, d, e, f, g, h);
		state <= BUFFER;
        end
    end 
	BUFFER: begin
			for (int n = 0; n < 8; n++) hash[n] <= input_hash[n];
			state <= BLOCK;
	end
    BLOCK: begin
		if (i == 0) begin
			a <= hash[0];;		
			b <= hash[1];	
			c <= hash[2];	
			d <= hash[3];	
			e <= hash[4];	
			f <= hash[5];	
			g <= hash[6];	
			h <= hash[7];
		end			
		if(j < num_blocks) begin		
			for (int m = 0; m < 16; m++) w[m] <= input_message[m];
			state <= COMPUTE;
		end
		else begin 
			state <= WRITE;
		end
		
	end
    COMPUTE: begin 
		if (i < 64) begin
			{a, b, c, d, e, f, g, h} = sha256_op(a, b, c, d, e, f, g, h, w[0], (i));
			for (int n = 0; n < 15; n++) w[n] <= w[n+1];
			w[15] <= wtnew();
			i++;
		end
		else begin
			hash[0] <= hash[0] + a;
			hash[1] <= hash[1] + b;
			hash[2] <= hash[2] + c;
			hash[3] <= hash[3] + d;
			hash[4] <= hash[4] + e;
			hash[5] <= hash[5] + f;
			hash[6] <= hash[6] + g;
			hash[7] <= hash[7] + h;
		
			i<=0;
			j++;
			state <= BLOCK;
		end
		//$display("%x\t%x\t%x\t%x\t%x\t%x\t%x\t%x", a, b, c, d, e, f, g, h);
    end
    WRITE: begin
		for (int n = 0; n < 8; n++) output_hash[n] = hash[n];
		state <= IDLE;
    end
  
	endcase
 end
 
// Generate done when SHA256 hash computation has finished and moved to IDLE state
assign done = (state == IDLE);

endmodule
