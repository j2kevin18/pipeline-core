module adder (
   input   Add_A,
   input   Add_B,
   input   Add_Cin,
   output  Cout,
   output  Sum
);

assign Cout     = (Add_A & Add_B) | (Add_Cin & (Add_A | Add_B));
assign Sum      = Add_A ^ Add_B ^ Add_Cin;
// assign {Cout, Sum} = Add_A + Add_B + Add_Cin;
endmodule


module wallace_mul (
    input [31:0] mul1,
    input [31:0] mul2,
    input is_signed,
    output [63:0] result
);
    // every 3 bits generate a boothcode, then shift 2 bits
    wire [2:0] booth_code [15:0];
    wire [1:0] unsigned_booth_code [15:0];
    // mul1 2*mul1 mul1_complement 2*mul1_complement
    wire        [31:0]   mulX;
    wire        [32:0]   mulX_2;
    wire        [33:0]   mulX_3;
    wire        [31:0]   mulX_cpl;
    wire        [32:0]   mulX_cpl_2;
    wire        [31:0]   mulY;
    // Nsum is the partical product
    // Csum is the carry of 3_2_compressor
    // Ssum is the sum of 3_2_compressor
    wire        [63:0]   Nsum       [15:0];  
    wire        [64:0]   Csum       [16:0];  
    wire        [63:0]   Ssum       [16:0]; 


    assign mulX         = mul1;
    assign mulX_2       = {mulX, 1'b0};
    assign mulX_3       = {1'b0, mulX_2} + {2'b00, mulX};
    assign mulX_cpl     = ~mulX;
    assign mulX_cpl_2   = ~mulX_2;
    assign mulY         = mul2;

    genvar i;
    generate
        assign booth_code[0] = {mulY[1], mulY[0], 1'b0};
        assign unsigned_booth_code[0] = {mulY[1], mulY[0]};
        for (i=1; i<=15; i=i+1) begin
            assign booth_code[i] = {mulY[2*i+1], mulY[2*i], mulY[2*i-1]};
            assign unsigned_booth_code[i] = {mulY[2*i+1], mulY[2*i]};
        end
    endgenerate

    generate
    for (i = 0; i < 16; i = i + 1) begin
        assign Nsum[i] = is_signed ?
                         {64{(booth_code[i] == 3'b000)}} & 64'b0                                                   |
                         {64{(booth_code[i] == 3'b001)}} & {{(32-2*i){mulX[31]}},         mulX,       {2*i{1'b0}}} |
                         {64{(booth_code[i] == 3'b010)}} & {{(32-2*i){mulX[31]}},         mulX,       {2*i{1'b0}}} |
                         {64{(booth_code[i] == 3'b011)}} & {{(32-2*i-1){mulX_2[32]}},     mulX_2,     {2*i{1'b0}}} |

                         {64{(booth_code[i] == 3'b100)}} & {{(32-2*i-1){mulX_cpl_2[32]}}, mulX_cpl_2, {2*i{1'b1}}} |
                         {64{(booth_code[i] == 3'b101)}} & {{(32-2*i){mulX_cpl[31]}},     mulX_cpl,   {2*i{1'b1}}} |
                         {64{(booth_code[i] == 3'b110)}} & {{(32-2*i){mulX_cpl[31]}},     mulX_cpl,   {2*i{1'b1}}} |
                         {64{(booth_code[i] == 3'b111)}} & 64'b0
                         : 
                         {64{(unsigned_booth_code[i] == 2'b00)}} & 64'b0                                                     |
                         {64{(unsigned_booth_code[i] == 2'b01)}} & {{(32-2*i){1'b0}},           mulX,       {2*i{1'b0}}}     |
                         {64{(unsigned_booth_code[i] == 2'b10)}} & {{(32-2*i-1){1'b0}},         mulX_2,     {2*i{1'b0}}}     |
                         {64{(unsigned_booth_code[i] == 2'b11)}} & {{(32-2*i-2){1'b0}},         mulX_3,     {2*i{1'b0}}};
        
        // use Csum to the implement of +1, when taking complement
        assign Csum[i][0] = is_signed ? 
                            (booth_code[i] == 3'b100) |
                            (booth_code[i] == 3'b101) |
                            (booth_code[i] == 3'b110) 
                            : 1'b0;
    end
    endgenerate

    assign Csum[16][0] = 1'b0;


    generate 
    for(i=0;i<64;i=i+1)begin
        adder  adder0(.Add_A(Nsum[  0][i]),.Add_B(Nsum[  1][i]),.Add_Cin(Nsum[  2][i]),.Sum(Ssum[ 0][i]),.Cout(Csum[ 0][i+1]));
        adder  adder1(.Add_A(Nsum[  3][i]),.Add_B(Nsum[  4][i]),.Add_Cin(Nsum[  5][i]),.Sum(Ssum[ 1][i]),.Cout(Csum[ 1][i+1]));
        adder  adder2(.Add_A(Nsum[  6][i]),.Add_B(Nsum[  7][i]),.Add_Cin(Nsum[  8][i]),.Sum(Ssum[ 2][i]),.Cout(Csum[ 2][i+1]));
        adder  adder3(.Add_A(Nsum[  9][i]),.Add_B(Nsum[ 10][i]),.Add_Cin(Nsum[ 11][i]),.Sum(Ssum[ 3][i]),.Cout(Csum[ 3][i+1]));
        adder  adder4(.Add_A(Nsum[ 12][i]),.Add_B(Nsum[ 13][i]),.Add_Cin(Nsum[ 14][i]),.Sum(Ssum[ 4][i]),.Cout(Csum[ 4][i+1]));
        adder  adder5(.Add_A(Nsum[ 15][i]),.Add_B(1'b0        ),.Add_Cin(1'b0        ),.Sum(Ssum[ 5][i]),.Cout(Csum[ 5][i+1]));
        adder  adder6(.Add_A(Ssum[  0][i]),.Add_B(Ssum[  1][i]),.Add_Cin(Ssum[  2][i]),.Sum(Ssum[ 6][i]),.Cout(Csum[ 6][i+1]));
        adder  adder7(.Add_A(Ssum[  3][i]),.Add_B(Ssum[  4][i]),.Add_Cin(Ssum[  5][i]),.Sum(Ssum[ 7][i]),.Cout(Csum[ 7][i+1]));
        adder  adder8(.Add_A(Csum[  0][i]),.Add_B(Csum[  1][i]),.Add_Cin(Csum[  2][i]),.Sum(Ssum[ 8][i]),.Cout(Csum[ 8][i+1]));
        adder  adder9(.Add_A(Csum[  3][i]),.Add_B(Csum[  4][i]),.Add_Cin(Csum[  5][i]),.Sum(Ssum[ 9][i]),.Cout(Csum[ 9][i+1]));
        adder adder10(.Add_A(Ssum[  6][i]),.Add_B(Ssum[  7][i]),.Add_Cin(Ssum[  8][i]),.Sum(Ssum[10][i]),.Cout(Csum[10][i+1]));
        adder adder11(.Add_A(Ssum[  9][i]),.Add_B(Csum[  6][i]),.Add_Cin(Csum[  7][i]),.Sum(Ssum[11][i]),.Cout(Csum[11][i+1]));
        adder adder12(.Add_A(Csum[  8][i]),.Add_B(Csum[  9][i]),.Add_Cin(1'b0        ),.Sum(Ssum[12][i]),.Cout(Csum[12][i+1]));
        adder adder13(.Add_A(Ssum[ 10][i]),.Add_B(Ssum[ 11][i]),.Add_Cin(Ssum[ 12][i]),.Sum(Ssum[13][i]),.Cout(Csum[13][i+1]));
        adder adder14(.Add_A(Csum[ 10][i]),.Add_B(Csum[ 11][i]),.Add_Cin(Csum[ 12][i]),.Sum(Ssum[14][i]),.Cout(Csum[14][i+1]));
        adder adder15(.Add_A(Ssum[ 13][i]),.Add_B(Ssum[ 14][i]),.Add_Cin(Csum[ 13][i]),.Sum(Ssum[15][i]),.Cout(Csum[15][i+1]));
        adder adder16(.Add_A(Ssum[ 15][i]),.Add_B(Csum[ 14][i]),.Add_Cin(Csum[ 15][i]),.Sum(Ssum[16][i]),.Cout(Csum[16][i+1]));
    end
    endgenerate


    // get result
    assign result = (Ssum[16] + Csum[16][63:0]);


endmodule