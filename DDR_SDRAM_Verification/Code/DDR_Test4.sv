/****************************************************************************************************/
// Title      : DDR SDRAM Test4
// File       : DDR_Test4.sv
// Description: Test for writing and reading data alternately in all memory locations
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 07-25-2011
// Notes                 : None 
/****************************************************************************************************/
import DDR_EnvPackage::*;

class DDR_Test4;

  `include "DDR_ParametersPkg.sv"

  //------------------------------------------ 
  // Instances References
  DDR_TBFM pTBFM;
  DDR_RBFM pRBFM;
  
 
  
  integer BL = 0;
  real    CL = 0;
  integer i = 0;
  integer j = 0;
  integer k = 0;
  integer n = 0;
  
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
  
  // Function for CAS Latency decode
  function real cas_latency_decoded;
  
    input [2 : 0] cas_latency;
    
    `ifdef SAMSUNG_DDR
    
      case(cas_latency)
      
        3'b010: cas_latency_decoded = 2;
        3'b011: cas_latency_decoded = 3;
        3'b101: cas_latency_decoded = 1.5;
        3'b111: cas_latency_decoded = 2.5;
        
      endcase
    
    `else `define MICRON_DDR
    
      case(cas_latency)
        
        3'b010: cas_latency_decoded = 2;
        3'b110: cas_latency_decoded = 2.5;
        3'b011: cas_latency_decoded = 3;
    
      endcase
    `endif
       

  endfunction

  //------------------------------------------ 
  // Task Test4 Run
  task Run;
     
    DDR_Packet Pkt = new();
    
    $display("TEST 4"); 
    //-----------------------------------------------
    // Power Up and Initialization of DDR SDRAM  
    
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
    
    // Power Up and Initialization of DDR SDRAM  finished
    //-----------------------------------------------
        
    pTBFM.Refresh;
    pTBFM.Nop(trfc);
    
    assert(Pkt.randomize(Pkt.bMem_Mode_Register));
    pTBFM.Load_Mode(0, {Pkt.bMem_Mode_Register.bMem_RFU, Pkt.bMem_Mode_Register.bMem_DLL_Reset, Pkt.bMem_Mode_Register.bMem_TM, Pkt.bMem_Mode_Register.bMem_Latency, Pkt.bMem_Mode_Register.bMem_Burst_Type, Pkt.bMem_Mode_Register.bMem_Burst_Length});
    BL = (1<<Pkt.bMem_Mode_Register.bMem_Burst_Length);
    pRBFM.bl = BL;
    CL = cas_latency_decoded(Pkt.bMem_Mode_Register.bMem_Latency);
    
    
    pTBFM.Nop(tmrd);
    pTBFM.Nop(CLK_200_CYLCES); 
    
    // DDL Stabilization finished
    //-----------------------------------------------
    
    $display("%m: [DDR_SDRAM][TEST4][Message] at time %t MEMORY WRITE to READ : Uninterrupting", $time);
    for(i=0; i<1/*(2**BA_BITS)*/; i++) begin
     
        for(j=0; j<1/*(2**ADDR_BITS)*/; j++) begin
          pTBFM.Activate(i, j); 
          pTBFM.Nop(trcd);
            for(k=1; k<16/*(2**COL_BITS)*/; k = k+BL) begin
               assert(Pkt.randomize(Pkt.bMem_Data)); 
               pTBFM.Write(i /*bank*/, k /*col*/, 0 /*AutoPrecharge*/, Pkt.bMem_Data.bMem_DM /*Dm*/, Pkt.bMem_Data.bMem_Data/*Dq*/ );                
               //Stores in RFBM FIFO
               `ifdef TEST4
               for(n=0; n<BL;n++) begin
                  case(n)
                  7: begin 
                        //pRBFM.Fifo_Write[7] = Pkt.bMem_Addr.bMem_Data[127:112];
                        pRBFM.Fifo_Write[7][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[15] ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[127 : 120];
                        pRBFM.Fifo_Write[7][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[14] ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[119 : 112];
                     end   
                  6: begin 
                       // pRBFM.Fifo_Write[6] = Pkt.bMem_Addr.bMem_Data[111: 96];
                        pRBFM.Fifo_Write[6][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[13] ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[111 : 104];
                        pRBFM.Fifo_Write[6][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[12] ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[103 : 96];
                     end
                  5: begin 
                        //pRBFM.Fifo_Write[5] = Pkt.bMem_Addr.bMem_Data[95 : 80];
                        pRBFM.Fifo_Write[5][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[11] ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[95 : 88];
                        pRBFM.Fifo_Write[5][((DQ_BITS/2)-1) : 0]           = Pkt.bMem_Data.bMem_DM[10] ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[87 : 80];
                     end   
                  4: begin 
                       // pRBFM.Fifo_Write[4] = Pkt.bMem_Addr.bMem_Data[79 : 64];
                        pRBFM.Fifo_Write[4][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[9]  ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[79 : 72];
                        pRBFM.Fifo_Write[4][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[8]  ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[71 : 64];
                     end   
                  3: begin
                        //pRBFM.Fifo_Write[3] = Pkt.bMem_Addr.bMem_Data[63 : 48];
                        pRBFM.Fifo_Write[3][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[7]  ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[63 : 56];
                        pRBFM.Fifo_Write[3][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[6]  ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[55 : 48];
                     end   
                  2: begin
                       // pRBFM.Fifo_Write[2] = Pkt.bMem_Addr.bMem_Data[47 : 32];
                        pRBFM.Fifo_Write[2][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[5]  ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[47 : 40];
                        pRBFM.Fifo_Write[2][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[4]  ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[39 : 32];
                     end   
                  1: begin
                       // pRBFM.Fifo_Write[1] = Pkt.bMem_Addr.bMem_Data[31 : 16];
                        pRBFM.Fifo_Write[1][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[3]  ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[31 : 24];
                        pRBFM.Fifo_Write[1][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[2]  ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[23 : 16];
                     end   
                  0: begin 
                       // pRBFM.Fifo_Write[0] = Pkt.bMem_Addr.bMem_Data[15 : 0];
                        pRBFM.Fifo_Write[0][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[1]  ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[15 : 8];
                        pRBFM.Fifo_Write[0][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[0]  ?  {(DQ_BITS/2){1'bx}} :Pkt.bMem_Data.bMem_Data[7  : 0];        
                     end
                  endcase
                
               end
               `endif
            
               pTBFM.Nop(BL/2+1); 
               pTBFM.Read(i /*Bank*/, k /*Col*/, 0/*AutoPrecharge*/);
               pTBFM.Nop(CL+BL/2-1);
            end
          pTBFM.Nop(1+twr);  
          pTBFM.Precharge(i, 0); 
          pTBFM.Nop(trp);  
        end    
    
    end
        
  endtask: Run


endclass: DDR_Test4


