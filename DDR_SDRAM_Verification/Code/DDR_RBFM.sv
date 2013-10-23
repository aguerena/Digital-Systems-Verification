/****************************************************************************************************/
// Title      : DDR SDRAM Rx Bus Functional Model
// File       : DDR_RBFM.sv
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 07-25-2011
// Notes                 : None 
/****************************************************************************************************/ 
import DDR_EnvPackage::*;

class DDR_RBFM;

  `include "DDR_ParametersPkg.sv"
  //------------------------------------------ 
  // Interfaces
  
  virtual interface DDR_Interface.MONITOR DDR_If;
  virtual interface DDR_InterfaceInt.MONITOR DDR_IntIf;
  
  //------------------------------------------ 
  // Events declarations
  event e_PowerUp;
  event e_Write;
  event e_Read;
  event e_Active;
  event e_Precharge;
  event e_Burst_terminate;
  event e_Command;
  event e_Read_Rdy;
  event e_Dqs_Read; 
  

  integer bl; //cambiar aqui
  
  //------------------------------------------
  // Counters for Write-Read Checkers
  integer n = 0; 
  integer i = 0;
  
  //------------------------------------------
  // Logic types for data processing and coverage
  `ifdef TEST3  
  logic  [DQ_BITS - 1 : 0] Fifo_Write  [0:(1<<full_mem_bits)-1]; 
  `endif
  
  `ifdef TEST4  
  logic  [DQ_BITS - 1 : 0] Fifo_Write  [0:MAX_BL-1];
  `endif
  
  `ifdef TEST5
  logic    [DQ_BITS - 1 : 0] Fifo_Write  [0:(1<<full_mem_bits)-1];
  logic    [BA_BITS - 1 : 0] Addr_bank;
  logic  [ADDR_BITS - 1 : 0] Addr_row;
  logic   [COL_BITS - 1 : 0] Addr_col;
  `define RX_MEM_ADDR(col_counter) ( (Addr_bank<<(ADDR_BITS+COL_BITS)) | (Addr_row<<COL_BITS) | (Addr_col+col_counter) )
  `endif
  
  logic  [DQ_BITS -  1 : 0] Fifo_Read     [0:MAX_BL-1]; 
  logic   Fifo_DqsL_Read [0:MAX_BL+1]; 
  logic   Fifo_DqsH_Read [0:MAX_BL+1]; 
 
 
  logic rbfm_Write;
  logic rbfm_Write_Burst_Type;
  logic [3:0] rbfm_Write_Burst_Length;
  logic rbfm_Read;
  logic rbfm_Read_Burst_Type;
  logic [3:0] rbfm_Read_Burst_Length;
  logic [1:0] rbfm_Active;
  logic [2:0] rbfm_Precharge;
  logic [2:0] rbfm_Burst_terminate;
  logic [2:0] rbfm_Read_CAS_Latency;
  logic rbfm_PowerUp; 
  logic [ADDR_BITS -1 : 0] rbfm_Active_Row;
  logic [6:0] rbfm_Command;
// logic rbfm_burst_type;
  
  
  //------------------------------------------ 
  // Constructor: Connects the interface
  function new( virtual interface DDR_Interface DDR_RxIf, virtual interface DDR_InterfaceInt DDR_RxIntIf);
    DDR_If    = DDR_RxIf; 
    DDR_IntIf = DDR_RxIntIf; 
  endfunction
  


  //------------------------------------------ 
  // RBFM Tasks 


