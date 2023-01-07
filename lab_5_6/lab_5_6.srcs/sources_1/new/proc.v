`define PC_WIDTH 10
`define COMMAND_SIZE 46
`define PROGRAM_SIZE 1024
`define DATA_SIZE 1024
`define OP_SIZE 4

`define NOP 0
`define LOAD_MEM 1
`define ADD 2
`define SUB 3
`define JMP_GZ 4
`define LOAD_A 5
`define LOAD_B 6
`define WRITE_A_TO_MEM 7

/*
    ������ �������:
    ADD, SUB, NOP:
    | ��� ��������  |  |                       |
         4 ����     |  |                       |
    LOAD:
    | ��� ��������  |  ����� � ������ |           �������             |
         4 ����     |     10 ���      |            32 ����            |
    JMP_GZ:
    | ��� ��������  |           ����� ��������      |                        |
         4 ����     |            10 ���             |       32 ����          |
    LOAD_A, LOAD_B, WRITE_A_TO_MEM:
    | ��� ��������  |           �����               |                        |
         4 ����     |            10 ���             |       32 ����          |
*/


module cpu_conv2(
    input clk_in,
    input reset,
    output pc
);

wire clk;
reg[`PC_WIDTH-1 : 0] pc, newpc;

wire [$clog2(`DATA_SIZE) - 1 : 0] new_addr = addr_to_load;
reg [`COMMAND_SIZE-1 : 0]   Program [0:`PROGRAM_SIZE - 1  ];
reg [31:0]                  Data    [0:`DATA_SIZE - 1];

//1 ����
reg[`COMMAND_SIZE-1 : 0] command_1;

reg [`COMMAND_SIZE - 1 : 0] command_2;
wire [`OP_SIZE - 1 : 0] op = command_2 [`COMMAND_SIZE - 1 -: `OP_SIZE];

wire [$clog2(`DATA_SIZE) - 1 : 0] addr_to_load = command_2 [`COMMAND_SIZE - 1 - `OP_SIZE  -: $clog2(`DATA_SIZE)];

wire [31:0] literal_to_load = command_2 [`COMMAND_SIZE - 1 - `OP_SIZE - $clog2(`DATA_SIZE) -: 32];
wire [$clog2(`DATA_SIZE) - 1 : 0] addr1 = command_2 [`COMMAND_SIZE - 1 - `OP_SIZE  -: $clog2(`DATA_SIZE)];
wire [$clog2(`DATA_SIZE) - 1 : 0] addr2 = command_2 [`COMMAND_SIZE - 1 - `OP_SIZE - $clog2(`DATA_SIZE)  -: $clog2(`DATA_SIZE)];
wire [$clog2(`DATA_SIZE) - 1 : 0] addr3 = command_2 [`COMMAND_SIZE - 1 - `OP_SIZE - 2*$clog2(`DATA_SIZE) -: $clog2(`DATA_SIZE)];
reg [31:0] Reg_A, Reg_B, newReg_A, newReg_B;

integer i;
initial 
begin
    pc = 0; newpc = 0;
    $readmemb("Program.mem", Program);
    for(i = 0; i < `DATA_SIZE; i = i + 1)
        Data[i] = 32'b0;
    command_1 = 0;
    command_2 = 0;
    Reg_A = 0;
    Reg_B = 0;
    newReg_A = 0; 
    newReg_B = 0;
end



clk_wiz_0 inst(
    .clk_in1(clk_in),
    .clk_out1(clk)
);



//���� ���������� ��������� ������
always@(posedge clk)
    if(reset)
        pc <= 0;
    else
        pc <= newpc;
        

//���� ����������� ���������� �������� �������� ������
always@*
begin
    if( op == `JMP_GZ && Reg_A > 0)
        newpc <= new_addr;
    else newpc <= pc + 1;
end

//1 ����
always@(posedge clk)
    command_1 <= Program[pc];


//2 ����
always@(posedge clk)
    command_2 <= command_1;


//��������� �������� A
always @(posedge clk)
begin 
    if(reset) Reg_A <= 0;
    else Reg_A <= newReg_A;
end

//��������� �������� �
always @(posedge clk)
begin 
    if(reset) Reg_B <= 0;
    else Reg_B <= newReg_B;
end

//����� ��� ��� �������� �
always@*
begin
    case(op)
        `LOAD_MEM:  Data[addr_to_load] <= literal_to_load;
        `ADD:       newReg_A <= Reg_A + Reg_B;
        `SUB:       newReg_A <= Reg_A - Reg_B;
        `LOAD_A:    newReg_A <= Data[addr_to_load];
    endcase
end

//����� ��� ��� �������� B
always@*
begin
    case(op)
        `LOAD_B:    newReg_B <= Data[addr_to_load];
    endcase
end

//������ � ������
always @(posedge clk)
    if(op == `WRITE_A_TO_MEM)
        Data[ addr_to_load ] <= Reg_A;

endmodule
