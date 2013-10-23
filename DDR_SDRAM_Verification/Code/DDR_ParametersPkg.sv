/****************************************************************************************************/
// Title      : DDR SDRAM Parameters Defintions
// File       : DDR_ParametersPkg.sv
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 06-Aug-2011
// Notes                 : None 
/****************************************************************************************************/ 
  
    //------------------------------------------   
    // Test to Run 
    
    //`define TEST1
    `define TEST2
    //`define TEST3
    //`define TEST4
    //`define TEST5
    
    
    //------------------------------------------   
    // Parameters for Reference Model and Verification Environment
    
    parameter tCK              =     7.5; // tCK    ns    Nominal Clock Cycle Time
    parameter tDQSQ            =     0.5; // tDQSQ  ns    DQS-DQ skew, DQS to last DQ valid, per group, per access
    parameter tMRD             =    15.0; // tMRD   ns    Load Mode Register command cycle time
    parameter tRAP             =    20.0; // tRAP   ns    ACTIVE to READ with Auto precharge command
    parameter tRAS             =    40.0; // tRAS   ns    Active to Precharge command time
    parameter tRC              =    65.0; // tRC    ns    Active to Active/Auto Refresh command time
    parameter tRFC             =    75.0; // tRFC   ns    Refresh to Refresh or Any Command interval time
    parameter tRCD             =    20.0; // tRCD   ns    Active to Read/Write without precharge command time
    parameter tRP              =    20.0; // tRP    ns    Precharge command period
    parameter tRRD             =    15.0; // tRRD   ns    Active bank a to Active bank b command time
    parameter tWR              =    15.0; // tWR    ns    Write recovery time

    parameter ADDR_BITS        =      13; // Set this parameter to control how many Address bits are used
    parameter DQ_BITS          =      16; // Set this parameter to control how many Data bits are used
    parameter DQS_BITS         =       2; // Set this parameter to control how many DQS bits are used
    parameter DM_BITS          =       2; // Set this parameter to control how many DM bits are used
    parameter COL_BITS         =       9; // Set this parameter to control how many Column bits are used

    parameter ERROR_STOP       =       1; // If set to 1, the model won't halt on command sequence/major errors
    parameter DEBUG            =       1; // Turn on DEBUG messages
    parameter DISPLAY_MESSAGES =       1; // Turn on DEBUG messages
    parameter BA_BITS          =       2;                         // Set this parmaeter to control how many Bank Address bits are used
    parameter full_mem_bits    = BA_BITS + ADDR_BITS + COL_BITS; // Set this parameter to control how many unique addresses are used
    parameter part_mem_bits    = 10;                             // Set this parameter to control how many unique addresses are used

    parameter CLK_CYCLES_200US = 26667;      // Number of cycles for Clk stabilization
    parameter WL               = 1;       // Write Latency Cycles
    parameter CLK_200_CYLCES   = 200;     // Number of cycles for DDL stabilization
    parameter MAX_BL           = 8;       // Maximum Burst Length accepted
    
    parameter REPEAT_NUMBER    = 70;      // Repeat number for Test5
    parameter PACKET_SEED      = 3;       // Seed for Packet class 
    //------------------------------------------   
    // Definitios for each Test
    `ifdef TEST5
        parameter TEST_BL = 4;
        //`define DATA_MASK_ON
        `define RANDOM_CAS_LATENCY
        //`define FIXED_CAS_LATENCY_2
        //`define FIXED_CAS_LATENCY_2_5
        //`define FIXED_CAS_LATENCY_3
        
        `define RANDOM_BURST_LENGTH
        //`define FIXED_BURST_LENGTH_2
        //`define FIXED_BURST_LENGTH_4
        //`define FIXED_BURST_LENGTH_8
        
        `define RANDOM_BURST_TYPE
        //`define FIXED_BURST_INTERLEAVE_TYPE
        //`define FIXED_BURST_SEQUENTIAL_TYPE
        
    `else `ifdef TEST4
        parameter TEST_BL = 4;
        //`define DATA_MASK_ON
        //`define RANDOM_CAS_LATENCY
        `define FIXED_CAS_LATENCY_2
        //`define FIXED_CAS_LATENCY_2_5
        //`define FIXED_CAS_LATENCY_3
        
        //`define RANDOM_BURST_LENGTH
        //`define FIXED_BURST_LENGTH_2
        //`define FIXED_BURST_LENGTH_4
        `define FIXED_BURST_LENGTH_8
        
        //`define RANDOM_BURST_TYPE
        `define FIXED_BURST_INTERLEAVE_TYPE
        //`define FIXED_BURST_SEQUENTIAL_TYPE
        
    `else `ifdef TEST3
        parameter TEST_BL = 4;
        `define DATA_MASK_ON
        //`define RANDOM_CAS_LATENCY
        //`define FIXED_CAS_LATENCY_2
        //`define FIXED_CAS_LATENCY_2_5
        `define FIXED_CAS_LATENCY_3
        
       // `define RANDOM_BURST_LENGTH
        //`define FIXED_BURST_LENGTH_2
        `define FIXED_BURST_LENGTH_4
        //`define FIXED_BURST_LENGTH_8
        
        //`define RANDOM_BURST_TYPE
        //`define FIXED_BURST_INTERLEAVE_TYPE
        `define FIXED_BURST_SEQUENTIAL_TYPE
        
    `else `ifdef TEST2
        parameter TEST_BL = 8;
    `else  `define TEST1
        parameter TEST_BL = 4;
    `endif `endif `endif `endif
    