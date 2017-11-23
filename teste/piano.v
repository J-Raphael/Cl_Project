module piano ( CLOCK_27, KEY, SW, I2C_SDAT, I2C_SCLK, AUD_ADCDAT, AUD_DACLRCK, AUD_DACDAT, AUD_BCLK, AUD_ADCLRCK, AUD_XCK, LEDR, LEDG );
	
	// Entradas:
		input CLOCK_27; // Clock em 27MHz.
		input [3:0] Key; 
		input [7:0] SW; 
		input AUD_ADCDAT;
	
	// Inouts:
		inout I2C_SDAT;
		
	// Saídas:
		output I2C_SCLK, AUD_ADCLRCK, AUD_DACLRCK;
		output AUD_DACDAT;
		output [7:0] LEDG, LEDR;
		output reg AUD_BCLK, AUD_XCK;
		
	// Parametros:
		parameter REF_CLK = 18432000; // MCLK, 18.432MHz.
		parameter SAMPLE_RATE = 48000; // 48KHz.
		parameter CHANNEL_NUM = 2; // Dual Channel.
		parameter SIN_SAMPLE_DATA = 48;
		
		//  Frequencia Notas Musicais:
			parameter DO = 2000;
			parameter RE = 1900;
			parameter MI = 1805;
			parameter FA = 1760;
			parameter SOL = 1675;
			parameter LA = 1595;
			parameter SI = 1520;
			parameter DO1 = 1485;
			
	// Regs:
		reg [19:0] count20;
		reg Reset;
		reg [3:0] BCK_DIV;
		reg [8:0] LRCK_1X_DIV;
		reg LRCK_1X;
		reg [3:0] SEL_Count;
		reg [11:0] count12;
		reg SING;
		reg [DATA_WIDTH - 1:0] SOUND1, SOUND2, SOUND3;
		reg [1:0] count2;
		reg [7:0] Octave;
		reg [3:0] volume;
		
	// Funcao ... :
		i2c_codec_control u1(CLOCK_27, KEY[0], I2C_SCLK, I2C_SDAT, LEDG[7:4]);
	
	// Clock do Codec:
		always @( posedge CLOCK_27 or negedge Reset) begin
			if(!Reset)
				AUD_XCK <= 0;
			else
				AUD_XCK <= ~AUD_XCK;
		end
	
	// Delay do Reset:
		always @(posedge CLOCK_27) begin
			if( count20 != 20'hFFFFF) begin
				count20 <= count20+1;
				Reset <= 0;
			end
			else
				Reset <= 1;
		end
	
	always *( posedge AUD_XCK or negedge Reset ) begin
		if(!Reset) begin
			BCK_DIV <= 4'b0;
			AUD_BCLK <= 0;			
		end
		else begin
			if( BCK_DIV >= (REF_CLK/(SAMPLE_RATE*DATA_WIDTH*CHANNEL_NUM*2) - 1 ))
			begin
				BCK_DIV <= 4'b0;
				AUD_BCLK <= ~AUD_BCLK;
			end
			else 
				BCK_DIV <= BCK_DIV + 1;
		end
	end
	
	always @(posedge AUD_XCK or negedge Reset) begin
		if(!Reset) begin
			LRCK_1X_DIV <= 9'b0;
			LRCK_1X <= 1'b0;
		end 
		else begin
			if(LRCK_1X_DIV >= (REF_CLK/(SAMPLE_RATE*2) - 1)) begin
				LRCK_1X_DIV <= 9'b0;
				LRCK_1X <= ~LRCK_1X;
			end
			else
				LRCK_1X_DIV <= LRCK_1X_DIV + 1;
		end
	end
	
	assign AUD_ADCLRCK = LRCK_1X;
	assign AUD_DACLRCK = LRCK_1X;
	
	always @(negedge AUD_BCLK or negedge Reset) begin
		if( !Reset)
			Octave <= 8'b00000000;
		else
			if(SW)
				Octave <= SW;
	end
	
	always @(posedge AUD_BCLK or negedge Reset) begin
		if(!Reset)
			count12 <= 12'h000;
		else begin
			if(Octave == 8'b00000001) begin
				if(count12 == DO)
					count12 <= 12'h00;
				else
					count12 <= count12 + 1;
			end
			if(Octave == 8'b00000010) begin
				if( count12 == RE)
					count12 <= 12'h00;
				else
					count12 <= count12 + 1;
			end
			if(Octave == 8'b00000100) begin
				if( count12 == MI)
					count12 <= 12'h00;
				else
					count12 <= count12 + 1;
			end
			if(Octave == 8'b00001000) begin
				if( count12 == FA)
					count12 <= 12'h00;
				else
					count12 <= count12 + 1;
			end
			if(Octave == 8'b00010000) begin
				if( count12 == SOL)
					count12 <= 12'h00;
				else
					count12 <= count12 + 1;
			end
			if(Octave == 8'b00100000) begin
				if( count12 == LA)
					count12 <= 12'h00;
				else
					count12 <= count12 + 1;
			end
			if(Octave == 8'b01000000) begin
				if( count12 == SI)
					count12 <= 12'h00;
				else
					count12 <= count12 + 1;
			end
			if(Octave == 8'b10000000) begin
				if( count12 == DO1)
					count12 <= 12'h00;
				else
					count12 <= count12 + 1;
			end
		end
	end
	
	assign LEDR = Octave;
	
	always @(negedge AUD_BCLK or negedge Reset) begin
		if(!Reset) begin
			SOUND1 <= 0;
			SOUND2 <= 0;
			SOUND3 <= 0;
			SING <= 1'b0;
		end
		else begin
			if(count12 == 12'h001) begin
				SOUND1 <= (SING == 1'b1)?32768+29000:32768-29000;
				SOUND2 <= (SING == 1'b1)?32768+16000:32768-16000;
				SOUND3 <= (SING == 1'b1)?32768+3000 : 32768-3000;
				SING <= ~SING;
			end
		end
	end
	
	always @(negedge KEY[3] or negedge Reset) begin
		if(!Reset)
			count2 <= 2'b00;
		else
			count2 <= count2 + 1;
	end
	
	always @(negedge AUD_BCLK or negedge Reset) begin
		if(!Reset)
			SEL_Count <= 4'b0000;
		else
			SEL_Count <= SEL_Count + 1;
	end
	
	assign AUD_DACDAT = (count2 == 2'd1)?SOUND1[~SEL_Count]:
						(count2 == 2'd2)?SOUND2[~SEL_Count]:
						(count2 == 2'd3)?SOUND3[~SEL_Count]:1'b0;
						
	always @(count2) begin
		case(count2)
			0: volume <= 4'b0000;
			1: volume <= 4'b0001;
			2: volume <= 4'b0011;
			3: volume <= 4'b1111;
			defaul: volume <= 4'b0000;
		endcase
	end

	assign LEDG[3:0] = volume;
	
endmodule
