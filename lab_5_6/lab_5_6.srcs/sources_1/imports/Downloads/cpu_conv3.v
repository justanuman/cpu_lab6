`define PC_WIDTH 10
`define COMMAND_SIZE 46
`define PROGRAM_SIZE 1024
`define DATA_SIZE 1024
`define OP_SIZE 4
`define ADDR_SIZE 10
`define STACK_SIZE 100

`define NOP 0
`define LOAD 1
`define ADD 2
`define SUB 3
`define JMP_GZ 4
`define MULT 5
`define JMP 6
`define RET 7
`define JMP_Z 8
`define JMP_LZ 9
`define INCR 10
`define MOV 11
`define COMP 12
/*
    ������ �������:
    ADD, SUB, NOP, MULT:
    | ��� ��������  | ����� 1            | ����� 2         | ����� 3
         4 ����     | 10 ���             | 10 ���          | 10 ���
    ������ �������:
    INCR:
    | ��� ��������  | ����� 1            
         4 ����     | 10 ���             |
    LOAD:
    | ��� ��������  |  ����� � ������ |           �������             |
         4 ����     |     10 ���      |            32 ����            |
    JMP_GZ:
    | ��� ��������  |           ����� ��������      |                        |
         4 ����     |            10 ���             |       32 ����          |
    JMP_Z:
    | ��� ��������  |           ����� ��������      |                        |
         4 ����     |            10 ���             |       32 ����          | 
     JMP_LZ:
    | ��� ��������  |           ����� ��������      |                        |
         4 ����     |            10 ���             |       32 ����          |
    RET: �������
    | ��� ��������  |                               |                        |// ��������
         4 ����     |            10 ���             |       32 ����          |
    JMP: ������ � ��� ���������
    | ��� ��������  |           ����� ��������      |                        | // ��������
         4 ����     |            10 ���             |       32 ����          |
    INP: ������ � ��� ���������
    | ��� ��������  |  ����� � ������ |           �������    �� �����         | // �� ������� 
         4 ����     |     10 ���      |            32 ����            |
    MOV, COMP
    | ��� ��������  | ����� 1         | ����� 2         | 
         4 ����     | 10 ���          | 10 ���          | 22 ���
    
*/


module cpu_conv3(
    input clk_in,
    input reset,
    output pc
);

wire clk;
reg[`PC_WIDTH-1 : 0] pc, newpc;
reg[`STACK_SIZE-1:0] stack, newStack;
reg[`PC_WIDTH-1 : 0] oldpc;

reg [`COMMAND_SIZE-1 : 0]   Program [0:`PROGRAM_SIZE - 1  ];
reg [31:0]                  Data    [0:`DATA_SIZE - 1];

reg[`COMMAND_SIZE-1 : 0] command_1, command_2, command_3;
wire [`OP_SIZE - 1 : 0] op_2 = command_2 [`COMMAND_SIZE - 1 -: `OP_SIZE];
wire [`OP_SIZE - 1 : 0] op_3 = command_3 [`COMMAND_SIZE - 1 -: `OP_SIZE];

wire [`ADDR_SIZE - 1 : 0] addr1 = command_2[`COMMAND_SIZE - 1 - `OP_SIZE                 -: `ADDR_SIZE];
wire [`ADDR_SIZE - 1 : 0] addr2 = command_2[`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE    -: `ADDR_SIZE];

