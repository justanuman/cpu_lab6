`timescale 1ns / 1ps

`define PC_WIDTH 10
`define COMMAND_SIZE 46
`define PROGRAM_SIZE 1024
`define DATA_SIZE 1024
`define OP_SIZE 4
`define ADDR_SIZE 10

`define NOP 0
`define LOAD 1
`define MOV 2
`define MOV_IA 3
`define ADD 4
`define SUB 5
`define MOD 6
`define DIV 7
`define INCR 8
`define DECR 9
`define JMP_GZ 10
`define HLT 11

/*
    Формат команды:
    ADD, SUB, MOD, DIV, NOP:
    | код операции  | Адрес 1         | Адрес 2         | Адрес 3         |                 |
         4 бита     | 10 бит          | 10 бит          | 10 бит          | 12 бит          |
    INCR, DECR:
    | код операции  | адрес в памяти  |                 |
         4 бита     | 10 бит          | 32 бит          |
    LOAD:
    | код операции  | адрес в памяти  | Литерал         |
         4 бита     | 10 бит          | 32 бит          |
    MOV, MOV_IA (косвенная адресация):
    | код операции  | Адрес 1         | Адрес 2         | 
         4 бита     | 10 бит          | 10 бит          | 22 бит
    JMP_GZ:
    | код операции  | адрес перехода  |                 |
         4 бита     | 10 бит          | 32 бит          |
    HLT:                                              
    | код операции  |                 |
         4 бита     | 42 бит          |
        
*/

module ConvCPU(
    input clk,
    input rst,
    output reg [`PC_WIDTH - 1:0] pc,
    output reg HLT
);

    reg [`PC_WIDTH - 1:0] new_pc;
        
    reg [`COMMAND_SIZE - 1:0] program [0:`PROGRAM_SIZE - 1];
    reg [31:0] data [0:`DATA_SIZE - 1];
    assign number = data[0];
    
    reg [`COMMAND_SIZE - 1:0] command_1, command_2, command_3;
    wire [`OP_SIZE - 1:0] op_2 = command_2[`COMMAND_SIZE - 1-:`OP_SIZE];
    wire [`OP_SIZE - 1:0] op_3 = command_3[`COMMAND_SIZE - 1-:`OP_SIZE];
    
    wire [`ADDR_SIZE - 1:0] addr_1 = command_2[`COMMAND_SIZE - 1 - `OP_SIZE-:`ADDR_SIZE];
    wire [`ADDR_SIZE - 1:0] addr_2 = command_2[`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE-:`ADDR_SIZE];
    
    wire [$clog2(`DATA_SIZE) - 1:0] new_addr = command_3[`COMMAND_SIZE - 1 - `OP_SIZE-:$clog2(`DATA_SIZE)];
    wire [$clog2(`DATA_SIZE) - 1:0] addr_to_load = command_3[`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE - `ADDR_SIZE-:$clog2(`DATA_SIZE)];
    wire [$clog2(`DATA_SIZE) - 1:0] addr_to_load_l = command_3[`COMMAND_SIZE - 1 - `OP_SIZE-:`ADDR_SIZE];
    wire [$clog2(`DATA_SIZE) - 1:0] addr_to_mov = command_3[`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE-:`ADDR_SIZE];
    wire [$clog2(`DATA_SIZE) - 1:0] addr_to_unary_op = command_3[`COMMAND_SIZE - 1 - `OP_SIZE-:$clog2(`DATA_SIZE)];
    
    wire [31:0] literal_to_load = command_3[`COMMAND_SIZE - 1 - `OP_SIZE - $clog2(`DATA_SIZE)-:32];
    reg [31:0] reg_a, reg_b, new_reg_a, new_reg_b;
    reg flag_gz, new_flag_gz;
    
    reg [31:0] new_data;
    
    integer i;
    
    initial begin
        pc = 0; new_pc = 0;
        $readmemb("Program1.mem", program);
        for (i = 0; i < `DATA_SIZE; i = i + 1)
            data[i] = 32'b0;
        command_1 = 0;
        command_2 = 0;
        command_3 = 0;
        reg_a = 0;
        reg_b = 0;
        new_reg_a = 0; 
        new_reg_b = 0;
        HLT = 0;
    end
    
    //Блок управления счётчиком команд
    always @(posedge clk) begin
        if (rst)
            pc <= 0;
        else
            pc <= new_pc;
    end
    
    //Такт 2
    //Изменение регистра A
    always @(posedge clk) begin
        if (rst) 
            reg_a <= 0;
        else 
            reg_a <= new_reg_a;
    end
    
    //Изменение регистра B
    always @(posedge clk) begin 
        if (rst) 
            reg_b <= 0;
        else 
            reg_b <= new_reg_b;
    end
 
    always @* begin
        case (op_2)
            `ADD, `SUB, `MOD, `DIV, `MOV, `MOV_IA: new_reg_a <= data[addr_1];
            default: new_reg_a <= new_reg_a;
        endcase
    end
    
    always @* begin
        case(op_2)
            `ADD, `SUB, `MOD, `DIV: new_reg_b <= data[addr_2];
            default: new_reg_b <= new_reg_b;
        endcase
    end
    
    //Такт_3
    always @(posedge clk) begin
        case(op_3)
            `ADD, `SUB, `MOD, `DIV: data[addr_to_load] <= new_data;
            `INCR, `DECR: data[addr_to_unary_op] <= new_data;
            `LOAD: data[addr_to_load_l] <= new_data;
            `MOV: data[addr_to_mov] <= new_data;
            `MOV_IA: data[data[addr_to_mov]] <= new_data;
            `HLT: begin
                //$writememb("Data1.mem", data); 
                HLT <= 1;
            end
        endcase
    end
    
    always @* begin
        case(op_3)
            `ADD: new_data <= reg_a + reg_b;
            `SUB: new_data <= reg_a - reg_b;
            `MOD: new_data <= reg_a % reg_b;
            `DIV: new_data <= reg_a / reg_b;
            `INCR: new_data <= data[addr_to_unary_op] + 1;
            `DECR: new_data <= data[addr_to_unary_op] - 1;
            `LOAD: new_data <= literal_to_load;
            `MOV, `MOV_IA: new_data <= reg_a;
        endcase
    end
    
    always @(posedge clk) begin
        flag_gz <= new_flag_gz;
    end
    
    always @* begin 
        case(op_3)
            `ADD, `SUB, `MOD, `DIV, `INCR, `DECR: new_flag_gz <= new_data > 0;
        endcase
    end
    
    //Блок определения следующего значения счётчика команд
    always @* begin
        if (op_3 == `JMP_GZ && new_flag_gz)
            new_pc <= new_addr;
        else 
            new_pc <= pc + 1;
    end
    
    always @(posedge clk) begin
        command_1 <= program[pc];
        command_2 <= command_1;
        command_3 <= command_2;
    end

endmodule
