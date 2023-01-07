`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.01.2023 15:42:45
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench(

    );
    
    reg clk=0;
    reg reset=0;
    wire pc;
    always#10 clk=~clk;
    cpu_conv3 cpu(
    .clk_in(clk),
    .reset(reset),
   .pc(pc)
);
endmodule