wire [$clog2(`DATA_SIZE) - 1 : 0] new_addr = command_3 [`COMMAND_SIZE - 1 - `OP_SIZE -: $clog2(`DATA_SIZE)];
wire [$clog2(`DATA_SIZE) - 1 : 0] addr_to_load = command_3 [`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE - `ADDR_SIZE -: $clog2(`DATA_SIZE)];
wire [$clog2(`DATA_SIZE) - 1 : 0] addr_to_load_L = command_3 [`COMMAND_SIZE - 1 - `OP_SIZE  -: `ADDR_SIZE];
wire [$clog2(`DATA_SIZE) - 1:0] addr_to_mov = command_3[`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE-:`ADDR_SIZE];

wire [31:0] literal_to_load = command_3 [`COMMAND_SIZE - 1 - `OP_SIZE - $clog2(`DATA_SIZE) -: 32];
reg [31:0] Reg_A, Reg_B, newReg_A, newReg_B;

reg flag_GZ, new_flag_GZ;
reg flag_Z, new_flag_Z;
reg flag_LZ, new_flag_LZ;

integer i;
initial 
begin
 flag_GZ=0; new_flag_GZ=0;
 flag_Z=0; new_flag_Z=0;
 flag_LZ=0; new_flag_LZ=0;
    pc = 0; newpc = 0;
    oldpc=0;
    stack=0; newStack=0;
   // $readmemb("Program1.mem", Program);
   $readmemb("test.mem", Program);
    for(i = 0; i < `DATA_SIZE; i = i + 1)
        Data[i] = 32'b0;
    command_1 = 0;
    command_2 = 0;
    command_3 = 0;
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
begin 
    oldpc=pc; //!!!!!!!!
    if(reset)
        pc <= 0;
    else
        pc <= newpc;
end
//���� ���������� ������
always@(posedge clk)
    if(reset)
        stack <= 0;
    else
        stack <= newStack;

//���� 2
//��������� �������� A
// � ��� ������ ��� �������
always @(posedge clk)
begin 
    if(reset) Reg_A <= 0;
    else Reg_A <= newReg_A;
    
end

//��������� �������� B
always @(posedge clk)
begin 
    if(reset) Reg_B <= 0;
    else Reg_B <= newReg_B;
end


always @*
begin
    case(op_2)
        `ADD, `SUB, `MULT, `INCR,  `MOV :
            newReg_A <= Data[addr1];//data[data[addr_to_mov]]
        `COMP: newReg_A <= Data[Data[addr1]];//data[data[addr_to_mov]]
        default: newReg_A <= newReg_A;
    endcase
end

always @*
begin
    case(op_2)
        `ADD, `SUB, `MULT,`COMP:
            newReg_B <= Data[addr2];
        default: newReg_B <= newReg_B;
    endcase
end

//����_3
reg [31:0] new_data;

always @(posedge clk)
begin
    case(op_3)
        `ADD, `SUB, `MULT:
            Data[addr_to_load] <= new_data;
         `LOAD:
            Data[addr_to_load_L] <= new_data;
         `MOV: Data[addr_to_mov] <= new_data;
         
    endcase
end

always @*
begin
    case(op_3)
        `ADD: new_data <= Reg_A + Reg_B;
        `SUB: new_data <= Reg_A - Reg_B;
        `MULT:new_data <= Reg_A * Reg_B;
        `MOV: new_data <= Reg_A;
        `INCR:new_data <= Reg_A+1;
        `LOAD: new_data <= literal_to_load;
    endcase
end

always @(posedge clk)
begin
    flag_GZ <= new_flag_GZ;
    flag_Z <= new_flag_Z;
    flag_LZ <= new_flag_LZ;
   

end

always @*
begin 
    case(op_3)
        `ADD, `SUB, `MULT: 
        begin 
            new_flag_GZ <= new_data >= 0;//!!!!!
            new_flag_LZ <= new_data < 0;
            new_flag_Z <= new_data == 0;
        end
       `COMP:
        begin 
            new_flag_LZ <= Reg_A < Reg_B;
            new_flag_Z <= Reg_A == Reg_B;
            new_flag_GZ <= Reg_A > Reg_B;
        end
    endcase
end

//���� ����������� ���������� �������� �������� ������
always@*
begin
    if( op_3 == `JMP_GZ && new_flag_GZ || (op_3 == `JMP) || ( op_3 == `JMP_Z && new_flag_Z ) || ( op_3 == `JMP_LZ && new_flag_LZ))
    begin 
        newStack={newStack[`STACK_SIZE-11:0],oldpc-1};
        newpc = new_addr;
    end
    else if((op_3 == `RET))
    begin
        newpc = stack[9:0];
        newStack={10'b0,newStack[`STACK_SIZE-1:10]};
    end
    else 
    begin 
        newpc <= pc + 1;
    end
end


//���� ����������� ���������� �������� �����
/*always@*
begin
    if( (op_3 == `JMP_GZ && new_flag_GZ) || (op_3 == `JMP) || ( op_3 == `JMP_Z && new_flag_Z) ||(op_3 == `JMP_LZ && new_flag_LZ) )
    begin 
        newStack<={newStack[`STACK_SIZE-11:0],pc+1};
    end
    else if((op_3 == `RET))
    begin
        newStack<={10'b0,newStack[`STACK_SIZE-1:10]};
    end
    
end
*/

always@(posedge clk)
begin
    command_1 <= Program[pc];
    command_2 <= command_1;
    command_3 <= command_2;
end


endmodule
/*
always@*
begin
    if( op_3 == `JMP_GZ && new_flag_GZ || (op_3 == `JMP))
    begin 
        newpc <= new_addr;
        
    end
    else if( op_3 == `JMP_Z && new_flag_Z )
    begin 
        newpc <= new_addr;
    end
    else if( op_3 == `JMP_LZ && new_flag_LZ )
    begin 
        newpc <= new_addr;
    end
    else if((op_3 == `RET))
    begin
        newpc <= stack[9:0];
    end
    else 
    begin 
        newpc <= pc + 1;
    end
end
*/