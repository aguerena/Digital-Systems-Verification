/****************************************************************************************************/
// Title      : DDR SDRAM Test5
// File       : DDR_Test5.sv
// Description: Test for random command generation
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 07-25-2011
// Notes                 : None 
/****************************************************************************************************/
import DDR_EnvPackage::*;

class DDR_Test5;

  `include "DDR_ParametersPkg.sv"

  
  //------------------------------------------ 
  // Local Definition
  `define MEM_ADDR ( (addr_bank<<(ADDR_BITS+COL_BITS)) | (addr_row<<COL_BITS) | (addr_col) )
  
  //------------------------------------------ 
  // Instances References
  DDR_TBFM pTBFM;
  DDR_RBFM pRBFM;
  
  integer BL = 0;
  integer CL = 0;

  integer k = 0;  //Counter for Columns
  
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
  // Task Test5 Run
  task Run;
   
    DDR_Packet Pkt = new();
    $display("TEST 5");
    
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
    
    `ifdef TEST5
    
    $display("%m: [DDR_SDRAM][Test5][Message] at time %0t MEMORY : Random Command Generation", $time); 
    repeat(REPEAT_NUMBER) begin
      
      
      assert(Pkt.randomize(Pkt.bMem_Cmd_MR));
      if(!Pkt.bMem_Cmd_MR) begin
        assert(Pkt.randomize(Pkt.bMem_Mode_Register));
        pTBFM.Load_Mode(0, {Pkt.bMem_Mode_Register.bMem_RFU, Pkt.bMem_Mode_Register.bMem_DLL_Reset, Pkt.bMem_Mode_Register.bMem_TM, Pkt.bMem_Mode_Register.bMem_Latency, Pkt.bMem_Mode_Register.bMem_Burst_Type, Pkt.bMem_Mode_Register.bMem_Burst_Length});
        BL = (1<<Pkt.bMem_Mode_Register.bMem_Burst_Length);
        pRBFM.bl = BL;
        CL = cas_latency_decoded(Pkt.bMem_Mode_Register.bMem_Latency);
    
        pTBFM.Nop(tmrd);
        
      end
      else begin
      
         
      assert(Pkt.randomize(Pkt.bMem_Cmd_ACT_AREF)); 
      if( Pkt.bMem_Cmd_ACT_AREF  ) begin
        
         assert(Pkt.randomize(Pkt.bMem_Addr)); 
         $display("%m: [DDR_SDRAM][Test5][Message] at time %0t MEMORY : Activate", $time);
         pTBFM.Activate(Pkt.bMem_Addr.bMem_Bank, Pkt.bMem_Addr.bMem_Row);
         pTBFM.Nop(tras);
          
         assert(Pkt.randomize(Pkt.bMem_Cmd_WRITEA_WRITE_READA_READ_WRITEREAD_WRITEREADALT)); 
         case(Pkt.bMem_Cmd_WRITEA_WRITE_READA_READ_WRITEREAD_WRITEREADALT)
          
          //WRITE_READ ALTERNATE
          3'b101: begin 
            
            $display("%m: [DDR_SDRAM][Test5][Message] at time %0t MEMORY : Write Read Alternate", $time);
            
            for(k=0; k<(BL*4); k = k+BL) begin 
                      
              assert(Pkt.randomize(Pkt.bMem_Data));
              pTBFM.Write(Pkt.bMem_Addr.bMem_Bank/*bank*/, k /*col*/, 0 /*AutoPrecharge*/, Pkt.bMem_Data.bMem_DM /*Dm*/, Pkt.bMem_Data.bMem_Data/*Dq*/);
              Write_Memory(Pkt.bMem_Data.bMem_DM,Pkt.bMem_Data.bMem_Data,Pkt.bMem_Addr.bMem_Bank,Pkt.bMem_Addr.bMem_Row,k);
              
              pRBFM.Addr_bank = Pkt.bMem_Addr.bMem_Bank; pRBFM.Addr_row = Pkt.bMem_Addr.bMem_Row; pRBFM.Addr_col = k;
              pTBFM.Nop(BL/2+1);
              pTBFM.Read(Pkt.bMem_Addr.bMem_Bank /*Bank*/, k /*Col*/, 0/*AutoPrecharge*/);             
              pTBFM.Nop(CL+BL/2-1);
              
            end 
              
            pTBFM.Nop(1+twr);  
            pTBFM.Precharge(Pkt.bMem_Addr.bMem_Bank, 0); 
            pTBFM.Nop(trp); 
          
          end
          
          //WRITEA 
          3'b011: begin
            
             $display("%m: [DDR_SDRAM][Test5][Message] at time %0t MEMORY : Write with Auto Precharge", $time);
             
             assert(Pkt.randomize(Pkt.bMem_Data));
             pTBFM.Write(Pkt.bMem_Addr.bMem_Bank/*bank*/, 0 /*col*/, 1 /*AutoPrecharge*/, Pkt.bMem_Data.bMem_DM /*Dm*/, Pkt.bMem_Data.bMem_Data/*Dq*/);
             Write_Memory(Pkt.bMem_Data.bMem_DM,Pkt.bMem_Data.bMem_Data,Pkt.bMem_Addr.bMem_Bank,Pkt.bMem_Addr.bMem_Row,0);
             pTBFM.Nop(BL/2+twr+trp); //poner bl
             
          end
          
          //WRITE
          3'b010: begin
            
             $display("%m: [DDR_SDRAM][Test5][Message] at time %0t MEMORY : Write", $time);
             
             assert(Pkt.randomize(Pkt.bMem_Data));
             pTBFM.Write(Pkt.bMem_Addr.bMem_Bank/*bank*/, 0 /*col*/, 0 /*AutoPrecharge*/, Pkt.bMem_Data.bMem_DM /*Dm*/, Pkt.bMem_Data.bMem_Data/*Dq*/);
             Write_Memory(Pkt.bMem_Data.bMem_DM,Pkt.bMem_Data.bMem_Data,Pkt.bMem_Addr.bMem_Bank,Pkt.bMem_Addr.bMem_Row,0);
             pTBFM.Nop(BL/2+twr); //poner bl
             pTBFM.Precharge(Pkt.bMem_Addr.bMem_Bank, 0);
             pTBFM.Nop(trp);
             
          end 
          
          //READA
          3'b001: begin
            
            $display("%m: [DDR_SDRAM][Test5][Message] at time %0t MEMORY : Read with Auto Precharge", $time);
            pRBFM.Addr_bank = Pkt.bMem_Addr.bMem_Bank; pRBFM.Addr_row = Pkt.bMem_Addr.bMem_Row; pRBFM.Addr_col = 0;
            pTBFM.Read(Pkt.bMem_Addr.bMem_Bank /*Bank*/, 0 /*Col*/, 1/*AutoPrecharge*/);       
            //pTBFM.Nop(4/2+twr-2);
            pTBFM.Nop(BL/2+twr);
            
          end
          
          //READ
          3'b000: begin
            $display("%m: [DDR_SDRAM][Test5][Message] at time %0t MEMORY : Read", $time);
            pRBFM.Addr_bank = Pkt.bMem_Addr.bMem_Bank; pRBFM.Addr_row = Pkt.bMem_Addr.bMem_Row; pRBFM.Addr_col = 0;
            pTBFM.Read(Pkt.bMem_Addr.bMem_Bank /*Bank*/, 0 /*Col*/, 0/*AutoPrecharge*/);            
            pTBFM.Nop(CL+BL/2-1);
            
            assert(Pkt.randomize(Pkt.bMem_Cmd_READ_BST));
            if( !(Pkt.bMem_Cmd_READ_BST)) begin
              $display("%m: [DDR_SDRAM][Test5][Message] at time %0t MEMORY : Burst Terminate", $time);
              pTBFM.Burst_Term();
              pTBFM.Nop(CL+BL/2-1);
              pTBFM.Precharge(Pkt.bMem_Addr.bMem_Bank, 0);
              pTBFM.Nop(trp);  
            
            end
            else begin
                
              pTBFM.Precharge(Pkt.bMem_Addr.bMem_Bank, 0);
              pTBFM.Nop(trp);
                 
            end        
            
          end
                   
         default:    $display("%m: [DDR_SDRAM][Test5][Message] at time %0t MEMORY ERROR: Illegal Random Command", $time); 
         
         endcase
            
      end
           
      else begin
        
         $display("%m: [DDR_SDRAM][Test5][Message] at time %0t MEMORY : Auto Refresh", $time);
         pTBFM.Refresh();
         pTBFM.Nop(trfc); 
      
      end
  
      
    end
  end
   `endif
   
      
  endtask: Run

  //------------------------------------------ 
  // Function for Write Memory in RBFM
  function void Write_Memory;
   
   input [(8*DM_BITS) - 1 : 0] DM;
   input [(8*DQ_BITS) - 1 : 0] DQ;
   input [BA_BITS - 1 : 0] addr_bank;
   input [ADDR_BITS - 1 : 0] addr_row;
   input [COL_BITS - 1 : 0] addr_col; 
   integer n;
   
   `ifdef TEST5
    for(n=0; n<BL;n++) begin
                  case(n)
                 
                  7: begin 
                        
                        pRBFM.Fifo_Write[`MEM_ADDR+7][(DQ_BITS - 1)   : (DQ_BITS/2)] = DM[15] ?  pRBFM.Fifo_Write[`MEM_ADDR+7][(DQ_BITS - 1)   : (DQ_BITS/2)]:DQ[127 : 120];
                        pRBFM.Fifo_Write[`MEM_ADDR+7][((DQ_BITS/2)-1) :           0] = DM[14] ?  pRBFM.Fifo_Write[`MEM_ADDR+7][((DQ_BITS/2)-1) :           0]:DQ[119 : 112];
                     end   
                  6: begin 
                      
                        pRBFM.Fifo_Write[`MEM_ADDR+6][(DQ_BITS - 1)   : (DQ_BITS/2)] = DM[13] ?  pRBFM.Fifo_Write[`MEM_ADDR+6][(DQ_BITS - 1)   : (DQ_BITS/2)]:DQ[111 : 104];
                        pRBFM.Fifo_Write[`MEM_ADDR+6][((DQ_BITS/2)-1) :           0] = DM[12] ?  pRBFM.Fifo_Write[`MEM_ADDR+6][((DQ_BITS/2)-1) :           0]:DQ[103 : 96];
                     end
                  5: begin 
                        
                        pRBFM.Fifo_Write[`MEM_ADDR+5][(DQ_BITS - 1)   : (DQ_BITS/2)] = DM[11] ?  pRBFM.Fifo_Write[`MEM_ADDR+5][(DQ_BITS - 1)   : (DQ_BITS/2)]:DQ[95 : 88];
                        pRBFM.Fifo_Write[`MEM_ADDR+5][((DQ_BITS/2)-1) : 0]           = DM[10] ?  pRBFM.Fifo_Write[`MEM_ADDR+5][((DQ_BITS/2)-1) :           0]:DQ[87 : 80];
                     end   
                  4: begin 
                      
                        pRBFM.Fifo_Write[`MEM_ADDR+4][(DQ_BITS - 1)   : (DQ_BITS/2)] = DM[9]  ?  pRBFM.Fifo_Write[`MEM_ADDR+4][(DQ_BITS - 1)   : (DQ_BITS/2)]:DQ[79 : 72];
                        pRBFM.Fifo_Write[`MEM_ADDR+4][((DQ_BITS/2)-1) :           0] = DM[8]  ?  pRBFM.Fifo_Write[`MEM_ADDR+4][((DQ_BITS/2)-1) :           0]:DQ[71 : 64];
                     end   
                  3: begin
                       
                        pRBFM.Fifo_Write[`MEM_ADDR+3][(DQ_BITS - 1)   : (DQ_BITS/2)] = DM[7]  ?  pRBFM.Fifo_Write[`MEM_ADDR+3][(DQ_BITS - 1)   : (DQ_BITS/2)]:DQ[63 : 56];
                        pRBFM.Fifo_Write[`MEM_ADDR+3][((DQ_BITS/2)-1) :           0] = DM[6]  ?  pRBFM.Fifo_Write[`MEM_ADDR+3][((DQ_BITS/2)-1) :           0]:DQ[55 : 48];
                     end   
                  2: begin
                      
                        pRBFM.Fifo_Write[`MEM_ADDR+2][(DQ_BITS - 1)   : (DQ_BITS/2)] = DM[5]  ?  pRBFM.Fifo_Write[`MEM_ADDR+2][(DQ_BITS - 1)   : (DQ_BITS/2)]:DQ[47 : 40];
                        pRBFM.Fifo_Write[`MEM_ADDR+2][((DQ_BITS/2)-1) :           0] = DM[4]  ?  pRBFM.Fifo_Write[`MEM_ADDR+2][((DQ_BITS/2)-1) :           0]:DQ[39 : 32];
                     end   
                  1: begin
                      
                        pRBFM.Fifo_Write[`MEM_ADDR+1][(DQ_BITS - 1)   : (DQ_BITS/2)] = DM[3]  ?  pRBFM.Fifo_Write[`MEM_ADDR+1][(DQ_BITS - 1)   : (DQ_BITS/2)]:DQ[31 : 24];
                        pRBFM.Fifo_Write[`MEM_ADDR+1][((DQ_BITS/2)-1) :           0] = DM[2]  ?  pRBFM.Fifo_Write[`MEM_ADDR+1][((DQ_BITS/2)-1) :           0]:DQ[23 : 16];
                     end   
                  0: begin 
                      
                        pRBFM.Fifo_Write[`MEM_ADDR+0][(DQ_BITS - 1)   : (DQ_BITS/2)] = DM[1]  ?  pRBFM.Fifo_Write[`MEM_ADDR+0][(DQ_BITS - 1)   : (DQ_BITS/2)]:DQ[15 : 8];
                        pRBFM.Fifo_Write[`MEM_ADDR+0][((DQ_BITS/2)-1) :           0] = DM[0]  ?  pRBFM.Fifo_Write[`MEM_ADDR+0][((DQ_BITS/2)-1) :           0]:DQ[7  : 0];        
                     end
                  endcase
      end 
     `endif
  
  endfunction 
  

endclass: DDR_Test5
