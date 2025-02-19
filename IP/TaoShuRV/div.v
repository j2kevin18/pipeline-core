module div#(
	parameter 			DATA_LEN		= 	32			
)(
    input   wire                 clk,
    input   wire                 rst,
    input   wire signed  [DATA_LEN:0]              dividend,
    input   wire signed  [DATA_LEN:0]              divisor ,
    input   wire                   valid,
    
    output  reg  signed  [DATA_LEN:0]          quotient ,
    output  reg  signed  [DATA_LEN:0]          remainder,
    output  reg                    ready
    
    
);

	//自动计算计数器位宽函数。
	function integer clogb2(input integer depth);begin
		if(depth == 0)
			clogb2 = 1;
		else if(depth != 0)
			for(clogb2=0 ; depth>0 ; clogb2=clogb2+1)
				depth=depth >> 1;
		end
	endfunction
 
	reg work_flag;
	reg [DATA_LEN-1:0] remainder_pre;
	reg [2*DATA_LEN-1:0] divisor_long;
	reg [clogb2(DATA_LEN):0] cnt;
	reg [DATA_LEN-1:0]  quotient_pre;
	
	always@(posedge clk)
		if(rst)
			work_flag <= 1'd0;
		else    if(cnt == DATA_LEN)
			work_flag <= 1'd0;
		else    if(valid == 1'd1)
			work_flag <= 1'd1;
	
	always@(posedge clk)
		if(rst)
			remainder_pre <= 'd0;
		else    if(work_flag == 1'd0)
			remainder_pre <= (dividend[DATA_LEN] == 1'd1)?~dividend[DATA_LEN-1:0]+1'd1:dividend[DATA_LEN-1:0];
		else    if(work_flag == 1'd1)
			begin
				if({{DATA_LEN{1'd0}}, remainder_pre} >= divisor_long)
					remainder_pre <= remainder_pre - divisor_long[DATA_LEN-1:0];
				else    
					remainder_pre <= remainder_pre;
			end        
			
	
	always@(posedge clk)
		if(rst)
			divisor_long <= {2*DATA_LEN{1'b0}};
		else    if(work_flag == 1'd0)
			divisor_long <= {(divisor[DATA_LEN] == 1'd1)?~divisor[DATA_LEN-1:0]+1'd1:divisor[DATA_LEN-1:0], {DATA_LEN{1'b0}}};
		else    if(work_flag == 1'd1)
			divisor_long <= divisor_long>>1;
	
	always@(posedge clk)
		if(rst)
			cnt <= 'd0;
		else    if(work_flag == 1'd0)
			cnt <= 'd0;
		else
			cnt <= cnt + 'd1;
	
	always@(posedge clk)
		if(rst)
			quotient_pre <= 'd0;
		else    if(work_flag == 1'd0)
			quotient_pre <= 'd0;
		else    if(work_flag == 1'd1)
			begin
				if({{DATA_LEN{1'd0}}, remainder_pre} >= divisor_long)
					quotient_pre[DATA_LEN-cnt] <= 1'd1;
				else    
					quotient_pre[DATA_LEN-cnt] <= 1'd0;
			end        
			
	always@(posedge clk)
		if(rst)
			quotient <= {(DATA_LEN+1){1'b0}};
		else    if(cnt == DATA_LEN+1)
			quotient <= (dividend[DATA_LEN]^divisor[DATA_LEN] == 1'd1)?{1'd1,~quotient_pre+1'd1}:{1'b0, quotient_pre};     
	
	always@(posedge clk)
		if(rst)
			remainder <= {(DATA_LEN+1){1'b0}};
		else    if(cnt == DATA_LEN+1)
			remainder <= {dividend[DATA_LEN] == 1'd1}? {1'd1,~remainder_pre[DATA_LEN-1:0]+1'd1} :{1'd0,remainder_pre[DATA_LEN-1:0]};    
	
	always@(posedge clk)
		if(rst)
			ready <= 'd0;
		else    if(cnt == DATA_LEN+1)
			ready <= 'd1;
		else
			ready <= 'd0;
        
endmodule 

module div_pipeline #(
	parameter 			DATA_LEN		= 	32			
)(
    input   wire                 					 clk,
    input   wire                 					 rst,
    input   wire [DATA_LEN-1:0]  		             dividend,
    input   wire [DATA_LEN-1:0]  		             divisor ,
    input   wire                   					 valid,
	input   wire				   					 is_signed,
    
    output  reg  [DATA_LEN-1:0]  		             quotient ,
    output  reg  [DATA_LEN-1:0]  		         	 remainder,
    output  reg                    					 ready
    
);

	wire dividend_sign;
	wire divisor_sign;
	reg [DATA_LEN:0] dividend_tmp;
	reg [DATA_LEN:0] divisor_tmp;
	reg [DATA_LEN:0] quotient_tmp;
	reg [DATA_LEN:0] remainder_tmp;

	assign dividend_sign = dividend[DATA_LEN-1];
	assign divisor_sign  = divisor[DATA_LEN-1];

	always @(*) begin
		if(is_signed) begin
			dividend_tmp = {dividend_sign, dividend};
			divisor_tmp = {divisor_sign, divisor};
		end
		else begin
			dividend_tmp = {1'b0, dividend};
			divisor_tmp = {1'b0, divisor};
		end
	end

	always @(*) begin
		quotient  = quotient_tmp[DATA_LEN-1:0];
		remainder = remainder_tmp[DATA_LEN-1:0];
	end

	div#(
		.DATA_LEN(DATA_LEN)
	) 
	u_div (
		.clk      (clk),
		.rst      (rst),
		.dividend (dividend_tmp),
	    .divisor  (divisor_tmp),
		.valid    (valid),
	 	.quotient (quotient_tmp),
	 	.remainder(remainder_tmp),
		.ready    (ready)
	);

endmodule