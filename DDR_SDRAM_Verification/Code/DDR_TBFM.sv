/****************************************************************************************************/
// Title      : DDR SDRAM Tx Bus Functional Model
// File       : DDR_TBFM.sv
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 06-Aug-2011
// Notes                 : None 
/****************************************************************************************************/  


class DDR_TBFM;
  
  `include "DDR_ParametersPkg.sv"
     
  
  logic [3 : 0] bl;
  logic [2 : 0] rl;
     
  
/***********************************Local Definitions************************************************/ 
  
  
  `define LOAD_MODE_EN(x_interface)  x_interface.Cke = 'b1; x_interface.Cs_n = 'b0; x_interface.Ras_n = 'b0; x_interface.Cas_n = 'b0; x_interface.We_n = 'b0; x_interface.Ba = bank; x_interface.Addr = a;     
  `define REFRESH_EN(x_interface)    x_interface.Cke = 'b1; x_interface.Cs_n = 'b0; x_interface.Ras_n = 'b0; x_interface.Cas_n = 'b0; x_interface.We_n = 'b1;
  `define BURST_TERM_EN(x_interface) x_interface.Cke = 'b1; x_interface.Cs_n = 'b0; x_interface.Ras_n = 'b1; x_interface.Cas_n = 'b1; x_interface.We_n = 'b0;
  `define PRECHARGE_EN(x_interface)  x_interface.Cke = 'b1; x_interface.Cs_n = 'b0; x_interface.Ras_n = 'b0; x_interface.Cas_n = 'b1; x_interface.We_n = 'b0; x_interface.Ba = bank; x_interface.Addr = (pa<<10);
  `define ACTIVATE_EN(x_interface)   x_interface.Cke = 'b1; x_interface.Cs_n = 'b0; x_interface.Ras_n = 'b0; x_interface.Cas_n = 'b1; x_interface.We_n = 'b1; x_interface.Ba = bank; x_interface.Addr = row;
  `define WRITE_EN(x_interface)      x_interface.Cke = 'b1; x_interface.Cs_n = 'b0; x_interface.Ras_n = 'b1; x_interface.Cas_n = 'b0; x_interface.We_n = 'b0; x_interface.Ba = bank;
  `define READ_EN(x_interface)       x_interface.Cke = 'b1; x_interface.Cs_n = 'b0; x_interface.Ras_n = 'b1; x_interface.Cas_n = 'b0; x_interface.We_n = 'b1; x_interface.Ba = bank;
  `define NOP_EN(x_interface)        x_interface.Cke = 'b1; x_interface.Cs_n = 'b0; x_interface.Ras_n = 'b1; x_interface.Cas_n = 'b1; x_interface.We_n = 'b1;
  `define DESELECT_EN(x_interface)   x_interface.Cke = 'b1; x_interface.Cs_n = 'b1; x_interface.Ras_n = 'b1; x_interface.Cas_n = 'b1; x_interface.We_n = 'b1;
  `define CLK(x_interface)           x_interface.Clk
  `define ADDR(x_interface)          x_interface.Addr
  
  `define DQS(x_interface)           x_interface.Dqs
  `define DQ(x_interface)            x_interface.Dq
  `define DM(x_interface)            x_interface.Dm
  `define CKE(x_interface)           x_interface.Cke
