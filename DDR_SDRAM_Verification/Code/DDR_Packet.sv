/****************************************************************************************************/
// Title      : DDR SDRAM Generation Packet
// File       : DDR_Packet.sv
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 06-Aug-2011
// Notes                 : None 
/****************************************************************************************************/
class DDR_Packet;

  `include "DDR_ParametersPkg.sv"

/***********************************Local Definitions************************************************/ 

/*
  AREF  = Auto Refresh
  EMR   = Extended Mode Register
  MR    = Mode Register
  ACT   = Active
  PRE   = Precharge
  BST   = Burst Terminate
  READ  = Read
  READA = Read with Auto Precharge
  WRITE = Write
  WRITEA= Write with Auto Precharge
*/

  `define SEQUENTIAL      1'b0
  `define INTERLEAVE      1'b1
  `define NORMAL_MODE     1'b0
  `define TEST_MODE       1'b1
  `define BURST_LENGTH_2 3'b001
  `define BURST_LENGTH_4 3'b010
  `define BURST_LENGTH_8 3'b011
  `define CAS_LATENCY_1_5_S  3'b101
  `define CAS_LATENCY_2_S    3'b010 
  `define CAS_LATENCY_2_5_S  3'b111
  `define CAS_LATENCY_3_S    3'b101
  `define CAS_LATENCY_2_M    3'b010
  `define CAS_LATENCY_2_5_M  3'b110
  `define CAS_LATENCY_3_M    3'b011
  
   
/****************************************************************************************************/   

  //------------------------------------------ 
  // Random structs and variables 

  rand struct packed{ 
       bit [BA_BITS - 1 : 0]   bMem_Bank;
       bit [ADDR_BITS - 1 : 0] bMem_Row;
       bit [COL_BITS - 1 : 0]  bMem_Col;
} bMem_Addr; 

  rand struct packed{ 
       bit [(8*DQ_BITS) - 1 : 0]     bMem_Data;
       bit [(8*DM_BITS) - 1 : 0]     bMem_DM;
} bMem_Data; 
  
  rand struct packed{ 
       bit [3 : 0]             bMem_RFU;
       bit                     bMem_DLL_Reset;
       bit                     bMem_TM;
       bit [2 : 0]             bMem_Latency;
       bit                     bMem_Burst_Type;
       bit [2 : 0]             bMem_Burst_Length;
} bMem_Mode_Register; 

      rand bit                      bMem_Cmd_ACT_AREF;
      rand bit [2 : 0]              bMem_Cmd_WRITEA_WRITE_READA_READ_WRITEREAD_WRITEREADALT;
      rand bit                      bMem_Cmd_READ_BST;
      rand bit                      bMem_Cmd_MR;      

  
  
  //------------------------------------------ 
  // Constraints 
    
  constraint cACT_AREF     { bMem_Cmd_ACT_AREF     dist{1'b1:=9, 1'b0:=1};    };   
  constraint cREAD_BST     { bMem_Cmd_READ_BST     dist{1'b1:=7, 1'b0:=3};    };
  constraint cMR           { bMem_Cmd_MR           dist{1'b1:=9, 1'b0:=2};    };
  constraint cWRITEA_WRITE_READA_READ_WRITEREAD_WRITEREADALT {  bMem_Cmd_WRITEA_WRITE_READA_READ_WRITEREAD_WRITEREADALT dist{3'b101:=2, 3'b011:=2, 3'b010:=3, 3'b001:=2, 3'b000:=3 };    };
  
  
  // Constraints for bMem_Mode_Register elements
  
  constraint cRFU { bMem_Mode_Register.bMem_RFU        == 4'b0000; };
  constraint cTM  { bMem_Mode_Register.bMem_TM         == `NORMAL_MODE;    };
  constraint cDLLR{ bMem_Mode_Register.bMem_DLL_Reset  == 1'b0;    };
  
  `ifdef RANDOM_BURST_TYPE
      constraint cBT  { bMem_Mode_Register.bMem_Burst_Type dist{`SEQUENTIAL:=9, `INTERLEAVE:=1};    };    
  `else `ifdef FIXED_BURST_INTERLEAVE_TYPE
      constraint cBT  { bMem_Mode_Register.bMem_Burst_Type == `INTERLEAVE;    };
  `else `define FIXED_BURST_SEQUENTIAL_TYPE
      constraint cBT  { bMem_Mode_Register.bMem_Burst_Type == `SEQUENTIAL;    };    
  `endif `endif
  
    
  `ifdef RANDOM_BURST_LENGTH
      constraint cBL  { bMem_Mode_Register.bMem_Burst_Length inside {[1:3]};};   
  `else `ifdef FIXED_BURST_LENGTH_2
      constraint cBL  { bMem_Mode_Register.bMem_Burst_Length == `BURST_LENGTH_2;};
  `else `ifdef FIXED_BURST_LENGTH_8
      constraint cBL  { bMem_Mode_Register.bMem_Burst_Length == `BURST_LENGTH_8;}; 
  `else `define FIXED_BURST_LENGTH_4
      constraint cBL  { bMem_Mode_Register.bMem_Burst_Length == `BURST_LENGTH_4;};
  `endif `endif `endif
  
 
  `ifdef RANDOM_CAS_LATENCY
       `ifdef SAMSUNG_DDR
       constraint cL   { bMem_Mode_Register.bMem_Latency == {3'b010, 3'b101, 3'b011, 3'b111};    };
       `else `define MICRON_DDR
       constraint cL   { bMem_Mode_Register.bMem_Latency inside {3'b010, 3'b110, 3'b011};            };
       `endif
  `else `define FIXED_CAS_LATENCY
  
       `ifdef SAMSUNG_DDR
       
          `ifdef FIXED_CAS_LATENCY_1_5
              constraint cL   { bMem_Mode_Register.bMem_Latency    == `CAS_LATENCY_1_5_S ;    };
          `else `ifdef FIXED_CAS_LATENCY_2
              constraint cL   { bMem_Mode_Register.bMem_Latency    == `CAS_LATENCY_2_S ;    };
          `else `ifdef FIXED_CAS_LATENCY_2_5
              constraint cL   { bMem_Mode_Register.bMem_Latency    == `CAS_LATENCY_2_5_S ;    };
          `else `define FIXED_CAS_LATENCY_3
              constraint cL   { bMem_Mode_Register.bMem_Latency    == `CAS_LATENCY_3_S ;    };
          `endif `endif `endif
          
          
       `else `define MICRON_DDR
       
         `ifdef FIXED_CAS_LATENCY_2
              constraint cL   { bMem_Mode_Register.bMem_Latency    == `CAS_LATENCY_2_M ;    };
          `else `ifdef FIXED_CAS_LATENCY_2_5
              constraint cL   { bMem_Mode_Register.bMem_Latency    == `CAS_LATENCY_2_5_M ;    };
          `else `define FIXED_CAS_LATENCY_3
              constraint cL   { bMem_Mode_Register.bMem_Latency    == `CAS_LATENCY_3_M ;    };
          `endif `endif 
       
       
       `endif
  
  
       
  `endif
  
  // Constraints for bMem_Data elements
  
  `ifdef DATA_MASK_ON
  //constraint cDM  {foreach(bMem_Addr.bMem_DM[i]) bMem_Addr.bMem_DM[i] dist{1'b0:=9, 1'b1:=1};};
  constraint cDM  {  bMem_Data.bMem_DM dist{{8*DM_BITS{1'b0}}:=5, {8*DM_BITS{1'b1}}:=1};}; 
  `else `define DATA_MASK_OFF
  constraint cDM  { bMem_Data.bMem_DM == {8*DM_BITS{1'b0}};}; 
  `endif
  
  //------------------------------------------ 
  // Packet Functions 

   function void Print;
     
    // Prints bMem_Addr and bMem_Data elements
    $display("%m: [DDR_SDRAM][PACKET][Message] at time %t:  Bank = %0h, Row = %0h, Col = %0h, Data = %0h, Data_Mask = %0h", 
    $time, bMem_Addr.bMem_Bank, bMem_Addr.bMem_Row, bMem_Addr.bMem_Col, bMem_Data.bMem_Data, bMem_Data.bMem_DM);
    
    // Prints bMem_Mode_Register elements
    $display("%m: [DDR_SDRAM][PACKET][Message] at time %t:  RFU = %0h, DDL_Reset = %s, Mode = %s, Latency = %0h, Burst_Type = %s, Burst_Length = %0h",
    $time, bMem_Mode_Register.bMem_RFU, (bMem_Mode_Register.bMem_DLL_Reset ? "DLL Reset" : "NO DLL Reset"), (bMem_Mode_Register.bMem_TM ? "Test Mode" : "Normal Mode"), 
    bMem_Mode_Register.bMem_Latency, ( bMem_Mode_Register.bMem_Burst_Type ? "Interleave" : "Sequential" ), bMem_Mode_Register.bMem_Burst_Length);     
   
   endfunction: Print

   //------------------------------------------ 
   // Constructor 
   function new();
   
    this.srandom(PACKET_SEED);
      
   endfunction
  
endclass: DDR_Packet