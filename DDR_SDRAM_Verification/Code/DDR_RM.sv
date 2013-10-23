
/****************************************************************************************************/
// Title      : DDR SDRAM Reference Model
// File       : DDR_RM.sv
/****************************************************************************************************/ 
// Author                : MICRON TECHNOLOGY, INC.
// Modified by           : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 07-25-2011
// Notes                 : Modified for Especialidad en Diseno de CI DDR SDRAM Project 
/****************************************************************************************************/  

`timescale 1ns/1ps

module DDR_RM (Clk, Clk_n, Cke, Cs_n, Ras_n, Cas_n, We_n, Ba , Addr, Dm, Dq, Dqs);
  
     `include "DDR_ParametersPkg.sv" 
    
    // Port Declarations
    input                         Clk;
    input                         Clk_n;
    input                         Cke;
    input                         Cs_n;
    input                         Ras_n;
    input                         Cas_n;
    input                         We_n;
    input        [BA_BITS -1 : 0] Ba;
    input     [ADDR_BITS - 1 : 0] Addr;
    input       [DM_BITS - 1 : 0] Dm;
    ref       [DQ_BITS - 1 : 0] Dq;
    ref      [DQS_BITS - 1 : 0] Dqs;
    
    
    // Commands Decode
    wire      Auto_refresh_enable     = ~Cs_n & ~Ras_n & ~Cas_n &  We_n;
    wire      Extended_mode_enable    = ~Cs_n & ~Ras_n & ~Cas_n & ~We_n &  Ba[0] & ~Ba[1];
    wire      Mode_reg_enable         = ~Cs_n & ~Ras_n & ~Cas_n & ~We_n & ~Ba[0] & ~Ba[1];
    wire      Active_enable           = ~Cs_n & ~Ras_n &  Cas_n &  We_n;
    wire      Precharge_enable        = ~Cs_n & ~Ras_n &  Cas_n & ~We_n;
    wire      Burst_terminate_enable  = ~Cs_n &  Ras_n &  Cas_n & ~We_n;
    wire      Read_enable             = ~Cs_n &  Ras_n & ~Cas_n &  We_n;
    wire      Write_enable            = ~Cs_n &  Ras_n & ~Cas_n & ~We_n;
     
    // Internal Wires (fixed width)
    wire                 [31 : 0] Dq_in;
    wire                  [3 : 0] Dqs_in;
    wire                  [3 : 0] Dm_in;
    
    assign Dq_in   [DQ_BITS - 1 : 0] = Dq;
    assign Dqs_in [DQS_BITS - 1 : 0] = Dqs;
    assign Dm_in   [DM_BITS - 1 : 0] = Dm;
    
    // Data pair 
    logic                  [31 : 0] dq_rise;
    logic                   [3 : 0] dm_rise;
    logic                  [31 : 0] dq_fall;
    logic                   [3 : 0] dm_fall;
    logic                   [7 : 0] dm_pair;
    logic                  [31 : 0] Dq_buf;
    
    
      // Internal System Clock
    reg                             Cke_reg;
    logic                           Sys_clk;
    
    
    
       // Data IO variables
    logic                           Data_in_enable;
    logic                           Data_out_enable;
    
  
    
      // Burst counter
    logic        [COL_BITS - 1 : 0] Burst_counter;
    
     // Burst Length Decode
    bit    [3 : 0] burst_length;
    bit    [3 : 0] read_precharge_truncation;
    
        // Internal address mux variables
    logic                   [1 : 0] Prev_bank;
    logic                   [1 : 0] Bank_addr;
    logic        [COL_BITS - 1 : 0] Cols_addr;
    logic        [COL_BITS - 1 : 0] Cols_brst;
    logic        [COL_BITS - 1 : 0] Cols_temp;
    logic       [ADDR_BITS - 1 : 0] Rows_addr;
    logic       [ADDR_BITS - 1 : 0] B0_row_addr;
    logic       [ADDR_BITS - 1 : 0] B1_row_addr;
    logic       [ADDR_BITS - 1 : 0] B2_row_addr;
    logic       [ADDR_BITS - 1 : 0] B3_row_addr;
    
        
    // CAS Latency Decode
    bit [2 : 0] cas_latency_x2 ;//= (Mode_reg[6:4] === 3'o6) ? 5 : 2*Mode_reg[6:4];
    
    // Burst Type Decode
    bit burst_type; 
    
    // Internal Dqs initialize
    logic                           Dqs_int;

    // Dqs buffer
    logic        [DQS_BITS - 1 : 0] Dqs_out;

    // Dq buffer
    logic         [DQ_BITS - 1 : 0] Dq_out;
     
    // Burst terminate variables
    logic                           Cmnd_bst [0:6];
    
 
    
     // Auto precharge variables
    logic                           Read_precharge  [0:3];
    logic                           Write_precharge [0:3];
    integer                         Count_precharge [0:3];

    // Manual precharge variables
    logic                           A10_precharge  [0:6];
    logic                  [1 : 0]  Bank_precharge [0:6];
    logic                           Cmnd_precharge [0:6];
      
    // Read pipeline variables
    
    logic                           Read_cmnd [0:6];
    logic                   [1 : 0] Read_bank [0:6];
    logic        [COL_BITS - 1 : 0] Read_cols [0:6];
    
      // Write pipeline variables
    
    logic                           Write_cmnd [0:3];
    logic                   [1 : 0] Write_bank [0:3];
    logic        [COL_BITS - 1 : 0] Write_cols [0:3];
   
    // Memory Banks
    reg         [DQ_BITS - 1 : 0] mem_array  [0:(1<<full_mem_bits)-1];
    
    // Dqs edge checking
    integer i;
    logic  [3 : 0] expect_pos_dqs;
    logic  [3 : 0] expect_neg_dqs;
    
    // Precharge variables
    reg                           Pc_b0, Pc_b1, Pc_b2, Pc_b3;

    // Activate variables
    reg                           Act_b0, Act_b1, Act_b2, Act_b3;
 
     // Power Up and DLL Reset variables
    bit                           DLL_enable;
    bit                           DLL_reset;
    bit                           DLL_done;
    integer                       DLL_count;
    integer                       aref_count;
    bit                   [1 : 0] Prech_count;
    bit                           power_up_done;
    bit                           init_device_operation;

    //Write DQS for tDSS, tDSH, tDQSH, tDQSL checks
    wire wdqs_valid = Write_cmnd[2] || Write_cmnd[1] || Data_in_enable;
    
    //DQS, DQ Buffer
    assign Dqs = Dqs_out;
    assign Dq  = Dq_out;
   
 
     // Timing Check
    time      MRD_chk;                                //Load Mode Register command cycle time check flag
    time      RFC_chk;                                //Refresh to Refresh Command interval time check flag
    time      RRD_chk;                                //Active bank a to Active bank b command time check flag
    time      RAS_chk0, RAS_chk1, RAS_chk2, RAS_chk3; //Active to Precharge command time check flag for Bank 0, 1, 2 and 3
    time      RAP_chk0, RAP_chk1, RAP_chk2, RAP_chk3; //ACTIVE to READ with Auto precharge command time check flag for Bank 0, 1, 2 and 3
    time      RC_chk0,  RC_chk1,  RC_chk2,  RC_chk3;  //Active to Active/Auto Refresh command time check flag for Bank 0, 1, 2 and 3
    time      RCD_chk0, RCD_chk1, RCD_chk2, RCD_chk3; //Active to Read/Write command time check flag for Bank 0, 1, 2 and 3
    time      RP_chk0,  RP_chk1,  RP_chk2,  RP_chk3;  //Precharge command period time check flag for Bank 0, 1, 2 and 3
    time      WR_chk0,  WR_chk1,  WR_chk2,  WR_chk3;  //Write recovery time  check flag for Bank 0, 1, 2 and 3
