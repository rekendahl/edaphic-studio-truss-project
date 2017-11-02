/*
 Trusster Open Source License version 1.0a (TRUST)
 copyright (c) 2006 Mike Mintz and Robert Ekendahl.  All rights reserved. 

 Redistribution and use in source and binary forms, with or without modification, 
 are permitted provided that the following conditions are met: 
 
 * Redistributions of source code must retain the above copyright notice, 
 this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, 
 this list of conditions and the following disclaimer in the documentation 
 and/or other materials provided with the distribution.
 * Redistributions in any form must be accompanied by information on how to obtain 
 complete source code for this software and any accompanying software that uses this software.
 The source code must either be included in the distribution or be available in a timely fashion for no more than 
 the cost of distribution plus a nominal fee, and must be freely redistributable under reasonable and no more 
 restrictive conditions. For an executable file, complete source code means the source code for all modules it 
 contains. It does not include source code for modules or files that typically accompany the major components 
 of the operating system on which the executable file runs.
 

 THIS SOFTWARE IS PROVIDED BY MIKE MINTZ AND ROBERT EKENDAHL ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, 
 OR NON-INFRINGEMENT, ARE DISCLAIMED. IN NO EVENT SHALL MIKE MINTZ AND ROBERT EKENDAHL OR ITS CONTRIBUTORS 
 BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
 OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
 EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

`include "testbench.svh"

`include "truss.svh"

`include "uart_bfm_agent.svh"
`include "uart_16550_agent.svh"
`include "uart_generator_agent.svh"
`include "uart_checker_agent.svh"
`include "uart_16550_configuration.svh"

`include "wishbone_driver.svh"
`include "wishbone_memory_bank.svh"

`define uart_registers_first 0
`define uart_registers_last 7

import truss::*;

parameter teal::uint64 UART_CLOCK_FREQUENCY =  29489826; //29.4Mhz

`include "interfaces_uart.svh"

function  testbench::new ( string top_path, truss::interfaces_dut dut_base);
   interfaces_uart uart_dut;   
   super.new (top_path, dut_base);
   log_.debug ("testbench new() begin ");

   begin
      int foo = $cast (uart_dut, dut_base);
      assert (foo);
   end

   begin
      //build the channels of the bi-directional interface
      uart_channel program_egress = new  ("program egress");
      uart_channel program_egress_tap = new  ("protocol egress tap");

      uart_channel program_ingress = new ("program ingress");

      uart_channel protocol_ingress = new  ("protocol ingress");
      uart_channel protocol_ingress_tap = new  ("protocol ingress tap");


      uart_channel protocol_egress = new ("protocol egress");

      //build the configuration of the interface
      uart_configuration = new ("Program");

      program_egress.add_listner (program_egress_tap);
      protocol_ingress.add_listner (protocol_ingress_tap);
      
      //build the connection layer of the interface
      begin
	 uart_bfm_agent ba = new ("uart Protocol", uart_dut.uart_interface_1, uart_configuration, UART_CLOCK_FREQUENCY, protocol_ingress, protocol_egress);
	 uart_protocol_bfm = ba;
      end

      begin
	 uart_16550_agent sfm = new  ("16550 uart", uart_dut.uart_16550_interface_1,  uart_configuration, UART_CLOCK_FREQUENCY, program_egress,   program_ingress);
	 uart_program_sfm   = sfm;
      end
      
      begin
	 //build and hookup the ingress and egress stimulus and scoreboards of the interface
	 uart_generator_agent  gen_agent = new ("egress_generator", uart_configuration, program_egress);
	 uart_egress_generator = gen_agent;
      end
      begin
	 uart_checker_agent check_agent = new  ("egress checker", program_egress_tap, protocol_egress);	 
	 uart_egress_checker = check_agent;
      end


      begin
	 uart_generator_agent gen_agent = new  ("ingress_generator", uart_configuration, protocol_ingress);
	 uart_ingress_generator = gen_agent;
      end
      begin
	 uart_checker_agent check_agent = new  ("ingress checker", protocol_ingress_tap, program_ingress);	 
	 uart_ingress_checker = check_agent;
      end
      

      //Now for the main chip register interface
      wishbone_driver_ = new ("WB", uart_dut.wishbone_driver_interface_1);
      begin
	 wishbone_memory_bank mb = new ("main_bus", wishbone_driver_);
	 teal::add_memory_bank (mb);
	 teal::add_map ("main_bus", `uart_registers_first, `uart_registers_last);
      end

   end // begin
   
   top_reset_ = uart_dut.top_reset_;
   
      log_.debug ( "testbench new() done ");
   endfunction 


task testbench::time_zero_setup ();
   top_reset_.wb_rst_ir <= 1;
   #1;
endtask

task testbench::out_of_reset (truss::reset r);
   top_reset_.wb_rst_ir = 1;
   log_.info ("before pause");
   
   wishbone_driver_.pause (10);
   log_.info ("after pause");
   
   top_reset_.wb_rst_ir = 0;
endtask

function void testbench::randomize2 ();  uart_configuration.randomize2 (); endfunction
task testbench::write_to_hardware (); endtask
task testbench::start (); log_.info ("testbench starting"); endtask


//no wait_for_completion, let the test/exercisors do that
task testbench::wait_for_completion (); endtask
function void testbench::report (string prefix);  uart_configuration.report (prefix); endfunction