/*******************************************************************************************************/  
  // Task RunMonitor 
  task RunMonitor; 
 
    fork
    
        // Monitor for Commands
        forever @(posedge DDR_If.Clk) begin
        
          rbfm_Command = {DDR_If.Cs_n, DDR_If.Ras_n, DDR_If.Cas_n, DDR_If.We_n, DDR_If.Ba[1], DDR_If.Ba[0], DDR_If.Addr[10] }; 
          -> e_Command;
        
        end
    
        // Monitor for Power Up
        forever @(DDR_IntIf.power_up_done) begin
           -> e_PowerUp;
           rbfm_PowerUp = DDR_IntIf.power_up_done;
        end
       
        // Monitor for Read
        forever @(posedge DDR_IntIf.Read_enable) begin
             rbfm_Read_Burst_Type   = DDR_IntIf.burst_type;
             rbfm_Read              = DDR_IntIf.Read_enable;
             rbfm_Read_CAS_Latency  = DDR_IntIf.cas_latency_x2;
             rbfm_Read_Burst_Length = DDR_IntIf.burst_length;
             -> e_Read;
        end
        
        // Monitor for Write
        forever @(posedge DDR_IntIf.Write_enable) begin
             rbfm_Write_Burst_Type   = DDR_IntIf.burst_type;
             rbfm_Write              = DDR_IntIf.Write_enable;
             rbfm_Write_Burst_Length = DDR_IntIf.burst_length;
             -> e_Write;
        end
        
        // Monitor for Active
        forever @(posedge DDR_IntIf.Active_enable) begin
             rbfm_Active = {DDR_If.Ba[1], DDR_If.Ba[0]};
             rbfm_Active_Row = DDR_If.Addr;
             -> e_Active;
        end
        
        // Monitor for Precharge
        forever @(posedge DDR_IntIf.Precharge_enable) begin
             rbfm_Precharge = {DDR_If.Addr[10], DDR_If.Ba[1], DDR_If.Ba[0]};
             -> e_Precharge;
        end 
        
        // Monitor for Burst Terminate
        forever @(posedge DDR_IntIf.Burst_terminate_enable) begin
             rbfm_Burst_terminate = DDR_IntIf.cas_latency_x2;
             
            @(posedge DDR_If.Clk); 
             case(DDR_IntIf.cas_latency_x2)
             `ifdef SAMSUNG_DDR
                3: begin
                      @(posedge DDR_If.Clk);
                      @(posedge DDR_If.Clk);
                       -> e_Burst_terminate;
                   end
              `endif 
                4: begin
                      @(posedge DDR_If.Clk);
                      @(posedge DDR_If.Clk);
                      @(negedge DDR_If.Clk);
                       -> e_Burst_terminate;
                   end
                5: begin
                      @(posedge DDR_If.Clk);
                      @(posedge DDR_If.Clk);
                      @(posedge DDR_If.Clk);
                       -> e_Burst_terminate;
                   end   
                6: begin
                      @(posedge DDR_If.Clk);
                      @(posedge DDR_If.Clk);
                      @(posedge DDR_If.Clk);
                      @(negedge DDR_If.Clk);
                       $display("%m: [DDR_SDRAM][RBFM][Message] at time %t MONITOR:  Burst Terminate Detected", $time);
                       -> e_Burst_terminate;
                   end  
                default: $display("%m: [DDR_SDRAM][RBFM][Error] at time %t MONITOR: CAS Latency not supported ", $time);           
              endcase
             
            
        end
         
         
         // Monitor for DQS 
        `ifdef TEST3
        forever @( posedge DDR_IntIf.Data_out_enable) begin
           
           
          if(DDR_IntIf.cas_latency_x2 == 5 || DDR_IntIf.cas_latency_x2 == 3)begin
            
             {Fifo_DqsH_Read[0], Fifo_DqsL_Read[0]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
             @(negedge DDR_If.Clk);
             {Fifo_DqsH_Read[1], Fifo_DqsL_Read[1]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;  
          
             if( bl == 4 || bl == 8) begin
                @(posedge DDR_If.Clk);
                {Fifo_DqsH_Read[2], Fifo_DqsL_Read[2]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
                @(negedge DDR_If.Clk);
                {Fifo_DqsH_Read[3], Fifo_DqsL_Read[3]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
              end 
              if( bl == 8) begin
                @(posedge DDR_If.Clk);
                {Fifo_DqsH_Read[4], Fifo_DqsL_Read[4]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
                @(negedge DDR_If.Clk);
                {Fifo_DqsH_Read[5], Fifo_DqsL_Read[5]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;
                @(posedge DDR_If.Clk);
                {Fifo_DqsH_Read[6], Fifo_DqsL_Read[6]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
                @(negedge DDR_If.Clk);
                {Fifo_DqsH_Read[7], Fifo_DqsL_Read[7]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;  
              end 
               
          end
          else begin 
            
              {Fifo_DqsH_Read[0], Fifo_DqsL_Read[0]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
              @(posedge DDR_If.Clk);
              {Fifo_DqsH_Read[1], Fifo_DqsL_Read[1]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;  
          
              if( bl == 4 || bl == 8) begin
                @(negedge DDR_If.Clk);
                {Fifo_DqsH_Read[2], Fifo_DqsL_Read[2]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
                @(posedge DDR_If.Clk);
                {Fifo_DqsH_Read[3], Fifo_DqsL_Read[3]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
              end 
              if( bl == 8) begin
               @(negedge DDR_If.Clk);
               {Fifo_DqsH_Read[4], Fifo_DqsL_Read[4]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
               @(posedge DDR_If.Clk);
                {Fifo_DqsH_Read[5], Fifo_DqsL_Read[5]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;
                @(negedge DDR_If.Clk);
                {Fifo_DqsH_Read[6], Fifo_DqsL_Read[6]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
                @(posedge DDR_If.Clk);
                {Fifo_DqsH_Read[7], Fifo_DqsL_Read[7]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;  
              end 
          
          end
          $display("%m: [DDR_SDRAM][RBFM][Message] at time %t MONITOR:  Read Detected", $time); 
           -> e_Dqs_Read;
          // rbfm_burst_type = DDR_IntIf.burst_type;  
           
        end 
        `else
        
        forever @( negedge DDR_IntIf.Dqs_out) begin
         
          if(DDR_IntIf.cas_latency_x2 == 5 || DDR_IntIf.cas_latency_x2 == 3)begin
            
            {Fifo_DqsH_Read[0], Fifo_DqsL_Read[0]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
            @(negedge DDR_If.Clk);
            {Fifo_DqsH_Read[1], Fifo_DqsL_Read[1]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;  
          
            if( bl == 2 || bl == 4 || bl == 8) begin
              @(posedge DDR_If.Clk);
              {Fifo_DqsH_Read[2], Fifo_DqsL_Read[2]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
              @(negedge DDR_If.Clk);
              {Fifo_DqsH_Read[3], Fifo_DqsL_Read[3]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
            end
            if( bl == 4 || bl == 8) begin
              @(posedge DDR_If.Clk);
              {Fifo_DqsH_Read[4], Fifo_DqsL_Read[4]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
              @(negedge DDR_If.Clk);
              {Fifo_DqsH_Read[5], Fifo_DqsL_Read[5]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
            end
            if( bl == 8) begin
              @(posedge DDR_If.Clk);
              {Fifo_DqsH_Read[6], Fifo_DqsL_Read[6]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
              @(negedge DDR_If.Clk);
              {Fifo_DqsH_Read[7], Fifo_DqsL_Read[7]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;
              @(posedge DDR_If.Clk);
              {Fifo_DqsH_Read[8], Fifo_DqsL_Read[8]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
              @(negedge DDR_If.Clk);
              {Fifo_DqsH_Read[9], Fifo_DqsL_Read[9]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;  
            end
       
          end
          else begin
          
            {Fifo_DqsH_Read[0], Fifo_DqsL_Read[0]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
            @(posedge DDR_If.Clk);
            {Fifo_DqsH_Read[1], Fifo_DqsL_Read[1]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;  
          
            if( bl == 2 || bl == 4 || bl == 8) begin
              @(negedge DDR_If.Clk);
              {Fifo_DqsH_Read[2], Fifo_DqsL_Read[2]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
              @(posedge DDR_If.Clk);
              {Fifo_DqsH_Read[3], Fifo_DqsL_Read[3]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
            end
            if( bl == 4 || bl == 8) begin
              @(negedge DDR_If.Clk);
              {Fifo_DqsH_Read[4], Fifo_DqsL_Read[4]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
              @(posedge DDR_If.Clk);
              {Fifo_DqsH_Read[5], Fifo_DqsL_Read[5]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
            end
            if( bl == 8) begin
              @(negedge DDR_If.Clk);
              {Fifo_DqsH_Read[6], Fifo_DqsL_Read[6]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
              @(posedge DDR_If.Clk);
              {Fifo_DqsH_Read[7], Fifo_DqsL_Read[7]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;
              @(negedge DDR_If.Clk);
              {Fifo_DqsH_Read[8], Fifo_DqsL_Read[8]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ; 
              @(posedge DDR_If.Clk);
              {Fifo_DqsH_Read[9], Fifo_DqsL_Read[9]} = {DDR_IntIf.Dqs_out[1], DDR_IntIf.Dqs_out[0]} ;  
            end
          
          end
           $display("%m: [DDR_SDRAM][RBFM][Message] at time %t MONITOR:  Read Detected", $time);
           -> e_Dqs_Read;
          // rbfm_burst_type = DDR_IntIf.burst_type;  
           
        end 
        `endif
    
         // Monitor for DQ
       
        forever @(posedge DDR_IntIf.Data_out_enable) begin
         
         if(DDR_IntIf.cas_latency_x2 == 5 || DDR_IntIf.cas_latency_x2 == 3)begin
            
           if( bl == 2 || bl == 4 || bl == 8) begin
                 Fifo_Read[0] = DDR_IntIf.Dq_out;
                 @(negedge DDR_If.Clk);
                 Fifo_Read[1] = DDR_IntIf.Dq_out;
           end
           if( bl == 4 || bl == 8) begin
                 @(posedge DDR_If.Clk);
                 Fifo_Read[2] = DDR_IntIf.Dq_out;
                 @(negedge DDR_If.Clk);
                 Fifo_Read[3] = DDR_IntIf.Dq_out;      
           end
           if( bl == 8) begin
                 @(posedge DDR_If.Clk);
                 Fifo_Read[4] = DDR_IntIf.Dq_out;
                 @(negedge DDR_If.Clk);
                 Fifo_Read[5] = DDR_IntIf.Dq_out;
                 @(posedge DDR_If.Clk);
                 Fifo_Read[6] = DDR_IntIf.Dq_out;
                 @(negedge DDR_If.Clk);
                 Fifo_Read[7] = DDR_IntIf.Dq_out;
            end
            
          end
          
          else begin
            
           if( bl == 2 || bl == 4 || bl == 8) begin
                 Fifo_Read[0] = DDR_IntIf.Dq_out;
                 @(posedge DDR_If.Clk);
                 Fifo_Read[1] = DDR_IntIf.Dq_out;
           end
           if( bl == 4 || bl == 8) begin
                 @(negedge DDR_If.Clk);
                 Fifo_Read[2] = DDR_IntIf.Dq_out;
                 @(posedge DDR_If.Clk);
                 Fifo_Read[3] = DDR_IntIf.Dq_out;      
           end
           if( bl == 8) begin
                 @(negedge DDR_If.Clk);
                 Fifo_Read[4] = DDR_IntIf.Dq_out;
                 @(posedge DDR_If.Clk);
                 Fifo_Read[5] = DDR_IntIf.Dq_out;
                 @(negedge DDR_If.Clk);
                 Fifo_Read[6] = DDR_IntIf.Dq_out;
                 @(posedge DDR_If.Clk);
                 Fifo_Read[7] = DDR_IntIf.Dq_out;
            end
            
          end
          
             
          `ifdef TEST3 
            i = i+bl;
          `endif
          $display("%m: [DDR_SDRAM][RBFM][Message] at time %t MONITOR:  Read Dqs Detected", $time);
          -> e_Read_Rdy;
      
        end          
      
    
    join  
            
  endtask:RunMonitor;

/*******************************************************************************************************/
  // Task RunChecker 

  task RunChecker;

    fork
    
       // Checker for Power Up
       forever @(e_PowerUp) begin
        $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER: Power Up and Initialization Sequence was Executed Correctly", $time);
          
       end 
       
       // Checker for Burst_Terminate
       forever @(e_Burst_terminate) begin
  
          if( (!DDR_IntIf.Dq_out) || (DDR_IntIf.Dq_out)    )
               $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER: Burst Terminate was Executed Incorrectly", $time);
          else
               $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER: Burst Terminate was Executed Correctly", $time);
       end
    
      // Checker for Write-Read
      `ifdef TEST3
       forever @(e_Read_Rdy) begin
     
          
          for(n=0; n<bl;n++) begin
            $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER Data %0d: READ %h - WRITE %h : %s", $time, n, Fifo_Read[n], Fifo_Write[i+n-bl], ( (Fifo_Read[n] == Fifo_Write[i+n-bl]) ? "CORRECT":"INCORRECT")  );
          end 
       end          
      `endif 
   
      `ifdef TEST4
       forever @(e_Read_Rdy) begin
          
       
          for(n=0; n<bl;n++) begin
            $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER Data %0d: READ %h - WRITE %h : %s", $time, n, Fifo_Read[n], Fifo_Write[n], ( (Fifo_Read[n] == Fifo_Write[n]) ? "CORRECT":"INCORRECT")  );
          end
       end          
      `endif 
      
       
      `ifdef TEST5
       forever @(e_Read_Rdy) begin
          
       
          for(n=0; n<bl;n++) begin
            $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER Data %0d: READ %h - WRITE %h : %s", $time, n, Fifo_Read[n], Fifo_Write[`RX_MEM_ADDR(n)], ( (Fifo_Read[n] == Fifo_Write[`RX_MEM_ADDR(n)]) ? "CORRECT":"INCORRECT")  );
          end
       end          
      `endif
      
       // Checker for Read DQS
       forever @(e_Dqs_Read) begin
          
 
           `ifdef TEST3
            if(bl == 2)
           $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER: Dqs for Burst Length = %0d : where DqsH = %p is and DqsL = %p is %s", $time, bl,Fifo_DqsH_Read[0:2-1], Fifo_DqsL_Read[0:2-1],
           (({Fifo_DqsH_Read[0],Fifo_DqsH_Read[1]}) == ({1'b1,1'b0})) ? "CORRECT":"INCORRECT");
          else if (bl == 4)
            $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER: Dqs for Burst Length = %0d : where DqsH = %p is and DqsL = %p is %s", $time, bl,Fifo_DqsH_Read[0:4-1], Fifo_DqsL_Read[0:4-1],
           (({Fifo_DqsH_Read[0],Fifo_DqsH_Read[1],Fifo_DqsH_Read[2],Fifo_DqsH_Read[3]}) == ({1'b1,1'b0,1'b1,1'b0})) ? "CORRECT":"INCORRECT");
          else if (bl == 8)
            $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER: Dqs for Burst Length = %0d : where DqsH = %p is and DqsL = %p is %s", $time, bl,Fifo_DqsH_Read[0:8-1], Fifo_DqsL_Read[0:8-1],
           (({Fifo_DqsH_Read[0],Fifo_DqsH_Read[1],Fifo_DqsH_Read[2],Fifo_DqsH_Read[3],Fifo_DqsH_Read[4],Fifo_DqsH_Read[5],Fifo_DqsH_Read[6],Fifo_DqsH_Read[7]}) == ({1'b1,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b0})) ? "CORRECT":"INCORRECT");
                               
           `else 
                
           if(bl == 2)
           $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER: Dqs for Burst Length = %0d : where DqsH = %p is and DqsL = %p is %s", $time, bl,Fifo_DqsH_Read[0:2+1], Fifo_DqsL_Read[0:2+1],
           (({Fifo_DqsH_Read[0],Fifo_DqsH_Read[1],Fifo_DqsH_Read[2],Fifo_DqsH_Read[3]}) == ({1'b0,1'b0,1'b1,1'b0})) ? "CORRECT":"INCORRECT");
          else if (bl == 4)
            $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER: Dqs for Burst Length = %0d : where DqsH = %p is and DqsL = %p is %s", $time, bl,Fifo_DqsH_Read[0:4+1], Fifo_DqsL_Read[0:4+1],
           (({Fifo_DqsH_Read[0],Fifo_DqsH_Read[1],Fifo_DqsH_Read[2],Fifo_DqsH_Read[3],Fifo_DqsH_Read[4],Fifo_DqsH_Read[5]}) == ({1'b0,1'b0,1'b1,1'b0,1'b1,1'b0})) ? "CORRECT":"INCORRECT");
          else if (bl == 8)
            $display("%m: [DDR_SDRAM][RBFM][Message] at time %t CHECKER: Dqs for Burst Length = %0d : where DqsH = %p is and DqsL = %p is %s", $time, bl,Fifo_DqsH_Read[0:8+1], Fifo_DqsL_Read[0:8+1],
           (({Fifo_DqsH_Read[0],Fifo_DqsH_Read[1],Fifo_DqsH_Read[2],Fifo_DqsH_Read[3],Fifo_DqsH_Read[4],Fifo_DqsH_Read[5],Fifo_DqsH_Read[6],Fifo_DqsH_Read[7],Fifo_DqsH_Read[8],Fifo_DqsH_Read[9]}) == ({1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1,1'b0})) ? "CORRECT":"INCORRECT");
           
           `endif 
       end     
      
   
   join 
     
   
  endtask: RunChecker

endclass: DDR_RBFM


//logic rbfm_burst2_type;
  /*task RunMonitorCov(DDR_Packet Pkt);
  
    rbfm_burst2_type = Pkt.bMem_Mode_Register.bMem_Burst_Type;
  
  endtask */ 


