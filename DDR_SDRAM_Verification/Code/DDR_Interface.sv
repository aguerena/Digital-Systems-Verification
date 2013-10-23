/****************************************************************************************************/
// Title      : DDR SDRAM Interface
// File       : DDR_Interface.sv
// Description: Interface and Modports
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 07-Aug-2011
// Notes                 : None 
/****************************************************************************************************/  
`timescale 1ns/1ps

interface DDR_Interface(input Clk, Clk_n);

    `include "DDR_ParametersPkg.sv"
    
    // Signals
    logic                         Cke;
    logic                         Cs_n;
    logic                         Ras_n;
    logic                         Cas_n;
    logic                         We_n;
    logic       [BA_BITS -1 : 0]  Ba;
    logic    [ADDR_BITS - 1 : 0]  Addr;
    logic      [DM_BITS - 1 : 0]  Dm;
    logic      [DQ_BITS - 1 : 0]  Dq;
    logic     [DQS_BITS - 1 : 0]  Dqs;


     // DUV ModPort
  /*  modport DUV(
    input Clk,
          Clk_n, 
          Cke,
          Cs_n,
          Ras_n,
          Cas_n,
          We_n,
          Ba,
          Addr,
          Dm, 
    inout Dq,
          Dqs);*/
  
    // Reference Model ModPort
    modport RM(
    input Clk,
          Clk_n,
          Cke,
          Cs_n,
          Ras_n,
          Cas_n,
          We_n,
          Ba,
          Addr,
          Dm, 
          Dq,
          Dqs);
          
    // Tx  ModPort            
    modport TX(
    input  Clk,
           Clk_n,
    output Cke,
           Cs_n,
           Ras_n,
           Cas_n,
           We_n,
           Ba,
           Addr,
           Dm, 
           Dq,
           Dqs);       
    
    // Monitor  ModPort      
    modport MONITOR(
    input Clk,
          Clk_n,
          Cke,
          Cs_n,
          Ras_n,
          Cas_n,
          We_n,
          Ba,
          Addr,
          Dm, 
  output  Dq,
          Dqs);      
          
endinterface: DDR_Interface


interface DDR_InterfaceInt(); 
    
    `include "DDR_ParametersPkg.sv"
    
     // Signals
    bit power_up_done;
    bit Data_out_enable;
    logic [DQ_BITS -  1 : 0] Dq_out; 
    logic [DQS_BITS - 1 : 0] Dqs_out;
    logic burst_type;
    logic Read_enable;
    logic Write_enable;
    logic Auto_refresh_enable;
    logic Extended_mode_enable;
    logic Mode_reg_enable;
    logic Active_enable;
    logic Precharge_enable;
    logic Burst_terminate_enable;
    logic [2:0] cas_latency_x2;
    logic [3:0] burst_length;
    
    modport MONITOR(
    input power_up_done,
          Data_out_enable,
          Dq_out,
          Dqs_out,
          burst_type, 
          Read_enable,
          Write_enable,
          Auto_refresh_enable,
          Extended_mode_enable,
          Mode_reg_enable,
          Active_enable,
          Precharge_enable,
          Burst_terminate_enable,
          cas_latency_x2,
          burst_length);  
    


endinterface: DDR_InterfaceInt 




module DDR_RM_MODULE (DDR_Interface.RM DDR_If, DDR_InterfaceInt.MONITOR DDR_IntIf);
  
  DDR_RM DDR_RM_inst1( 
                      .Clk  (DDR_If.Clk),
                      .Clk_n(DDR_If.Clk_n),
                      .Cke  (DDR_If.Cke),
                      .Cs_n (DDR_If.Cs_n),
                      .Ras_n(DDR_If.Ras_n),
                      .Cas_n(DDR_If.Cas_n),
                      .We_n (DDR_If.We_n),
                      .Ba   (DDR_If.Ba),
                      .Addr (DDR_If.Addr),
                      .Dm   (DDR_If.Dm),
                      .Dq   (DDR_If.Dq),
                      .Dqs  (DDR_If.Dqs)); 
                      
  assign DDR_IntIf.power_up_done            = DDR_RM_inst1.power_up_done; 
  assign DDR_IntIf.Data_out_enable          = DDR_RM_inst1.Data_out_enable;
  assign DDR_IntIf.Dq_out                   = DDR_RM_inst1.Dq_out;
  assign DDR_IntIf.Dqs_out                  = DDR_RM_inst1.Dqs_out;
  assign DDR_IntIf.burst_type               = DDR_RM_inst1.burst_type;
  assign DDR_IntIf.cas_latency_x2           = DDR_RM_inst1.cas_latency_x2;
  assign DDR_IntIf.burst_length             = DDR_RM_inst1.burst_length;
  
  assign DDR_IntIf.Read_enable              = DDR_RM_inst1.Read_enable;
  assign DDR_IntIf.Write_enable             = DDR_RM_inst1.Write_enable;
  assign DDR_IntIf.Auto_refresh_enable      = DDR_RM_inst1.Auto_refresh_enable;
  assign DDR_IntIf.Extended_mode_enable     = DDR_RM_inst1.Extended_mode_enable;
  assign DDR_IntIf.Mode_reg_enable          = DDR_RM_inst1.Mode_reg_enable;
  assign DDR_IntIf.Active_enable            = DDR_RM_inst1.Active_enable;
  assign DDR_IntIf.Precharge_enable         = DDR_RM_inst1.Precharge_enable;
  assign DDR_IntIf.Burst_terminate_enable   = DDR_RM_inst1.Burst_terminate_enable;
  
     
endmodule



