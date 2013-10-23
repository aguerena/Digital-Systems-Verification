/****************************************************************************************************/
// Title      : DDR SDRAM Coverage Class
// File       : DDR_Coverage.sv
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 06-Aug-2011
// Notes                 : None 
/****************************************************************************************************/ 

import DDR_EnvPackage::*;

class DDR_Coverage;

   `include "DDR_ParametersPkg.sv"
   
  //------------------------------------------ 
  // Instances References
    DDR_RBFM pRBFM;
    
/***********************************Local Definitions************************************************/ 
  
  //                       {Cs_n, Ras_n, Cas_n, We_n, Ba[1], Ba[0], Addr[10]}
  `define MODE_REG         7'b000000?
  `define EXT_MODE_REG     7'b000001?  
  `define REFRESH          7'b0001???
  `define BURST_TERM       7'b0110???
  `define PRECHARGE        7'b0010???
  `define ACTIVATE         7'b0011???
  `define WRITE            7'b0100???
  `define READ             7'b0101???
  `define NOP              7'b0111???
  `define DESELECT         7'b1??????
  `define READ_PRECHARGE   7'b0101??1
  `define WRITE_PRECHARGE  7'b0100??1
  
/****************************************************************************************************/      
    
  //------------------------------------------ 
  // Covergroups 
  
    // Commands Covergroup 
    covergroup cg_Command; 
      cp_Command: coverpoint pRBFM.rbfm_Command{
          wildcard bins        Write              = {`WRITE};
          wildcard bins        Read               = {`READ};
          wildcard bins        Auto_Refresh       = {`REFRESH};
          wildcard bins        Extended_Mode_Reg  = {`EXT_MODE_REG};
          wildcard bins        Mode_Reg           = {`MODE_REG};
          wildcard bins        Active             = {`ACTIVATE};
          wildcard bins        Burst_terminate    = {`BURST_TERM};
          wildcard bins        Precharge          = {`PRECHARGE};
          wildcard bins        Nop                = {`NOP};
          wildcard bins        Deselect           = {`DESELECT};
          wildcard bins        Read_Precharge     = {`READ_PRECHARGE};
          wildcard bins        Write_Precharge    = {`WRITE_PRECHARGE};
      }
    endgroup: cg_Command
    
    // Power Up Covergroup
    covergroup cg_PowerUp;
      cp_Power_Up: coverpoint pRBFM.rbfm_PowerUp{
          bins        Power_Up = {1};
      }
    endgroup: cg_PowerUp 
    
    // Write Covergroup
    covergroup cg_Write;
      cp_Write : coverpoint pRBFM.rbfm_Write{
          bins        Write = {1};
      }
      cp_Write_Burst_Type: coverpoint pRBFM.rbfm_Write_Burst_Type{
          bins        Sequential  = {0};
          bins        Interleaved = {1};
      }
      cp_Write_Burst_Length: coverpoint pRBFM.rbfm_Write_Burst_Length{
          bins         Burst_Length_2       = {2};
          bins         Burst_Length_4       = {4};
          bins         Burst_Length_8       = {8};
          illegal_bins Burst_Length_Illegal = default;
      }
    endgroup: cg_Write

    // Read Covergroup
    covergroup cg_Read;
      cp_Read: coverpoint pRBFM.rbfm_Read{
          bins        Read = {1};
      }
      cp_Read_Burst_Type: coverpoint pRBFM.rbfm_Read_Burst_Type{
          bins        Sequential  = {0};
          bins        Interleaved = {1};
      }
      cp_Read_Burst_Length: coverpoint pRBFM.rbfm_Read_Burst_Length{
          bins         Burst_Length_2       = {2};
          bins         Burst_Length_4       = {4};
          bins         Burst_Length_8       = {8};
          illegal_bins Burst_Length_Illegal = default;
      }
      cp_Read_CAS_Latency: coverpoint pRBFM.rbfm_Read_CAS_Latency{
          `ifdef SAMSUNG_DDR 
          bins         CAS_Latency_15      = {3};     
          `endif          
          bins         CAS_Latency_2       = {4};
          bins         CAS_Latency_25      = {5};
          bins         CAS_Latency_3       = {6};
          illegal_bins CAS_Latency_Illegal = default;   
      }
    endgroup: cg_Read 
    
    // Active Covergroup
    covergroup cg_Active;
      cp_Active: coverpoint pRBFM.rbfm_Active{
          wildcard bins   Active    = {2'b??};
                   bins   Active_B0 = {2'b00};
                   bins   Active_B1 = {2'b01};
                   bins   Active_B2 = {2'b10};
                   bins   Active_B3 = {2'b11};                 
      }
    endgroup: cg_Active
    
    // Active Row Covergroup
    covergroup cg_Active_Row;
      cp_Active_Row: coverpoint pRBFM.rbfm_Active_Row;                 
    endgroup: cg_Active_Row
    
    // Burst Terminate Covergroup
    covergroup cg_Burst_terminate;
      cp_Burst_terminate: coverpoint pRBFM.rbfm_Burst_terminate{      
          wildcard bins        Burst_terminate = {3'b???};
          `ifdef SAMSUNG_DDR 
          bins         CAS_Latency_15      = {3};     
          `endif          
          bins         CAS_Latency_2       = {4};
          bins         CAS_Latency_25      = {5};
          bins         CAS_Latency_3       = {6};
          illegal_bins CAS_Latency_Illegal = default;  
      }
    endgroup: cg_Burst_terminate
    
    // Precharge Covergroup
    covergroup cg_Precharge;
      cp_Precharge: coverpoint pRBFM.rbfm_Precharge{
          wildcard bins   Precharge     = {3'b???};
          wildcard bins   Precharge_All = {3'b1??};
                   bins   Precharge_B0  = {3'b000};
                   bins   Precharge_B1  = {3'b001};
                   bins   Precharge_B2  = {3'b010};
                   bins   Precharge_B3  = {3'b011}; 
      }
    endgroup: cg_Precharge
    
    

    //------------------------------------------ 
    // Coverage Tasks
    task Sample_Coverage;
    begin
    
      fork
         forever @(pRBFM.e_PowerUp)           cg_PowerUp.sample();
         forever @(pRBFM.e_Write)             cg_Write.sample();
         forever @(pRBFM.e_Read)              cg_Read.sample();
         forever @(pRBFM.e_Active)            cg_Active.sample();
         forever @(pRBFM.e_Active)            cg_Active_Row.sample();
         forever @(pRBFM.e_Precharge)         cg_Precharge.sample();
         forever @(pRBFM.e_Burst_terminate)   cg_Burst_terminate.sample();
         forever @(pRBFM.e_Command)           cg_Command.sample();
      join  
    end  
    endtask
  
  
    task Show_Coverage;
    begin 
      
      `ifdef TEST5
          $set_coverage_db_name("cov_Test5.db");
      `else `ifdef  TEST4
          $set_coverage_db_name("cov_Test4.db");
      `else `ifdef  TEST3
          $set_coverage_db_name("cov_Test3.db");
      `else `ifdef  TEST2  
          $set_coverage_db_name("cov_Test2.db");
      `else `define TEST1
          $set_coverage_db_name("cov_Test1.db");
    `endif `endif `endif `endif 
    //$display( "Coverage=%2.2f%%", cgPowerUp.get_coverage() );  
      
    end
    endtask
    
  //------------------------------------------ 
  // Constructor
     function new();
      cg_Command  = new();
      cg_PowerUp  = new();   
      cg_Write    = new();
      cg_Read     = new();
      cg_Active_Row = new();
      cg_Active = new();
      cg_Precharge = new();
      cg_Burst_terminate = new();
     endfunction 
   
    
   
endclass