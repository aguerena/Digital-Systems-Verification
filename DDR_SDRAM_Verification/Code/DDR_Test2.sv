/****************************************************************************************************/
// Title      : DDR SDRAM Test2
// File       : DDR_Test2.sv
// Description: Directed Tests
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 07-Aug-2011
// Notes                 : None 
/****************************************************************************************************/
import DDR_EnvPackage::*;

class DDR_Test2;

  `include "DDR_ParametersPkg.sv"

  //------------------------------------------ 
  // Instances References
  DDR_TBFM pTBFM;
  
  integer BL = 8;
  
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
  // Task Test2 Run
  task Run;
   
    DDR_Packet Pkt = new();
     
    $display("TEST 2");  
    pTBFM.Power_Up();
    //pTBFM.Nop(trp);
    pTBFM.Precharge('h00, 1);  
    pTBFM.Nop(trp);
    pTBFM.Load_Mode(1, 'h0000);
    pTBFM.Nop(tmrd);
    
    assert(Pkt.randomize());
    pTBFM.Load_Mode(0, {Pkt.bMem_Mode_Register.bMem_RFU, 1'b1, Pkt.bMem_Mode_Register.bMem_TM, Pkt.bMem_Mode_Register.bMem_Latency, Pkt.bMem_Mode_Register.bMem_Burst_Type, Pkt.bMem_Mode_Register.bMem_Burst_Length});    
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
    
    pTBFM.Refresh;
    pTBFM.Nop(trfc);   
    pTBFM.Load_Mode(0, 'h0023);
    pTBFM.Nop(tmrd);
      
    pTBFM.Nop(CLK_200_CYLCES);
    
    
    pTBFM.Activate(0, 'h00000000); 
    pTBFM.Nop(trcd);     
    pTBFM.Write(0 /*bank*/, 0 /*col*/, 0 /*AutoPrecharge*/, { 4'h0, 4'h0, 4'h0, 4'hF} /*Dm*/, { 32'h0000_0000, 32'h0000_0000, 32'h3333_2222, 32'h1111_0000}/*Dq*/ );
    pTBFM.Nop(BL/2+twr);
    pTBFM.Read(0 /*Bank*/, 0 /*Col*/, 1/*AutoPrecharge*/);
    pTBFM.Nop(8);
    pTBFM.Activate(0, 'h00000000); 
    pTBFM.Nop(trcd);     
    pTBFM.Write(0 /*bank*/, 0 /*col*/, 0 /*AutoPrecharge*/, { 4'h0, 4'h0, 4'hF, 4'h0} /*Dm*/, { 32'h0000_0000, 32'h0000_0000, 32'h5555_5555, 32'h1111_0000}/*Dq*/ );
    pTBFM.Nop(BL/2+twr);
    pTBFM.Read(0 /*Bank*/, 0 /*Col*/, 1/*AutoPrecharge*/);
    pTBFM.Nop(8);
    pTBFM.Activate(0, 'h00000000); 
    pTBFM.Nop(trcd);
    pTBFM.Read(0 /*Bank*/, 0 /*Col*/, 0/*AutoPrecharge*/);
    pTBFM.Burst_Term();
    pTBFM.Nop(8);
    

    
     
  endtask: Run


endclass: DDR_Test2