/****************************************************************************************************/ 
/***********************************Local Definitions************************************************/ 
/****************************************************************************************************/ 
/****************************************************************************************************/  
 
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
*/
 
 //`define err_stop 
 `define NOP_Command       (~Cs_n &  Ras_n & Cas_n &  We_n)
 `define DESELECT          (Cs_n)
 
 `define PRE_to_AREF_TimeChk         ( ($time - RP_chk0 < tRP) || ($time - RP_chk1 < tRP) || ($time - RP_chk2 < tRP) || ($time - RP_chk3 < tRP) )  
 `define MR_EMR_to_AREF_TimeChk      ($time - MRD_chk < tMRD)
 `define AREF_to_AREF_TimeChk        ($time - RFC_chk < tRFC)
 
 `define PRE_to_MR_EMR_TimeChk       ( ($time - RP_chk0 < tRP) || ($time - RP_chk1 < tRP) || ($time - RP_chk2 < tRP) || ($time - RP_chk3 < tRP) )       
 `define MR_EMR_to_MR_EMR_TimeChk    ($time - MRD_chk < tMRD)
 `define AREF_to_MR_EMR_TimeChk      ($time - RFC_chk < tRFC) 
 
 `define MR_EMR_to_ACT_TimeChk       ($time - MRD_chk < tMRD)
 `define AREF_to_ACT_TimeChk         ($time - RFC_chk < tRFC)
 `define ACTa_to_ACTb_TimeChk        ($time - RRD_chk < tRRD)
 `define ACT0_to_ACT0_TimeChk        ($time - RC_chk0 < tRC)
 `define ACT1_to_ACT1_TimeChk        ($time - RC_chk1 < tRC)
 `define ACT2_to_ACT2_TimeChk        ($time - RC_chk2 < tRC)
 `define ACT3_to_ACT3_TimeChk        ($time - RC_chk3 < tRC)
 `define PRE0_to_ACT0_TimeChk        ($time - RP_chk0 < tRP)
 `define PRE1_to_ACT1_TimeChk        ($time - RP_chk1 < tRP)
 `define PRE2_to_ACT2_TimeChk        ($time - RP_chk2 < tRP)
 `define PRE3_to_ACT3_TimeChk        ($time - RP_chk3 < tRP)
 
 
 `define MR_EMR_to_PRE_TimeChk       ($time - MRD_chk < tMRD)
 `define AREF_to_PRE_TimeChk         ($time - RFC_chk < tRFC)
 `define ACT0_to_PRE0_TimeChk        ($time - RAS_chk0 < tRAS)
 `define ACT1_to_PRE1_TimeChk        ($time - RAS_chk1 < tRAS)
 `define ACT2_to_PRE2_TimeChk        ($time - RAS_chk2 < tRAS)
 `define ACT3_to_PRE3_TimeChk        ($time - RAS_chk3 < tRAS)
 `define WRITE_to_PRE0_TimeChk       ($time - WR_chk0 < tWR)
 `define WRITE_to_PRE1_TimeChk       ($time - WR_chk1 < tWR)
 `define WRITE_to_PRE2_TimeChk       ($time - WR_chk2 < tWR)
 `define WRITE_to_PRE3_TimeChk       ($time - WR_chk3 < tWR)
 
 `define ACT0_to_READ_TimeChk        ($time - RCD_chk0 < tRCD)
 `define ACT1_to_READ_TimeChk        ($time - RCD_chk1 < tRCD) 
 `define ACT2_to_READ_TimeChk        ($time - RCD_chk2 < tRCD)
 `define ACT3_to_READ_TimeChk        ($time - RCD_chk3 < tRCD)
 `define ACT0_to_READA_TimeChk       ($time - RAP_chk0 < tRAP)
 `define ACT1_to_READA_TimeChk       ($time - RAP_chk1 < tRAP)
 `define ACT2_to_READA_TimeChk       ($time - RAP_chk2 < tRAP)
 `define ACT3_to_READA_TimeChk       ($time - RAP_chk3 < tRAP)
 
 `define ACT0_to_WRITE_TimeChk       ($time - RCD_chk0 < tRCD) 
 `define ACT1_to_WRITE_TimeChk       ($time - RCD_chk1 < tRCD)
 `define ACT2_to_WRITE_TimeChk       ($time - RCD_chk2 < tRCD)
 `define ACT3_to_WRITE_TimeChk       ($time - RCD_chk3 < tRCD)
 
 
/****************************************************************************************************/ 
/****************************************************************************************************/ 
/****************************************************************************************************/ 
/****************************************************************************************************/  
    initial begin
    
        Cke_reg = 1'b0;
        Sys_clk = 1'b0;
        {Pc_b0, Pc_b1, Pc_b2, Pc_b3} = 4'b0000;
        {Act_b0, Act_b1, Act_b2, Act_b3} = 4'b1111;
        Dqs_int = 1'b0;
        Dqs_out = {DQS_BITS{1'bz}};
        Dq_out = {DQ_BITS{1'bz}};
        Data_in_enable = 1'b0;
        Data_out_enable = 1'b0;
        DLL_enable = 1'b0;
        DLL_reset = 1'b0;
        DLL_done = 1'b0;
        DLL_count = 0;
        aref_count = 0;
        Prech_count = 0;
        power_up_done = 0;
        init_device_operation = 0;
        MRD_chk = 0;
        RFC_chk = 0;
        RRD_chk = 0;
        {RAS_chk0, RAS_chk1, RAS_chk2, RAS_chk3} = 0;
        {RAP_chk0, RAP_chk1, RAP_chk2, RAP_chk3} = 0;
        {RC_chk0, RC_chk1, RC_chk2, RC_chk3} = 0;
        {RCD_chk0, RCD_chk1, RCD_chk2, RCD_chk3} = 0;
        {RP_chk0, RP_chk1, RP_chk2, RP_chk3} = 0;
        {WR_chk0, WR_chk1, WR_chk2, WR_chk3} = 0;
        $timeformat (-9, 3, " ns", 12);
        
    end
    
    
    // System Clock in DDR SDRAM      
    always @(posedge Clk) begin
       Sys_clk    <= Cke_reg;
       Cke_reg    <= Cke; 
    end
    
    always @(negedge Clk) begin
        Sys_clk <= 1'b0;
    end
    
    
    // When CKE is brought high Check you must have a Deselect or NOP command on the bus
    always @(Cke) begin
        if (Cke == 1'b1) begin   
            if( (!(`DESELECT)) && (!(`NOP_Command)) ) begin
                $display ("%m: [DDR_SDRAM][RM][Error] at time %0t ps MEMORY ERROR: Deselect or NOP command is not applied when the Clock Enable (Cke) is brought High.", $time);
            end 
        end
    end
    
    // Initialization Sequence
    initial begin  
       @(posedge Clk) begin
          $display("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY POWER UP INIT:  Start Clock", $time);    
          repeat(CLK_CYCLES_200US) @(negedge Clk); 
          $display("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY POWER UP INIT:  Clock Stable Condition Accomplished", $time);          
          @(posedge Cke && `NOP_Command ) begin
             $display("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY POWER UP INIT:  NOP applied and CKE taken high", $time);              
             @(posedge DLL_enable) begin
                $display("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY POWER UP INIT:  DLL Enabled", $time);
                aref_count = 0;
                @(posedge DLL_reset) begin
                   $display("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY POWER UP INIT:  DLL Reset", $time);
                   @(Prech_count >=2) begin
                      $display("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY POWER UP INIT:  All banks Precharged issued 2 or more times", $time);
                      if (aref_count >= 2) begin
                         $display("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY POWER UP INIT:  Auto Refresh issued 2 or more times", $time);
                         @(init_device_operation);
                         $display("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY POWER UP INIT:  Mode Register Set issued with A8 taken low", $time);
                         if (DISPLAY_MESSAGES) $display ("%4m: [DDR_SDRAM][RM][Message] at time %t MEMORY POWER UP INIT:  Power Up and Initialization Sequence is complete", $time);
                            power_up_done = 'b1;
                      end     
                      else begin
                        
                         aref_count = 0;
                         @(aref_count >= 2) begin
                            $display("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY POWER UP INIT:  Auto Refresh issued 2 or more times", $time);
                            @(init_device_operation);
                             $display("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY POWER UP INIT:  Mode Register Set issued with A8 taken low", $time);
                            if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY:  Power Up and Initialization Sequence is complete", $time);
                            power_up_done = 'b1;  
                               
                         end //@(aref_count >= 2)
                      end
                   end  //@(Prech_count)
                end  //@(posedge DLL_reset)
             end  //@posedge DLL_enable
          end  //@(posedge Cke && `NOP_Command)  
       end //@(posedge Clk)    
    end
    
    
    //DLL Counter
    task DLL_Counter;
    begin
    
      if(DLL_reset == 1'b1 && DLL_done == 1'b0) begin
        
        DLL_count++;
        if(DLL_count >= 200) DLL_done = 1'b1;
          
      end    

    end
    endtask: DLL_Counter  
      
      
    // Read Memory
    task read_mem(
       input [full_mem_bits - 1:0] addr, 
       output [DQ_BITS - 1:0] data);
           
       begin  
          data = mem_array[addr];
       end
       
    endtask: read_mem

    // Write Memory
    task write_mem(
        input [full_mem_bits - 1 : 0] addr,
        input       [DQ_BITS - 1 : 0] data);
    
        begin
          
            mem_array[addr] = data; 
        end
    
    endtask: write_mem
    
    
      // Burst Decode
    task Burst_Decode;
      
    begin

        // Advance Burst Counter
        if (Burst_counter < burst_length) begin
            Burst_counter++;
        end
       

        // Burst Type
        
          // Sequential Burst
        if (burst_type == 1'b0) begin                         
            Cols_temp = Cols_addr + 1;
            
        end  
          // Interleaved Burst
        else begin       
            Cols_temp [2 : 0] = (Burst_counter[2 : 0] ^ Cols_brst[2 : 0]);
                    
        end

        // Burst Length
        case(burst_length)
          
          'b10   : Cols_addr [0]     = Cols_temp [0];
          'b100  : Cols_addr [1 : 0] = Cols_temp [1 : 0];
          'b1000 : Cols_addr [2 : 0] = Cols_temp [2 : 0];
          default: Cols_addr         = Cols_temp;
          
        endcase
        
         //Data counter
        if (Burst_counter >= burst_length) begin
            Data_in_enable = 'b0;
            Data_out_enable = 'b0;
            read_precharge_truncation = 'h0;
            
        end  
   
    end
    
    endtask: Burst_Decode
    
    
      // Manual Precharge
    task Manual_Precharge;
    begin
       // A10 Precharge Pipeline
        A10_precharge[0] = A10_precharge[1];
        A10_precharge[1] = A10_precharge[2];
        A10_precharge[2] = A10_precharge[3];
        A10_precharge[3] = A10_precharge[4];
        A10_precharge[4] = A10_precharge[5];
        A10_precharge[5] = A10_precharge[6];
        A10_precharge[6] = 'b0;

        // Bank Precharge Pipeline
        Bank_precharge[0] = Bank_precharge[1];
        Bank_precharge[1] = Bank_precharge[2];
        Bank_precharge[2] = Bank_precharge[3];
        Bank_precharge[3] = Bank_precharge[4];
        Bank_precharge[4] = Bank_precharge[5];
        Bank_precharge[5] = Bank_precharge[6];
        Bank_precharge[6] = 'b00;

        // Command Precharge Pipeline
        Cmnd_precharge[0] = Cmnd_precharge[1];
        Cmnd_precharge[1] = Cmnd_precharge[2];
        Cmnd_precharge[2] = Cmnd_precharge[3];
        Cmnd_precharge[3] = Cmnd_precharge[4];
        Cmnd_precharge[4] = Cmnd_precharge[5];
        Cmnd_precharge[5] = Cmnd_precharge[6];
        Cmnd_precharge[6] = 'b0;

        // Terminate a Read if same bank or all banks
        if ( (Cmnd_precharge[0]) && (Bank_precharge[0] == Bank_addr || A10_precharge[0] == 'b1)  &&  (Data_out_enable) ) begin
                Data_out_enable = 'b0;
                read_precharge_truncation = 4'hF;  
        end
       
    end
    endtask: Manual_Precharge
     
    
      // Burst Terminate Pipeline
    task Burst_Terminate;
    begin
      
         // Command Precharge Pipeline
        Cmnd_bst[0] = Cmnd_bst[1];
        Cmnd_bst[1] = Cmnd_bst[2];
        Cmnd_bst[2] = Cmnd_bst[3];
        Cmnd_bst[3] = Cmnd_bst[4];
        Cmnd_bst[4] = Cmnd_bst[5];
        Cmnd_bst[5] = Cmnd_bst[6];
        Cmnd_bst[6] = 'b0;


        // Terminate a Read regardless of banks
        if ( (Cmnd_bst[0]) && (Data_out_enable) ) begin
            Data_out_enable = 'b0;
        end
        
    end
    endtask: Burst_Terminate
    
      // Dq and Dqs Drivers
    task Dq_Dqs_Drivers;
    begin
        // read command pipeline
        Read_cmnd [0] = Read_cmnd [1];
        Read_cmnd [1] = Read_cmnd [2];
        Read_cmnd [2] = Read_cmnd [3];
        Read_cmnd [3] = Read_cmnd [4];
        Read_cmnd [4] = Read_cmnd [5];
        Read_cmnd [5] = Read_cmnd [6];
        Read_cmnd [6] = 'b0;

        // read bank pipeline
        Read_bank [0] = Read_bank [1];
        Read_bank [1] = Read_bank [2];
        Read_bank [2] = Read_bank [3];
        Read_bank [3] = Read_bank [4];
        Read_bank [4] = Read_bank [5];
        Read_bank [5] = Read_bank [6];
        Read_bank [6] = 'b00;

        // read column pipeline
        Read_cols [0] = Read_cols [1];
        Read_cols [1] = Read_cols [2];
        Read_cols [2] = Read_cols [3];
        Read_cols [3] = Read_cols [4];
        Read_cols [4] = Read_cols [5];
        Read_cols [5] = Read_cols [6];
        Read_cols [6] = 'b0;

        // Initialize Read command
        if (Read_cmnd [0] == 'b1) begin
            Data_out_enable = 'b1;
            Bank_addr = Read_bank [0];
            Cols_addr = Read_cols [0];
            Cols_brst = Cols_addr [2 : 0];
            Burst_counter = 0;

            // Row Address Mux
            case (Bank_addr)
                2'd0    : Rows_addr = B0_row_addr;
                2'd1    : Rows_addr = B1_row_addr;
                2'd2    : Rows_addr = B2_row_addr;
                2'd3    : Rows_addr = B3_row_addr;
                default : $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Invalid Bank Address", $time);
            endcase
        end

        // Toggle Dqs during Read command
        if (Data_out_enable == 'b1) begin
            Dqs_int = 'b0;
            if (Dqs_out == 'd0) begin
                Dqs_out = {DQS_BITS{1'b1}};
            end else if (Dqs_out == {DQS_BITS{1'b1}}) begin
                Dqs_out = 'd0;
            end else begin
                Dqs_out = 'd0;
            end
        end else if (Data_out_enable == 1'b0 && Dqs_int == 1'b0) begin
            Dqs_out = {DQS_BITS{1'bz}};
        end

        // Initialize dqs for Read command
        if (Read_cmnd [2] == 'b1) begin
            if (Data_out_enable == 'b0) begin
                Dqs_int = 'b1;
                Dqs_out = 'd0;
            end
        end

        // Read latch
        if (Data_out_enable == 'b1) begin
            // output data
            read_mem({Bank_addr, Rows_addr, Cols_addr}, Dq_out);
            if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY READ : Bank = %h, Row = %h, Col = %h, Data = %h", $time, Bank_addr, Rows_addr, Cols_addr, Dq_out);
                
            
        end else begin
            Dq_out = {DQ_BITS{1'bz}};
        end
    end
    endtask: Dq_Dqs_Drivers


// Write FIFO and DM Mask Logic
    task Write_FIFO_DM_Mask_Logic;
    begin
        // Write command pipeline
        Write_cmnd [0] = Write_cmnd [1];
        Write_cmnd [1] = Write_cmnd [2];
        Write_cmnd [2] = Write_cmnd [3];
        Write_cmnd [3] = 'b0;

        // Write command pipeline
        Write_bank [0] = Write_bank [1];
        Write_bank [1] = Write_bank [2];
        Write_bank [2] = Write_bank [3];
        Write_bank [3] = 'b00;

        // Write column pipeline
        Write_cols [0] = Write_cols [1];
        Write_cols [1] = Write_cols [2];
        Write_cols [2] = Write_cols [3];
        Write_cols [3] = {COL_BITS{1'b0}};

        // Initialize Write command
        if (Write_cmnd [0] == 'b1) begin
            Data_in_enable = 'b1;
            Bank_addr = Write_bank [0];
            Cols_addr = Write_cols [0];
            Cols_brst = Cols_addr [2 : 0];
            Burst_counter = 0;
            
            // Row address mux
            case (Bank_addr)
                2'd0    : Rows_addr = B0_row_addr;
                2'd1    : Rows_addr = B1_row_addr;
                2'd2    : Rows_addr = B2_row_addr;
                2'd3    : Rows_addr = B3_row_addr;
                default : $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Invalid Row Address", $time);
            endcase
        end

        // Write data
        if (Data_in_enable == 'b1) begin
            
            // Data Buffer
            read_mem({Bank_addr, Rows_addr, Cols_addr}, Dq_buf);

            // write negedge Dqs on posedge Sys_clk
            if (Sys_clk) begin
                if (!dm_fall[0]) begin
                    Dq_buf [ 7 : 0] = dq_fall [ 7 : 0];
                end
                if (!dm_fall[1]) begin
                    Dq_buf [15 : 8] = dq_fall [15 : 8];
                end
                if (!dm_fall[2]) begin
                    Dq_buf [23 : 16] = dq_fall [23 : 16];
                end
                if (!dm_fall[3]) begin
                    Dq_buf [31 : 24] = dq_fall [31 : 24];
                end
                if (~&dm_fall) begin
                   // if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY WRITE Fall: Bank = %h, Row = %h, Col = %h, Data = %h", $time, Bank_addr, Rows_addr, Cols_addr, Dq_buf[DQ_BITS-1:0]);                           
                end
            // write posedge Dqs on negedge Sys_clk
            end else begin
                if (!dm_rise[0]) begin
                    Dq_buf [7 : 0] = dq_rise [7 : 0];
                end
                if (!dm_rise[1]) begin
                    Dq_buf [15 : 8] = dq_rise [15 : 8];
                end
                if (!dm_rise[2]) begin
                    Dq_buf [23 : 16] = dq_rise [23 : 16];
                end
                if (!dm_rise[3]) begin
                    Dq_buf [31 : 24] = dq_rise [31 : 24];
                end
                if (~&dm_rise) begin
                    //if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY WRITE Rise: Bank = %h, Row = %h, Col = %h, Data = %h", $time, Bank_addr, Rows_addr, Cols_addr, Dq_buf[DQ_BITS-1:0]);                    
                end
            end

            // Write Data
            $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY WRITE: Bank = %h, Row = %h, Col = %h, Data = %h", $time, Bank_addr, Rows_addr, Cols_addr, Dq_buf[DQ_BITS-1:0]);
            write_mem({Bank_addr, Rows_addr, Cols_addr}, Dq_buf);

            // tWR start and tWTR check
            if (Sys_clk && &dm_pair == 1'b0)  begin   
                case (Bank_addr)
                    'd0    : WR_chk0 = $time;
                    'd1    : WR_chk1 = $time;
                    'd2    : WR_chk2 = $time;
                    'd3    : WR_chk3 = $time;
                    default : $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Invalid Bank Address (tWR)", $time);
                endcase

                // tWTR check
                if (Read_enable == 1'b1) begin
                    $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tWTR violation during Read", $time);
                end
            end
        end
    end
    endtask

    // Auto Precharge Calculation
    task Auto_Precharge_Calculation;
    begin
        // Precharge counter
        if (Read_precharge [0] == 'b1 || Write_precharge [0] == 'b1) begin
            Count_precharge [0]++;
        end
        if (Read_precharge [1] == 'b1 || Write_precharge [1] == 'b1) begin
            Count_precharge [1]++;
        end
        if (Read_precharge [2] == 'b1 || Write_precharge [2] == 'b1) begin
            Count_precharge [2]++;
        end
        if (Read_precharge [3] == 'b1 || Write_precharge [3] == 'b1) begin
            Count_precharge [3]++;
        end

        // Read with AutoPrecharge Calculation
        //      The device start internal precharge when:
        //          1.  Meet tRAS requirement
        //          2.  BL/2 cycles after command
        if ((Read_precharge[0] == 'b1) && ($time - RAS_chk0 >= tRAS)) begin
            if (Count_precharge[0] >= burst_length/2) begin
                {Pc_b0, Act_b0, RP_chk0, Read_precharge[0]} = {1'b1 , 1'b0 , $time, 1'b0};
             /*   Pc_b0 = 'b1;
                Act_b0 = 'b0;
                RP_chk0 = $time;  
                Read_precharge[0] = 'b0;*/
            end
        end
        if ((Read_precharge[1] == 'b1) && ($time - RAS_chk1 >= tRAS)) begin
            if (Count_precharge[1] >= burst_length/2) begin
                Pc_b1 = 'b1;
                Act_b1 = 'b0;
                RP_chk1 = $time;
                Read_precharge[1] = 'b0;
            end
        end
        if ((Read_precharge[2] == 'b1) && ($time - RAS_chk2 >= tRAS)) begin
            if (Count_precharge[2] >= burst_length/2) begin
                Pc_b2 = 'b1;
                Act_b2 = 'b0;
                RP_chk2 = $time;
                Read_precharge[2] = 'b0;
            end
        end
        if ((Read_precharge[3] == 'b1) && ($time - RAS_chk3 >= tRAS)) begin
            if (Count_precharge[3] >= burst_length/2) begin
                Pc_b3 = 'b1;
                Act_b3 = 'b0;
                RP_chk3 = $time;
                Read_precharge[3] = 'b0;
            end
        end

        // Write with AutoPrecharge Calculation
        //      The device start internal precharge when:
        //          1.  Meet tRAS requirement
        //          2.  Write Latency PLUS BL/2 cycles PLUS tWR after Write command

        if ((Write_precharge[0] == 'b1) && ($time - RAS_chk0 >= tRAS)) begin 
            if ((Count_precharge[0] >= burst_length/2+1) && ($time - WR_chk0 >= tWR)) begin
                Pc_b0 = 'b1;
                Act_b0 = 'b0;
                RP_chk0 = $time;
                Write_precharge[0] = 'b0;
            end
        end
        if ((Write_precharge[1] == 'b1) && ($time - RAS_chk1 >= tRAS)) begin 
            if ((Count_precharge[1] >= burst_length/2+1) && ($time - WR_chk1 >= tWR)) begin
                Pc_b1 = 'b1;
                Act_b1 = 'b0;
                RP_chk1 = $time;
                Write_precharge[1] = 'b0;
            end
        end
        if ((Write_precharge[2] == 'b1) && ($time - RAS_chk2 >= tRAS)) begin 
            if ((Count_precharge[2] >= burst_length/2+1) && ($time - WR_chk2 >= tWR)) begin
                Pc_b2 = 'b1;
                Act_b2 = 'b0;
                RP_chk2 = $time;
                Write_precharge[2] = 'b0;
            end
        end
        if ((Write_precharge[3] == 'b1) && ($time - RAS_chk3 >= tRAS)) begin 
            if ((Count_precharge[3] >= burst_length/2+1) && ($time - WR_chk3 >= tWR)) begin
                Pc_b3 = 'b1;
                Act_b3 = 'b0;
                RP_chk3 = $time;
                Write_precharge[3] = 'b0;
            end
        end
    end
    endtask

    task Control_Logic;
    begin
    
      /********************************* Auto Refresh *********************************/
      if(Auto_refresh_enable == 'b1) begin
      
         
        // Display Command Message
        if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t: Auto Refresh", $time);
                
        // Precharge to Auto Refresh
        if (`PRE_to_AREF_TimeChk ) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRP violation during Auto Refresh", $time);
  
        // MR/EMR to Auto Refresh
        if (`MR_EMR_to_AREF_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tMRD violation during Auto Refresh", $time);
               
        // Auto Refresh to Auto Refresh
        if (`AREF_to_AREF_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRFC violation during Auto Refresh", $time); 
                        
        // Precharge to Auto Refresh --Al banks must be precharged
        if ( (Pc_b0 == 'b1) && (Pc_b1 == 'b1) && (Pc_b2 == 'b1) && (Pc_b3 == 'b1)) begin
          
                //Another Auto Refresh is executed. Auto Refresh counter is incremented. 
                aref_count++;
                //Record current tRFC time
                RFC_chk = $time;             
        end 
        else begin
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: All banks must be Precharged before Auto Refresh", $time);
                if (ERROR_STOP == 0) $stop (0);        
        end      
      
      
      end  
        
      /********************************* Extended Mode Register *********************************/
      if(Extended_mode_enable == 'b1) begin
        
        // Display Command Message
        if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t: Extended Mode Register Set", $time);
          
        // Precharge to EMR
        if (`PRE_to_MR_EMR_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRP violation during Extended Mode Register", $time);
            
        // MR/EMR to EMR
        if (`MR_EMR_to_MR_EMR_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tMRD violation during Extended Mode Register", $time);
                    
        // Auto Refresh to EMR
        if (`AREF_to_MR_EMR_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRFC violation during Extended Mode Register", $time);
        
         // Precharge to EMR --Al banks must be precharged
        if ( (Pc_b0 == 'b1) && (Pc_b1 == 'b1) && (Pc_b2 == 'b1) && (Pc_b3 == 'b1)) begin
                               
                //DDL_Enable Logic     
                if(Addr[0] == 'b0) begin
                  DLL_enable = 'b1;
                  if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY EMR: Enable DLL", $time);      
                end    
                else begin
                  DLL_enable = 'b0;
                  if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY EMR: Disable DLL", $time); 
                end  
                
                //Record current tMRD time
                MRD_chk = $time;      
                            
        end 
        else begin
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: All banks must be Precharged before Extended Mode Register", $time);
                if (ERROR_STOP == 0) $stop (0);        
        end    
                
      end
      
       /********************************* Mode Register *********************************/
      if(Mode_reg_enable == 'b1) begin
        
        // Display Command Message
        if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t: Mode Register Set", $time);
        
        // Precharge to MR
        if (`PRE_to_MR_EMR_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRP violation during Mode Register", $time);
            
        // MR/EMR to MR
        if (`MR_EMR_to_MR_EMR_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tMRD violation during Mode Register", $time);
                    
        // Auto Refresh to MR
        if (`AREF_to_MR_EMR_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRFC violation during Mode Register", $time);
        
         
        // Precharge to MR --Al banks must be precharged
        if ( (Pc_b0 == 'b1) && (Pc_b1 == 'b1) && (Pc_b2 == 'b1) && (Pc_b3 == 'b1)) begin
                
                
                
                //Burst Type Value
                
                burst_type = Addr[3];
                $display("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY MR: Burst Type = %s", $time, (burst_type ? "Interleave" : "Sequential"));
                            
                //DDL Reset Logic 
                if( (DLL_enable == 'b1) && (DLL_reset == 'b0) && (Addr[8] == 'b1) ) begin
                  DLL_reset = 'b1;
                  DLL_done  = 'b0;
                  DLL_count = 'd0;  
                end
                else if( (DLL_enable == 'b1) && (DLL_reset == 'b1) && (Addr[8] == 'b1) ) 
                  $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: DLL RESET is already enabled", $time);
                else if( (DLL_enable == 'b1) && (DLL_reset == 'b1) && (Addr [8] == 'b0) )
                  init_device_operation = 'b1; 
                else if( (DLL_enable == 'b1) && (DLL_reset == 'b0) && (Addr [8] == 'b0) )  
                  $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: DLL is ENABLE: DLL RESET is required.", $time);
                else if( (DLL_enable == 'b0) && (Addr [8] == 'b1) ) 
                  $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: DLL is DISABLE: DLL RESET will be ignored.", $time);
                  
                //Burst Length 
                case (Addr [2 : 0])
                    'b001  : begin burst_length = 2; $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY MR: Burst Length = 2", $time); end
                    'b010  : begin burst_length = 4; $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY MR: Burst Length = 4", $time); end
                    'b011  : begin burst_length = 8; $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY MR: Burst Length = 8", $time); end
                    default: begin $display ("%m: [DDR_SDRAM][RM][ERROR] at time %t MEMORY ERROR: Burst Length not supported", $time); end
                endcase
                
                //CAS Latency*2 definition 
                case (Addr [6 : 4])
                  
                    `ifdef SAMSUNG_DDR
                    'b010:  begin cas_latency_x2 = 4; $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY MR: CAS Latency = 2", $time);   end
                    'b011:  begin cas_latency_x2 = 6; $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY MR: CAS Latency = 3", $time);   end
                    'b101:  begin cas_latency_x2 = 3; $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY MR: CAS Latency = 1.5", $time); end
                    'b111:  begin cas_latency_x2 = 5; $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY MR: CAS Latency = 2.5", $time); end
                    default: $display ("%m: [DDR_SDRAM][RM][ERROR] at time %t MEMORY ERROR: CAS Latency not supported", $time);//cas_latency_x2 = 4;
                    
                    `else `define MICRON_DDR                   
                    'b010  : begin cas_latency_x2 = 4; $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY MR: CAS Latency = 2", $time);   end
                    'b110  : begin cas_latency_x2 = 5; $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY MR: CAS Latency = 2.5", $time); end
                    'b011  : begin cas_latency_x2 = 6; $display ("%m: [DDR_SDRAM][RM][Message] at time %t MEMORY MR: CAS Latency = 3", $time);   end
                    default : $display ("%m: [DDR_SDRAM][RM][ERROR] at time %t MEMORY ERROR: CAS Latency not supported", $time);
                    
                    `endif
                    
                    
                endcase
                             
                //Record current tMRD time
                MRD_chk = $time;        
                            
        end 
        else begin
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: All banks must be Precharged before Extended Mode Register", $time);
                if (ERROR_STOP == 0) $stop (0);        
        end    
        
        
      end
      
       /********************************* Activate Bank-Row *********************************/
      if(Active_enable == 'b1) begin
        
        //Display Command Message
        if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t: Activate Bank = %0h, Row = %0h", $time, Ba, Addr);
        
        //Power Up Done?
        if (power_up_done == 'b0) begin
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Power Up and Initialization Sequence not completed before executing Activate command", $time);
                `ifdef err_stop
                 if (ERROR_STOP == 0) $stop (0); 
                `endif  
        end  
        
        //Activate Bank a to Activate Bank b (different bank)
        if ((Prev_bank != Ba) && (`ACTa_to_ACTb_TimeChk)) $display ("m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRRD violation during Activate bank %0h", $time, Ba);
                
        
         //MR/EMR to Activate
        if (`MR_EMR_to_ACT_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tMRD violation during Activate bank %0h", $time, Ba);
                    
        //Auto Refresh to Activate
        if (`AREF_to_ACT_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRFC violation during Activate bank %0h", $time, Ba);
        
        //Precharge to Activate - A bank must be precharged before activation
       // if ((Ba == 'b00 && Act_b0 == 'b1) || (Ba == 'b01 && Act_b1 == 'b1) || (Ba == 'b10 && Act_b2 == 1'b1) || (Ba == 'b11 && Act_b3 == 'b1)) begin
        if ((Ba == 'b00 && Pc_b0 == 'b0) || (Ba == 'b01 && Pc_b1 == 'b0) || (Ba == 'b10 && Pc_b2 == 1'b0) || (Ba == 'b11 && Pc_b3 == 'b0)) begin
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Bank = %0h is already activated", $time, Ba);
                `ifdef err_stop
                 if (ERROR_STOP == 0) $stop (0); 
                `endif
                
        end 
        else begin
 
                 //Activate Bank 0
                if (Ba == 'b00 && Pc_b0 == 'b1) begin
                  
                    //Activate to Activate (same bank, bank 0)
                    if (`ACT0_to_ACT0_TimeChk)  $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRC violation during Activate Bank 0", $time);
                       
                    //Precharge to Activate
                    if (`PRE0_to_ACT0_TimeChk)  $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRP violation during Activate Bank 0", $time); 
                       
                    //Record variables for checking violation
                    Act_b0      = 'b1;
                    Pc_b0       = 'b0;
                    B0_row_addr = Addr;
                    //Record current tRC, tRCD, tRAS tRAP time for bank 0
                    RC_chk0     = $time;
                    RCD_chk0    = $time; 
                    RAS_chk0    = $time;
                    RAP_chk0    = $time;
                end
                
                //Activate Bank 1
                if (Ba == 'b01 && Pc_b1 == 'b1) begin
                  
                    //Activate to Activate (same bank, bank 1)
                    if (`ACT1_to_ACT1_TimeChk)  $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRC violation during Activate Bank 1", $time);
                       
                    //Precharge to Activate
                    if (`PRE1_to_ACT1_TimeChk)  $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRP violation during Activate Bank 1", $time); 
                       
                    //Record variables for checking violation
                    Act_b1      = 'b1;
                    Pc_b1       = 'b0;
                    B1_row_addr = Addr;
                    //Record current tRC, tRCD, tRAS tRAP time for bank 1
                    RC_chk1     = $time;
                    RCD_chk1    = $time; 
                    RAS_chk1    = $time;
                    RAP_chk1    = $time;
                end
  
                //Activate Bank 2
                if (Ba == 'b10 && Pc_b2 == 'b1) begin
                  
                    //Activate to Activate (same bank, bank 2)
                    if (`ACT2_to_ACT2_TimeChk)  $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRC violation during Activate Bank 2", $time);
                       
                    //Precharge to Activate
                    if (`PRE2_to_ACT2_TimeChk)  $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRP violation during Activate Bank 2", $time); 
                       
                    //Record variables for checking violation
                    Act_b2      = 'b1;
                    Pc_b2       = 'b0;
                    B2_row_addr = Addr;
                    //Record current tRC, tRCD, tRAS tRAP time for bank 2
                    RC_chk2     = $time;
                    RCD_chk2    = $time; 
                    RAS_chk2    = $time;
                    RAP_chk2    = $time;
                end
 
                //Activate Bank 3
                if (Ba == 'b11 && Pc_b3 == 'b1) begin
                  
                    //Activate to Activate (same bank, bank 3)
                    if (`ACT3_to_ACT3_TimeChk)  $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRC violation during Activate Bank 3", $time);
                       
                    //Precharge to Activate
                    if (`PRE3_to_ACT3_TimeChk)  $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRP violation during Activate Bank 3", $time); 
                       
                    //Record variables for checking violation
                    Act_b3      = 'b1;
                    Pc_b3       = 'b0;
                    B3_row_addr = Addr;
                    //Record current tRC, tRCD, tRAS tRAP time for bank 3
                    RC_chk3     = $time;
                    RCD_chk3    = $time; 
                    RAS_chk3    = $time;
                    RAP_chk3    = $time;
                end
                
                //Record tRRD and variables for checking violation
                RRD_chk = $time;
                Prev_bank = Ba;
                read_precharge_truncation[Ba] = 'b0;
 
        end
      end
      
      /********************************* Precharge Bank-Row *********************************/
      //NOP if bank is already precharged    
      if(Precharge_enable == 'b1) begin
        
        // Display Command Message
        if (DISPLAY_MESSAGES) begin
           if(Addr[10] == 'b1) $display ("%m: [DDR_SDRAM][RM][Message] at time %t: Precharge All Banks", $time);  
           else  $display ("%m: [DDR_SDRAM][RM][Message] at time %t: Precharge Bank = %0h", $time, Ba);     
        end
        
         // MR/EMR to Precharge
        if (`MR_EMR_to_PRE_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tMRD violation during Precharge", $time);
                    
        // Auto Refresh to Precharge
        if (`AREF_to_PRE_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRFC violation during Precharge", $time);
          
        //Precharge Bank 0
        if ( (Addr[10] == 'b1 || (Addr[10] == 'b0 && Ba == 'b00) ) && Act_b0 == 'b1 ) begin
                
                //Activate to Precharge Bank 0
                if (`ACT0_to_PRE0_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRAS violation during Precharge Bank 0", $time);
                                           
                //tWR violation check for Write
                if (`WRITE_to_PRE0_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tWR violation during Precharge Bank 0", $time);
                   
                //Record variables for checking violation
                Act_b0  = 'b0;
                Pc_b0   = 'b1;
                //Record current tRP time for bank 0
                RP_chk0 = $time;
                
        end
          
        //Precharge Bank 1
        if ( (Addr[10] == 'b1 || (Addr[10] == 'b0 && Ba == 'b01) ) && Act_b1 == 'b1 ) begin
                
                //Activate to Precharge Bank 1
                if (`ACT1_to_PRE1_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRAS violation during Precharge Bank 1", $time);
                                          
                //tWR violation check for Write
                if (`WRITE_to_PRE1_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tWR violation during Precharge Bank 1", $time);
                                   
                //Record variables for checking violation
                Act_b1  = 'b0;
                Pc_b1   = 'b1;
                //Record current tRP time for bank 1
                RP_chk1 = $time;
                               
        end
          
         //Precharge Bank 2
        if ( (Addr[10] == 'b1 || (Addr[10] == 'b0 && Ba == 'b10) ) && Act_b2 == 'b1 ) begin
                
                //Activate to Precharge Bank 2
                if (`ACT2_to_PRE2_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRAS violation during Precharge Bank 2", $time);
                                          
                //tWR violation check for Write
                if (`WRITE_to_PRE2_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tWR violation during Precharge Bank 2", $time);
                                   
                //Record variables for checking violation
                Act_b2  = 'b0;
                Pc_b2   = 'b1;
                //Record current tRP time for bank 2
                RP_chk2 = $time;
                               
        end
        
        //Precharge Bank 3
        if ( (Addr[10] == 'b1 || (Addr[10] == 'b0 && Ba == 'b11) ) && Act_b3 == 'b1 ) begin
                
                //Activate to Precharge Bank 3
                if (`ACT3_to_PRE3_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRAS violation during Precharge Bank 3", $time);
                                          
                //tWR violation check for Write
                if (`WRITE_to_PRE3_TimeChk) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tWR violation during Precharge Bank 3", $time);
                                   
                //Record variables for checking violation
                Act_b3  = 'b0;
                Pc_b3   = 'b1;
                //Record current tRP time for bank 3
                RP_chk3 = $time;
                               
        end     
                  
        // Prech_count is to make sure we have met part of the initialization sequence
        if( Addr[10] == 'b1 && Pc_b0 == 'b1 && Pc_b1 == 'b1 && Pc_b2 == 'b1 && Pc_b3 == 'b1 )
        Prech_count++;
        
        // Pipeline for READ  Read interrupted by Precharge
        A10_precharge [cas_latency_x2] = Addr[10];
        Bank_precharge[cas_latency_x2] = Ba;
        Cmnd_precharge[cas_latency_x2] = 'b1;  
          
        
      end
      
       /********************************* Burst Terminate *********************************/
      if(Burst_terminate_enable == 'b1) begin
        
        // Display Command Message
        if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t: Burst Terminate ", $time);
        
        if (Data_in_enable == 'b1) begin
          
                // Illegal to burst terminate a Write
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: It's illegal to burst terminate a Write", $time);
                `ifdef err_stop
                if (ERROR_STOP == 0) $stop (0);
                `endif
                   
        end 
        else if ( (Read_precharge[0] == 'b1) || (Read_precharge[1] == 'b1) || (Read_precharge[2] == 'b1) || (Read_precharge[3] == 'b1) ) begin
          
                // Illegal to burst terminate a Read with Auto Precharge
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: It's illegal to burst terminate a Read with Auto Precharge", $time);   
                 `ifdef err_stop
                if (ERROR_STOP == 0) $stop (0);
                `endif
              
        end 
        else begin
                // Burst Terminate Command Pipeline for Read
                Cmnd_bst[cas_latency_x2] = 'b1;
        end
        
        
      end
      
      
      /********************************* Read Command *********************************/
      if(Read_enable == 'b1) begin
        
        //Power Up Done?
        if (power_up_done == 'b0) begin
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Power Up and Initialization Sequence not completed before executing Read Command", $time);
                `ifdef err_stop
                 if (ERROR_STOP == 0) $stop (0); 
                `endif  
        end
        
        // Check for DLL reset before Read 
        if ( (DLL_reset == 'b1) && (DLL_done == 'b0) ) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: You need to wait 200 tCK after DLL Reset Enable before executing Read Command, Not %0d clocks.", $time, DLL_count); 
                     
        // Display Command Message
        if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t: Read Bank = %0h, Col = %h", $time, Ba, {Addr [11], Addr [9 : 0]});
          
        //Terminate a Write
        if (Data_in_enable == 'b1) begin
                Data_in_enable = 'b0;
        end
        
        //Activate to Read without Auto Precharge
        if (    (Addr [10] == 'b0 && Ba == 'b00 && `ACT0_to_READ_TimeChk) ||
                (Addr [10] == 'b0 && Ba == 'b01 && `ACT1_to_READ_TimeChk) ||
                (Addr [10] == 'b0 && Ba == 'b10 && `ACT2_to_READ_TimeChk) ||
                (Addr [10] == 'b0 && Ba == 'b11 && `ACT3_to_READ_TimeChk)) begin
                $display("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRCD violation during Read from Bank %0h", $time, Ba);
        end

        //Activate to Read with Auto Precharge
        if (    (Addr [10] == 'b1 && Ba == 'b00 && `ACT0_to_READA_TimeChk) ||
                (Addr [10] == 'b1 && Ba == 'b01 && `ACT1_to_READA_TimeChk) ||
                (Addr [10] == 'b1 && Ba == 'b10 && `ACT2_to_READA_TimeChk) ||
                (Addr [10] == 'b1 && Ba == 'b11 && `ACT3_to_READA_TimeChk)) begin
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRAP violation during Read from Bank %0h", $time, Ba);
        end
        
        
        //Interrupt a Read with Auto Precharge (same bank only)
        if (Read_precharge [Ba] == 'b1) begin
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: It's illegal to interrupt a Read with Auto Precharge", $time);
                `ifdef err_stop
                 if (ERROR_STOP == 0) $stop (0); 
                `endif 
                
                // Cancel Auto Precharge
                if (Addr[10] == 'b0)  Read_precharge [Ba]= 'b0;    
        end
        
        // Activate to Read Logic
        if ((Ba == 'b00 && Pc_b0 == 'b1) || (Ba == 'b01 && Pc_b1 == 'b1) ||
            (Ba == 'b10 && Pc_b2 == 'b1) || (Ba == 'b11 && Pc_b3 == 'b1)) begin
                $display("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Bank %0d is not Activated for Read", $time, Ba);
                `ifdef err_stop
                 if (ERROR_STOP == 0) $stop (0); 
                `endif 
        end 
        else begin
                // CAS Latency pipeline
                Read_cmnd[cas_latency_x2] = 'b1;
                Read_bank[cas_latency_x2] = Ba;
                Read_cols[cas_latency_x2] = {Addr [ADDR_BITS - 1 : 11], Addr [9 : 0]};
                // Auto Precharge
                if (Addr[10] === 1'b1) begin
                    Read_precharge  [Ba]= 'b1;
                    Count_precharge [Ba]= 0;
                end
        end
        
        
      end
      
      /********************************* Write Command *********************************/
      if(Write_enable == 'b1) begin
        
        //Power Up Done?
        if (power_up_done == 'b0) begin
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Power Up and Initialization Sequence not completed before executing Write Command", $time);
                `ifdef err_stop
                 if (ERROR_STOP == 0) $stop (0); 
                `endif 
        end
        
        // Display Command Message
        if (DISPLAY_MESSAGES) $display ("%m: [DDR_SDRAM][RM][Message] at time %t: Write Bank = %0h, Col = %0h", $time, Ba, {Addr [ADDR_BITS - 1 : 11], Addr [9 : 0]});
        
         // Check for DLL reset before Write 
        if ( (DLL_reset == 'b1) && (DLL_done == 'b0) ) $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: You need to wait 200 tCK after DLL Reset Enable before executing Write Command, Not %0d clocks.", $time, DLL_count);
        
        // Activate to Write
        if (    (Ba == 'b00 && `ACT0_to_WRITE_TimeChk) ||
                (Ba == 'b01 && `ACT1_to_WRITE_TimeChk) ||
                (Ba == 'b10 && `ACT2_to_WRITE_TimeChk) ||
                (Ba == 'b11 && `ACT3_to_WRITE_TimeChk)) begin
                $display("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: tRCD violation during Write to Bank %h", $time, Ba);
        end
        
        
        // Read to Write
        if (Read_cmnd[0] || Read_cmnd[1] || Read_cmnd[2] || Read_cmnd[3] || 
            Read_cmnd[4] || Read_cmnd[5] || Read_cmnd[6] || (Burst_counter < burst_length)) begin
              
                if (Data_out_enable || read_precharge_truncation[Ba]) begin
                    $display("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Read to Write violation: Illegal for a Write to interrupt a Read with Auto Precharge or a Read without Burst Termination", $time);
                end
        end
         
        
        //Interrupt a Write with Auto Precharge (same bank only)
        if (Write_precharge [Ba] == 'b1) begin
                $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: It's illegal to interrupt a Write with Auto Precharge", $time);
                `ifdef err_stop
                 if (ERROR_STOP == 0) $stop (0); 
                `endif 
                
                // Cancel Auto Precharge
                if (Addr[10] == 'b0)  Write_precharge [Ba]= 'b0;    
        end
        
        
        // Activate to Write
        if ((Ba == 'b00 && Pc_b0 == 'b1) || (Ba == 'b01 && Pc_b1 == 'b1) ||
            (Ba == 'b10 && Pc_b2 == 'b1) || (Ba == 'b11 && Pc_b3 == 'b1)) begin
                $display("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Bank %0d is not Activated for Write", $time, Ba);
                `ifdef err_stop
                 if (ERROR_STOP == 0) $stop (0); 
                `endif 
        end 
        else begin
                // Pipeline for Write  
                Write_cmnd [3] = 'b1;
                Write_bank [3] = Ba;
                Write_cols [3] = {Addr [ADDR_BITS - 1 : 11], Addr [9 : 0]};
                // Auto Precharge
                if (Addr[10] == 1'b1) begin
                    Write_precharge [Ba]= 'b1;
                    Count_precharge [Ba]= 0;
                end
        end
        
      end
    
    /********************************* **************** *********************************/
    end
    endtask: Control_Logic    
    
     task check_neg_dqs;
    begin
        if (Write_cmnd[2] || Write_cmnd[1] || Data_in_enable) begin
            for (i=0; i<DQS_BITS; i=i+1) begin
                if (expect_neg_dqs[i]) begin
                    $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Negative DQS[%1d] transition required.", $time, i);
                end
                expect_neg_dqs[i] = 1'b1;
            end
        end else begin
            expect_pos_dqs = 0;
            expect_neg_dqs = 0;
        end
    end
    endtask

    task check_pos_dqs;
    begin
        if (Write_cmnd[2] || Write_cmnd[1] || Data_in_enable) begin
            for (i=0; i<DQS_BITS; i=i+1) begin
                if (expect_pos_dqs[i]) begin
                    $display ("%m: [DDR_SDRAM][RM][Error] at time %t MEMORY ERROR: Positive DQS[%1d] transition required.", $time, i);
                end
                expect_pos_dqs[i] = 1'b1;
            end
        end else begin
            expect_pos_dqs = 0;
            expect_neg_dqs = 0;
        end
    end
    endtask
    
    
    // Main Logic
    
    //tasks which are executed on the positive edge of the System Clock
    always @ (posedge Sys_clk) begin
        Manual_Precharge;
        Burst_Terminate;
        Dq_Dqs_Drivers;
        Write_FIFO_DM_Mask_Logic;
        Burst_Decode;
        check_neg_dqs;
        Auto_Precharge_Calculation;
        DLL_Counter; 
        Control_Logic;
    end
    
    //tasks which are executed on the megative edge of the System Clock
    always @ (negedge Sys_clk) begin
        Manual_Precharge;
        Burst_Terminate;
        Dq_Dqs_Drivers;
        Write_FIFO_DM_Mask_Logic;
        Burst_Decode;
        check_pos_dqs;
    end

    // Dqs Receiver
    always @ (posedge Dqs_in[0]) begin
        // Latch data at posedge Dqs
        dq_rise[7 : 0] = Dq_in[7 : 0];
        dm_rise[0] = Dm_in[0];
        expect_pos_dqs[0] = 0;
    end

    always @ (posedge Dqs_in[1]) begin
        // Latch data at posedge Dqs
        dq_rise[15 : 8] = Dq_in[15 : 8];
        dm_rise[1] = Dm_in [1];
        expect_pos_dqs[1] = 0;
    end

    always @ (posedge Dqs_in[2]) begin
        // Latch data at posedge Dqs
        dq_rise[23 : 16] = Dq_in[23 : 16];
        dm_rise[2] = Dm_in [2];
        expect_pos_dqs[2] = 0;
    end

    always @ (posedge Dqs_in[3]) begin
        // Latch data at posedge Dqs
        dq_rise[31 : 24] = Dq_in[31 : 24];
        dm_rise[3] = Dm_in [3];
        expect_pos_dqs[3] = 0;
    end

    always @ (negedge Dqs_in[0]) begin
        // Latch data at negedge Dqs
        dq_fall[7 : 0] = Dq_in[7 : 0];
        dm_fall[0] = Dm_in[0];
        dm_pair[1:0]  = {dm_rise[0], dm_fall[0]};
        expect_neg_dqs[0] = 0;
    end

    always @ (negedge Dqs_in[1]) begin
        // Latch data at negedge Dqs
        dq_fall[15: 8] = Dq_in[15 : 8];
        dm_fall[1] = Dm_in[1];
        dm_pair[3:2]  = {dm_rise[1], dm_fall[1]};
        expect_neg_dqs[1] = 0;
    end

    always @ (negedge Dqs_in[2]) begin
        // Latch data at negedge Dqs
        dq_fall[23: 16] = Dq_in[23 : 16];
        dm_fall[2] = Dm_in[2];
        dm_pair[5:4]  = {dm_rise[2], dm_fall[2]};
        expect_neg_dqs[2] = 0;
    end

    always @ (negedge Dqs_in[3]) begin
        // Latch data at negedge Dqs
        dq_fall[31: 24] = Dq_in[31 : 24];
        dm_fall[3] = Dm_in[3];
        dm_pair[7:6]  = {dm_rise[3], dm_fall[3]};
        expect_neg_dqs[3] = 0;
    end
    
     specify
        
        `ifdef SAMSUNG_DDR
                                              // SYMBOL UNITS DESCRIPTION
                                              // ------ ----- -----------
        specparam tDSS             =     0.6; // tDSS   ns    DQS falling edge to CLK rising (setup time) =  0.4*tCK
        specparam tDSH             =     0.6; // tDSH   ns    DQS falling edge from CLK rising (hold time) = 0.4*tCK
        specparam tIH              =   0.900; // tIH    ns    Input Hold Time
        specparam tIS              =   0.900; // tIS    ns    Input Setup Time
        specparam tDQSH            =   3.000; // tDQSH  ns    DQS input High Pulse Width = 0.4*tCK
        specparam tDQSL            =   3.000; // tDQSL  ns    DQS input Low Pulse Width = 0.4*tCK
        
        `else `define MICRON_DDR
                                              // SYMBOL UNITS DESCRIPTION
                                              // ------ ----- -----------
        specparam tDSS             =     1.5; // tDSS   ns    DQS falling edge to CLK rising (setup time) = 0.2*tCK
        specparam tDSH             =     1.5; // tDSH   ns    DQS falling edge from CLK rising (hold time) = 0.2*tCK
        specparam tIH              =   0.900; // tIH    ns    Input Hold Time
        specparam tIS              =   0.900; // tIS    ns    Input Setup Time
        specparam tDQSH            =   2.625; // tDQSH  ns    DQS input High Pulse Width = 0.35*tCK
        specparam tDQSL            =   2.625; // tDQSL  ns    DQS input Low Pulse Width = 0.35*tCK
        `endif
        
        $width    (posedge Dqs_in[0] &&& wdqs_valid, tDQSH);
        $width    (posedge Dqs_in[1] &&& wdqs_valid, tDQSH);
        $width    (negedge Dqs_in[0] &&& wdqs_valid, tDQSL);
        $width    (negedge Dqs_in[1] &&& wdqs_valid, tDQSL);
        $setuphold(posedge Clk,   Cke,   tIS, tIH);
        $setuphold(posedge Clk,   Cs_n,  tIS, tIH);
        $setuphold(posedge Clk,   Cas_n, tIS, tIH);
        $setuphold(posedge Clk,   Ras_n, tIS, tIH);
        $setuphold(posedge Clk,   We_n,  tIS, tIH);
        $setuphold(posedge Clk,   Addr,  tIS, tIH);
        $setuphold(posedge Clk,   Ba,    tIS, tIH);
        $setuphold(posedge Clk, negedge Dqs &&& wdqs_valid, tDSS, tDSH);
        
    endspecify
    
    
        
endmodule

