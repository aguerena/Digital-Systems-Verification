/****************************************************************************************************/
// Title      : DDR SDRAM Test1
// File       : DDR_Test1.sv
// Description: Test for Power Up and Initialization of DDR SDRAM
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 07-Aug-2011
// Notes                 : None 
/****************************************************************************************************/
import DDR_EnvPackage::*;

class DDR_Test1;

  `include "DDR_ParametersPkg.sv"

  //------------------------------------------ 
  // Instances References
  DDR_TBFM pTBFM;
  
  
  //------------------------------------------ 
  // Variables for cycles counter
  real tck      = tCK;
  integer tmrd  = ( (tRAP/tCK) > ($rtoi(tRAP/tCK)) ) ? ($rtoi(tRAP/tCK)+1):(tRAP/tCK) ;
  integer trap  = cycles_counter(tRAP/tCK);
  integer tras  = cycles_counter(tRAS/tCK);
  integer trc   = cycles_counter(tRC/tCK);
  integer trfc  = cycles_counter(tRFC/tCK);
  integer trcd  = cycles_counter(tRCD/tCK);
  integer trp   = cycles_counter(tRP/tCK);
  integer trrd  = cycles_counter(tRRD/tCK);
  integer twr   = cycles_counter(tWR/tCK);
  
  
  integer BL = 4;
  
  
  //------------------------------------------ 
  // Function for cycles counter
  function integer cycles_counter;

    input number;
    real number;
    if(number > $rtoi(number))
      cycles_counter = $rtoi(number)+1;
    else 
      cycles_counter = number;
       
  endfunction  

  //------------------------------------------ 
  // Task Test1 Run
  task Run;
   
    $display("TEST 1");
    pTBFM.Power_Up(); 
    pTBFM.Precharge('h00, 1);  
    pTBFM.Nop(trp);
    pTBFM.Load_Mode(1, 'h0000);
    pTBFM.Nop(tmrd);
    pTBFM.Load_Mode(0, 'h0131);
    pTBFM.Nop(tmrd);
    pTBFM.Precharge('h00, 1);
    pTBFM.Nop(trp);
    pTBFM.Refresh();
    pTBFM.Nop(trfc);
    pTBFM.Refresh();
    pTBFM.Nop(trfc);
    pTBFM.Refresh();
    pTBFM.Nop(trfc);
    pTBFM.Load_Mode(0, 'h0031);
    pTBFM.Nop(tmrd);
    
  endtask: Run


endclass: DDR_Test1