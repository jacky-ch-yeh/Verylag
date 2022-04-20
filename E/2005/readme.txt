
****Please use Microsoft WordPad  to open these files!

1. Use winzip.exe or winrar.exe to extract the fpga_contest.zip file! There are 9 files and 4 directories 
    provided by CIC in "Altrea_xxxxx"  directory.

        .\readme.txt                          Contains file descriptions and some important notes 
        .\fpga_contest.pdf                 The description of FPGA contest problem.
        .\report000.txt                       This file is used to describe the materials
                            	                     that should be handed in by each team. The
                            	                     design, file name, tool names, specifications
                            	                     and others are described in this file.
        .\reporttem.txt	                     The template of the report.000
        \Project\CS.v                        The declaration of the CS module for Verilog
        \Project\CS.vhd	     The declaration of the CS  entity for VHDL
        \Simulation\testfixture.v       Testfixture file
        \Simulation\in.dat                 Input patterns
        \Simulation\out_golden.dat   Expected result data
        \Simulation\Verilog_lib        Altera FPGA simulation library for Verilog (for timing simulation)
        \Simulation\VHDL_lib         Altera FPGA simulation library for VHDL (for timing simulation)
        \Result\Function_sim            RTL Simulation results should be duplicated in this directory.
        \Result\Timing_sim              Post-layout Gate-level simulation results should be duplicated in this directory.
        
2. To test your circuit's performance, you can change the clock
   period by modifying the definition "CYCLE" in testfixture.v.
   clock period = CYCLE. 

3. For Post-layout Gate-Level simulation, you must generate the SDF file by Quartus-II and and 
   change the SDF file name by modifying the definition "SDFFILE" in the testfixture.v. 

4. CIC provides FPGA device simulation model library in \Simulation\Verilog_lib (for Verilog users) and \Simulation\VHDL_lib 
   (for VHDL users) directories for Quartus-II 4.1. If your Quartus-II version is not 4.1,  you can also find these FPGA device simulation model libraries  in 
    C:\Quartus II INSTALLATION DIRECTORY\eda\sim_lib\ in your client PC. 