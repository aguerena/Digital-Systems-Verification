/****************************************************************************************************/
// Title      : DDR SDRAM Environment Package
// File       : DDR_EnvPackage.sv
// Description: DDR_SDRAM Verification Environment Package
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 06-Aug-2011
// Notes                 : Files included:
/*                         DDR_Packet.sv
                           DDR_TBFM.sv 
                           DDR_RBFM.sv
                           DDR_Coverage.sv
                           DDR_Test1.sv
                           DDR_Test2.sv
                           DDR_Test3.sv
                           DDR_Test4.sv
                           DDR_Test5.sv
                           DDR_Environment.sv */
/****************************************************************************************************/  

//`timescale 1ns / 1ps

package DDR_EnvPackage; 
  
  `include "DDR_ParametersPkg.sv"
  `include "DDR_Packet.sv"  
  `include "DDR_TBFM.sv"
  `include "DDR_RBFM.sv" 
  `include "DDR_Coverage.sv"
  
  `ifdef TEST5
      `include "DDR_Test5.sv"
  `else `ifdef  TEST4
      `include "DDR_Test4.sv"
  `else `ifdef  TEST3
      `include "DDR_Test3.sv"
  `else `ifdef  TEST2
      `include "DDR_Test2.sv"
  `else `define TEST1
      `include "DDR_Test1.sv" 
  `endif `endif `endif `endif
  
 
  `include "DDR_Environment.sv"
  
endpackage: DDR_EnvPackage