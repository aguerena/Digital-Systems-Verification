/****************************************************************************************************/
// Title      : DDR SDRAM Environment
// File       : DDR_Environment.sv
/****************************************************************************************************/ 
// Author                : Alejandro Guerena
// E-Mail                : md679705@iteso.mx
// Date of last revision : 06-Aug-2011
// Notes                 : None 
/****************************************************************************************************/
import DDR_EnvPackage::*;

class DDR_Environment; 

  `include "DDR_ParametersPkg.sv"

   //------------------------------------------ 
  // Interfaces
  virtual interface DDR_Interface    DDR_If;
  virtual interface DDR_InterfaceInt DDR_IntIf;
  
  //------------------------------------------ 
  // Instances References
  DDR_TBFM TBFM;
  DDR_RBFM RBFM;  
  
  `ifdef  TEST5
       DDR_Test5 Test5;
  `else `ifdef  TEST4
       DDR_Test4 Test4;
  `else `ifdef  TEST3
       DDR_Test3 Test3;
  `else `ifdef  TEST2
       DDR_Test2 Test2;
  `else `define TEST1
       DDR_Test1 Test1; 
  `endif `endif `endif `endif
   
  DDR_Coverage Cov;
  
  //------------------------------------------ 
  // Constructor
   function new (virtual interface DDR_Interface DDR_IfEnv, virtual interface DDR_InterfaceInt DDR_IntIfEnv);
    DDR_If      = DDR_IfEnv;
    DDR_IntIf   = DDR_IntIfEnv;
    TBFM        = new( DDR_If );
    RBFM        = new( DDR_If, DDR_IntIf );  
    
    
    
    `ifdef TEST5
       Test5       = new();
       Test5.pTBFM = TBFM;
       Test5.pRBFM = RBFM;
        
    `else `ifdef  TEST4
       Test4       = new();
       Test4.pTBFM = TBFM; 
       Test4.pRBFM = RBFM;
       
    `else `ifdef  TEST3
       Test3       = new();
       Test3.pTBFM = TBFM;  
       Test3.pRBFM = RBFM;
    `else `ifdef  TEST2
       Test2       = new(); 
       Test2.pTBFM = TBFM;
       //Test2.pRBFM = RBFM; 
    `else `define TEST1
       Test1       = new();
       Test1.pTBFM = TBFM; 
    `endif `endif `endif `endif
    
    Cov         = new();
    Cov.pRBFM   = RBFM; 
    
  endfunction
 
  //------------------------------------------ 
  // Tasks
  task Run();
  
    #10;
    
    `ifdef TEST5
       Test5.Run();
    `else `ifdef  TEST4
       Test4.Run();
    `else `ifdef  TEST3
       Test3.Run();
    `else `ifdef  TEST2
       Test2.Run();
    `else `define TEST1
       Test1.Run(); 
    `endif `endif `endif `endif
      
    #10;
    Cov.Show_Coverage();  
    
  endtask: Run

  task Run_MonAndCheck();
    
    fork
      RBFM.RunMonitor;
      RBFM.RunChecker;
      Cov.Sample_Coverage(); 
    join
    
  endtask: Run_MonAndCheck
  

endclass: DDR_Environment

