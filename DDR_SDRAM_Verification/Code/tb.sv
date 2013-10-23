/****************************************************************************************************/
// Title      : DDR SDRAM test bench
// File       : tb.sv
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 06-Aug-2011
// Notes                 : Clk and Clk_n signal generation.
//                         Instances are declared: -DDR_Interface, DDR_InterfaceInt, DDR_RM_MODULE, DDR_Environment
/****************************************************************************************************/  

`timescale 1ns/1ps
`include "DDR_RM.sv"

module tb;
  
  `include "DDR_ParametersPkg.sv"
  import DDR_EnvPackage::*;
  
  // Clk and Clk_n signals
  bit Clk;
  bit Clk_n;
  
  //------------------------------------------   
  // Clk and Clk_n signal generation
  initial begin
    Clk   = 0;
    Clk_n = 1;  
  end 
  always #(tCK/2) Clk   = ~Clk;  
  always #(tCK/2) Clk_n = ~Clk_n;
  
  
  //------------------------------------------ 
  // Instances
  DDR_Interface     DDR_If(Clk, Clk_n);
  DDR_InterfaceInt  DDR_IntIf();
  DDR_RM_MODULE     RMD (DDR_If, DDR_IntIf);
  DDR_Environment Env = new(DDR_If, DDR_IntIf);
  
  //------------------------------------------ 
  // Test tasks
  initial begin: Test_Sequence

    Env.Run();
    
  end: Test_Sequence
  
  initial begin: MonAndCheck
    
    Env.Run_MonAndCheck();
 
  end: MonAndCheck
  
  
endmodule