/****************************************************************************************************/  
  
 
  //------------------------------------------ 
  // Instances
  
  //DDR_DUV Interface
  //virtual  DDR_Interface.DUV DDR_If;
  
  //DDR RM Interface
  //virtual interface DDR_Interface.RM DDR_rmIf;
  
  //DDR Tx Interface
  virtual interface DDR_Interface.TX DDR_If;  
 
  //------------------------------------------ 
  // Constructor: Connects the interface
  function new (virtual interface DDR_Interface DDR_TxIf);
   
     DDR_If   = DDR_TxIf;
          
  endfunction
  

  //------------------------------------------ 
  // Power Up Task
  task Power_Up;
  begin
    `CKE(DDR_If) <= 'b0;
    repeat(CLK_CYCLES_200US) @(negedge `CLK(DDR_If));
    Nop(1);
    `CKE(DDR_If) = 'b1;
    
    
  end
  endtask: Power_Up

  //------------------------------------------ 
  // Load Mode Task
  task Load_Mode;
    
    input [BA_BITS - 1 : 0]   bank;
    input [ADDR_BITS - 1 : 0] a; 
    begin
      
      case(bank)
        0: begin 
              $display("%m: [DDR_SDRAM][TBFM][Message] at time %t MEMORY MR/EMR: Mode Register Set", $time); 
              bl = (1<<a[2:0]);             
              case(a[6 : 4])
             `ifdef SAMSUNG_DDR
              'b010:  rl = 4;
              'b011:  rl = 6; 
              'b101:  rl = 3; 
              'b111:  rl = 5; 
              default: $display ("%m: [DDR_SDRAM][TBFM][Message] at time %t MEMORY MR/EMR: CAS Latency not supported", $time);
                    
              `else `define MICRON_DDR                   
              'b010  : rl = 4; 
              'b110  : rl = 5; 
              'b011  : rl = 6; 
              default : $display ("%%m: [DDR_SDRAM][TBFM][Message] at time %t MEMORY MR/EMR: CAS Latency not supported", $time);                  
              `endif
              endcase
           end  
           
        1: $display("%m: [DDR_SDRAM][TBFM][Message] at time %t MEMORY MR/EMR: Extended Mode Register Set", $time);
        default: $display("%m: [DDR_SDRAM][TBFM][Message] at time %t MEMORY MR/EMR: Reserved DDR SDRAM Command at time", $time);
      endcase
      `LOAD_MODE_EN(DDR_If)
      @(negedge `CLK(DDR_If));
            
    end
  endtask: Load_Mode  
  
  //------------------------------------------ 
  // Refresh Task
  task Refresh;
  begin
    
    `REFRESH_EN(DDR_If) 
    @(negedge `CLK(DDR_If)); 
    
  end
  endtask: Refresh
    
  //------------------------------------------ 
  // Burst_Term Task  
  task Burst_Term;
    
    integer i;
    begin
      
      `BURST_TERM_EN(DDR_If)  
      @(negedge `CLK(DDR_If));
      
    
    end
  endtask: Burst_Term
  
  
  //------------------------------------------ 
  // Precharge Task
  task Precharge;
    
    input [BA_BITS - 1 : 0]   bank;
    input pa;
    begin
      `PRECHARGE_EN(DDR_If)
       @(negedge `CLK(DDR_If));
    end
  endtask: Precharge
  
  
  //------------------------------------------ 
  // Activate Task
  task Activate;
  
    input [BA_BITS - 1 : 0]   bank;
    input [ADDR_BITS - 1 : 0] row;   
    begin
      
      `ACTIVATE_EN(DDR_If)
      @(negedge `CLK(DDR_If));  
    end
  endtask: Activate
  
  //------------------------------------------ 
  // Write Task
  task Write; //Note here: falta una linea de dqs_out debido a las graficas?
    
    input [BA_BITS - 1 : 0]   bank;
    input [COL_BITS - 1 : 0]  col;
    input pa;
    input [8*DM_BITS - 1 : 0] dm;
    input [8*DQ_BITS - 1 : 0] dq;
    reg [ADDR_BITS -1 : 0] a [1:0];  
    integer i; 
    begin
      
     
      `WRITE_EN(DDR_If) 
      a[0] = col& 10'h3FF;
      a[1] = (col>>10)<<11;
      `ADDR(DDR_If) = a[0] | a[1] | (pa<<10);
  	   
  	   for(i = 0; i<=bl; i++) begin
  	     
  	      if(i%2 == 0)  `DQS(DDR_If) <= #( (WL*tCK + i*tCK/2)*1000)  {DQS_BITS{1'b0}}; 
 	       else `DQS(DDR_If) <= #( (WL*tCK + i*tCK/2)*1000)  {DQS_BITS{1'b1}}; 
  	     
  	     `DQ(DDR_If) <= #( (WL*tCK + i*tCK/2 + tCK/4)*1000) dq>>i*DQ_BITS;
  	       
  	      case(i)
	         8: `DM(DDR_If) <= #( (WL*tCK + i*tCK/2 + tCK/4)*1000) dm[ 9*DM_BITS-1 :  8*DM_BITS]; 
	         7: `DM(DDR_If) <= #( (WL*tCK + i*tCK/2 + tCK/4)*1000) dm[ 8*DM_BITS-1 :  7*DM_BITS];
	         6: `DM(DDR_If) <= #( (WL*tCK + i*tCK/2 + tCK/4)*1000) dm[ 7*DM_BITS-1 :  6*DM_BITS];
	         5: `DM(DDR_If) <= #( (WL*tCK + i*tCK/2 + tCK/4)*1000) dm[ 6*DM_BITS-1 :  5*DM_BITS];
	         4: `DM(DDR_If) <= #( (WL*tCK + i*tCK/2 + tCK/4)*1000) dm[ 5*DM_BITS-1 :  4*DM_BITS];
	         3: `DM(DDR_If) <= #( (WL*tCK + i*tCK/2 + tCK/4)*1000) dm[ 4*DM_BITS-1 :  3*DM_BITS];
	         2: `DM(DDR_If) <= #( (WL*tCK + i*tCK/2 + tCK/4)*1000) dm[ 3*DM_BITS-1 :  2*DM_BITS];
	         1: `DM(DDR_If) <= #( (WL*tCK + i*tCK/2 + tCK/4)*1000) dm[ 2*DM_BITS-1 :  1*DM_BITS];
	         0: `DM(DDR_If) <= #( (WL*tCK + i*tCK/2 + tCK/4)*1000) dm[ 1*DM_BITS-1 :  0*DM_BITS];
  	      
	       endcase 
  	     
  	      
          	     
	    end
	    `DQS(DDR_If) <= #( (WL*tCK + bl*tCK/2 + tCK/2)*1000) {DQS_BITS{1'bz}};
  	   `DQ(DDR_If)  <= #( (WL*tCK + bl*tCK/2 + tCK/4)*1000) {DQ_BITS{1'bz}};
  	   `DM(DDR_If)  <= #( (WL*tCK + bl*tCK/2 + tCK/4)*1000) {DM_BITS{1'bz}};
 
      @(negedge `CLK(DDR_If));
       
    end
  endtask: Write
  
  
  //------------------------------------------ 
  // Read Task
  task Read;
  
    input [BA_BITS - 1 : 0]   bank;
    input [COL_BITS - 1 : 0]  col;
    input pa;
    reg [ADDR_BITS -1 : 0] a [1:0];
    begin
      
      `READ_EN(DDR_If) 
      a[0] = col& 10'h3FF;
      a[1] = (col>>10)<<11;
      `ADDR(DDR_If) = a[0] | a[1] | (pa<<10);
      @(negedge `CLK(DDR_If));
       
    end
    
  endtask: Read
  
 
  
  
  //------------------------------------------ 
  // Nop
  task Nop;
    
    input count;
    integer count;
    begin
      `NOP_EN(DDR_If) 
      repeat(count) @(negedge `CLK(DDR_If));
      
    end
    
  endtask: Nop
  
  
  //------------------------------------------ 
  // Deselect
  task Deselect;
   
    input count;
    integer count;
    begin
      `DESELECT_EN(DDR_If) 
      repeat(count) @(negedge `CLK(DDR_If));
      
    end
    
  endtask: Deselect
  

endclass: DDR_TBFM
