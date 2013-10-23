/****************************************************************************************************/
// Title      : DDR SDRAM Test3
// File       : DDR_Test3.sv
// Description: Test for writing and reading data in all memory locations
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 07-Aug-2011
// Notes                 : None 
/****************************************************************************************************/
import DDR_EnvPackage::*;

class DDR_Test3;

  `include "DDR_ParametersPkg.sv"

  //------------------------------------------ 
  // Instances References
  DDR_TBFM pTBFM;
  DDR_RBFM pRBFM;
  
  integer BL = 0;
  integer i = 0; //Counter for Banks
  integer j = 0; //Counter for Rows
  integer k = 0; //Counter for Columns
  integer n = 0; //Counter for each data in BL
  integer m = 0; //Counter for Columns+BL
  
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
  // Task Test3 Run
  task Run;
     
    DDR_Packet Pkt = new();
    
    $display("TEST 3"); 
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
    
    pTBFM.Nop(tmrd);  
    pTBFM.Nop(CLK_200_CYLCES); 
    
    // DDL Stabilization finished
    //-----------------------------------------------
    $display("%m: [DDR_SDRAM][TEST3][Message] at time %t MEMORY WRITE BURST", $time);
    for(i=0; i<4/*(2**BA_BITS)*/; i++) begin
     
        for(j=0; j<4/*(2**ADDR_BITS)*/; j++) begin
          pTBFM.Activate(i, j); 
          pTBFM.Nop(trcd);
            for(k=0; k<16/*(2**COL_BITS)*/; k = k+BL) begin
               assert(Pkt.randomize(Pkt.bMem_Data)); 
               pTBFM.Write(i /*bank*/, k /*col*/, 0 /*AutoPrecharge*/, Pkt.bMem_Data.bMem_DM /*Dm*/, Pkt.bMem_Data.bMem_Data/*Dq*/ );                
               //Stores in RFBM FIFO
                `ifdef TEST3
               for(n=0; n<BL;n++) begin
                  case(n)
                 
                  7: begin 
                        //pRBFM.Fifo_Write[m+7] = Pkt.bMem_Addr.bMem_Data[127:112];
                        pRBFM.Fifo_Write[m+7][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[15] ?  pRBFM.Fifo_Write[m+7][(DQ_BITS - 1)   : (DQ_BITS/2)]:Pkt.bMem_Data.bMem_Data[127 : 120];
                        pRBFM.Fifo_Write[m+7][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[14] ?  pRBFM.Fifo_Write[m+7][((DQ_BITS/2)-1) :           0]:Pkt.bMem_Data.bMem_Data[119 : 112];
                     end   
                  6: begin 
                       // pRBFM.Fifo_Write[m+6] = Pkt.bMem_Addr.bMem_Data[111: 96];
                        pRBFM.Fifo_Write[m+6][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[13] ?  pRBFM.Fifo_Write[m+6][(DQ_BITS - 1)   : (DQ_BITS/2)]:Pkt.bMem_Data.bMem_Data[111 : 104];
                        pRBFM.Fifo_Write[m+6][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[12] ?  pRBFM.Fifo_Write[m+6][((DQ_BITS/2)-1) :           0]:Pkt.bMem_Data.bMem_Data[103 : 96];
                     end
                  5: begin 
                        //pRBFM.Fifo_Write[m+5] = Pkt.bMem_Addr.bMem_Data[95 : 80];
                        pRBFM.Fifo_Write[m+5][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[11] ?  pRBFM.Fifo_Write[m+5][(DQ_BITS - 1)   : (DQ_BITS/2)]:Pkt.bMem_Data.bMem_Data[95 : 88];
                        pRBFM.Fifo_Write[m+5][((DQ_BITS/2)-1) : 0]           = Pkt.bMem_Data.bMem_DM[10] ?  pRBFM.Fifo_Write[m+5][((DQ_BITS/2)-1) :           0]:Pkt.bMem_Data.bMem_Data[87 : 80];
                     end   
                  4: begin 
                       // pRBFM.Fifo_Write[m+4] = Pkt.bMem_Addr.bMem_Data[79 : 64];
                        pRBFM.Fifo_Write[m+4][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[9]  ?  pRBFM.Fifo_Write[m+4][(DQ_BITS - 1)   : (DQ_BITS/2)]:Pkt.bMem_Data.bMem_Data[79 : 72];
                        pRBFM.Fifo_Write[m+4][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[8]  ?  pRBFM.Fifo_Write[m+4][((DQ_BITS/2)-1) :           0]:Pkt.bMem_Data.bMem_Data[71 : 64];
                     end   
                  3: begin
                        //pRBFM.Fifo_Write[m+3] = Pkt.bMem_Addr.bMem_Data[63 : 48];
                        pRBFM.Fifo_Write[m+3][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[7]  ?  pRBFM.Fifo_Write[m+3][(DQ_BITS - 1)   : (DQ_BITS/2)]:Pkt.bMem_Data.bMem_Data[63 : 56];
                        pRBFM.Fifo_Write[m+3][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[6]  ?  pRBFM.Fifo_Write[m+3][((DQ_BITS/2)-1) :           0]:Pkt.bMem_Data.bMem_Data[55 : 48];
                     end   
                  2: begin
                       // pRBFM.Fifo_Write[m+2] = Pkt.bMem_Addr.bMem_Data[47 : 32];
                        pRBFM.Fifo_Write[m+2][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[5]  ?  pRBFM.Fifo_Write[m+2][(DQ_BITS - 1)   : (DQ_BITS/2)]:Pkt.bMem_Data.bMem_Data[47 : 40];
                        pRBFM.Fifo_Write[m+2][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[4]  ?  pRBFM.Fifo_Write[m+2][((DQ_BITS/2)-1) :           0]:Pkt.bMem_Data.bMem_Data[39 : 32];
                     end   
                  1: begin
                       // pRBFM.Fifo_Write[m+1] = Pkt.bMem_Addr.bMem_Data[31 : 16];
                        pRBFM.Fifo_Write[m+1][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[3]  ?  pRBFM.Fifo_Write[m+1][(DQ_BITS - 1)   : (DQ_BITS/2)]:Pkt.bMem_Data.bMem_Data[31 : 24];
                        pRBFM.Fifo_Write[m+1][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[2]  ?  pRBFM.Fifo_Write[m+1][((DQ_BITS/2)-1) :           0]:Pkt.bMem_Data.bMem_Data[23 : 16];
                     end   
                  0: begin 
                       // pRBFM.Fifo_Write[m+0] = Pkt.bMem_Addr.bMem_Data[15 : 0];
                        pRBFM.Fifo_Write[m+0][(DQ_BITS - 1)   : (DQ_BITS/2)] = Pkt.bMem_Data.bMem_DM[1]  ?  pRBFM.Fifo_Write[m+0][(DQ_BITS - 1)   : (DQ_BITS/2)]:Pkt.bMem_Data.bMem_Data[15 : 8];
                        pRBFM.Fifo_Write[m+0][((DQ_BITS/2)-1) :           0] = Pkt.bMem_Data.bMem_DM[0]  ?  pRBFM.Fifo_Write[m+0][((DQ_BITS/2)-1) :           0]:Pkt.bMem_Data.bMem_Data[7  : 0];        
                     end
                  endcase
               end
               
               m = m+BL;
              `endif 
               pTBFM.Nop(BL/2-1); 
            end
          pTBFM.Nop(1+twr);  
          pTBFM.Precharge(i, 0); 
          pTBFM.Nop(trp);  
        end    
    
    end
     $display("%m: [DDR_SDRAM][TEST3][Message] at time %t MEMORY READ BURST", $time);
    for(i=0; i<4/*(2**BA_BITS)*/; i++) begin
     
        for(j=0; j<4/*(2**ADDR_BITS)*/; j++) begin
          pTBFM.Activate(i, j); 
          pTBFM.Nop(trcd);
            for(k=0; k<16/*(2**COL_BITS)*/; k = k+BL) begin
               pTBFM.Read(i /*Bank*/, k /*Col*/, 0/*AutoPrecharge*/);    
               pTBFM.Nop(BL/2-1);
            end
          pTBFM.Nop(twr-2);  
          pTBFM.Precharge(i, 0); 
          pTBFM.Nop(trp);  
        end   
    
    end   
        
     
  endtask: Run


endclass: DDR_Test3
