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

`ifndef __truss__
`define __truss__


`include "teal.svh"

`ifdef VCS
  `define virtual_interfaces_in_packages
 `endif

`ifdef ATHDL_SIM
 `define   virtual_interfaces_in_packages
`endif

`ifdef MTI
 `define   virtual_interfaces_in_packages
`endif

 
//If the simulator does not support interfaces delcared in packages, put them outside.
interface watchdog_interface (
   input reg hdl_timeout_,
`ifdef ATHDL_SIM
    input reg [`COUNTER_WIDTH-1:0] hdl_timeout_count_
`else
`ifdef MTI
   output reg [`COUNTER_WIDTH-1:0] hdl_timeout_count_
`else
   output reg [COUNTER_WIDTH-1:0] hdl_timeout_count_
`endif
`endif
  );
endinterface
   
package truss;

`define old_truss_assert(x) if (!(x)) log_.fatal (" assertion failure: x")
`define truss_assert(x) if (!(x)) log_.fatal(`" assertion failure: x`")

typedef enum {cold, warm} reset;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
virtual class verification_component;
  protected string name_;
  protected teal::vout log_;

   function new (string n); name_ = n; log_ = new (n); endfunction

   //engage pull ups,downs, and things like sense pins
  `PURE virtual task time_zero_setup ();

  //take your part of the DUT out of reset
  //may NOT be called in a loop/rerun/multiple test scenerio
  `PURE virtual task out_of_reset (reset r);

  `PURE virtual function void randomize2 ();

  //after this call, the component is ready for traffic 
  //(why not start of BFM calls this? , because generally usefull method, subcomponents)
  `PURE virtual task write_to_hardware ();

  //on start(), do what makes sense for the object type.
  //for big picture verifictaion components, engage your configuration, start monitors and BFMs
  //do NOT asume that the resisters are at reset, unless you know that for sure
  `PURE virtual task start ();

  //stop_all_threads, get back to the state just before the start call
//not clear that the scope disable works in all sv varients yet
//  `PURE virtual task stop ();

  //or not supposed to be in the generic thing? But needed in a checker
  //called after stop (automatically, or by owner?)
  `PURE virtual task wait_for_completion (); 

  //can mean different things, but generally report your state.
  `PURE virtual function void report (string prefix);

  function string name(); name = name_; endfunction

endclass


typedef class watchdog;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
virtual   class test_base extends verification_component;
      protected watchdog watchdog_;

      function new (string n, watchdog w);
	 super.new (n);
	 watchdog_ = w;
      endfunction 
	   
   endclass // test_base

typedef class test_base;
typedef class testbench_base;
typedef class watchdog;

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  class shutdown;
    //either verification_top is a friend or these have to be public. because there is a creation  order dependency
    test_base      test_; 
    testbench_base testbench_;
    watchdog       watchdog_;
    local teal::vout log_;

     function new (string name); log_ = new (name); endfunction

     extern function void  shutdown_now (string reason);  //implementation in verification_top.cpp

     endclass // shutdown


virtual class interfaces_dut;
//would like to put the watchdog interface in here!
endclass

virtual class testbench_base  extends verification_component;
   function new (string n, interfaces_dut dut); super.new (n); endfunction 
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class error_limit_vlog extends teal::vlog;
   local int limit_;
   local shutdown shutdown_;
   local bit triggered_;

   function new (int limit, shutdown s); limit_ = limit; shutdown_ = s; triggered_ = 0; endfunction 

   function void output_message (teal::message_list msg);
      super.output_message (msg);
   endfunction 

   protected virtual function string local_print_ (string val); 
      if ((!triggered_) && (how_many (teal::vout_error) >= limit_)) begin
	 triggered_ = 1;
	 shutdown_.shutdown_now ("Error threshold reached."); 
      end
      return val; 
   endfunction

endclass 

virtual class Checker;
    protected teal::latch expected_check_;
    protected int expected_check_count_;

    teal::latch actual_check_;
    int actual_check_count_;

    function new ();    
       expected_check_ = new ("checker", 1);
       actual_check_ = new ("checker", 1);
       actual_check_count_ = 0;
       expected_check_count_ = 0;
    endfunction
       
   task wait_expected_check (); expected_check_.pause ();endtask
   task wait_actual_check (); actual_check_.pause (); endtask

    `PURE virtual task wait_for_completion (); 
    `PURE virtual function void report (string prefix);


    function int expected_check_count(); return expected_check_count_;   endfunction
    function int actual_check_count(); return actual_check_count_;   endfunction
       
       virtual protected task note_expected_check (); expected_check_.signal (); ++expected_check_count_; endtask
       virtual protected task note_actual_check (); actual_check_.signal ();  ++actual_check_count_; endtask

endclass 

typedef int data_type;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class int_channel;
   local data_type storage_[$];
   local teal::latch put_condition_;
   local teal::latch get_condition_;
   local bit[63:0] depth_;
   local semaphore mutex_;
   local int_channel listners_[$];  //template on data_type once classes can be templated
   local teal::vout log_;

   function new  (string n, bit[63:0] d = 64'hFFFF_FFFF_FFFF_FFFF);
      put_condition_ = new ({n,  "_put_channel_condition"}, 1);
      get_condition_ = new ({n, "_get_channel_condition"}, 1);
      depth_ = d;
      mutex_ = new (1);
      log_ = new (n);
   endfunction // new


   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   task put (data_type d);
      bit [63:0] count_; count(count_);      
      if (count_ >= depth_) begin
	 get_condition_.pause ();
      end
      mutex_.get ();
      begin
	 string msg;
	 msg = $psprintf ("put() : data is %0d", d); //REWORK FOR YOUR DATA_TYPE!
	 log_.debug (msg);
      end
      storage_.push_back (d);
      mutex_.put ();
      put_condition_.signal ();

      //now for the attached channels
      for (integer i = 0; i < listners_.size(); ++i) begin
	 listners_[i].put (d);
      end
   endtask // put
   
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   task get (output data_type returned);
      begin
	 string msg;
	 bit [63:0] count_;
	 int foo;
	 
	 count(count_);	 
	 msg = $psprintf ("get() : count is %0d", count_); 
	 log_.debug (msg);
      end

      //humm could be an infinate loop if time does not advance (because the event is trigerred)
      begin
	 bit [63:0]    count_; count(count_);
      while  (!count_) begin
	 put_condition_.pause ();
	 begin
	    string msg;
	    bit [63:0] count_;
	    int foo;
	    count(count_);
	    msg = $psprintf ("get() : after wait. count is %0d", count_); 
	    log_.debug (msg);
	 end
	count(count_);	      
      end
	 end
      
      mutex_.get ();
      returned = storage_.pop_front();
      mutex_.put ();
      begin
	 string msg;
	 msg = $psprintf ("get() : data is %0d", returned); //REWORK FOR YOUR DATA_TYPE!
	 log_.debug (msg);
      end
      
      get_condition_.signal ();
   endtask

   
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   task count (output bit [63:0] returned);
      mutex_.get ();
      returned = storage_.size();
      mutex_.put ();
   endtask

   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   
   function string name (); return log_.name ();  endfunction

   task add_listner (int_channel new_one);
      listners_.push_back (new_one);
   endtask // add_listner

endclass

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
virtual class test_component  extends verification_component;
    protected bit completed_;

   function new (string n);
      super.new (n);
      completed_ = 1;
   endfunction // new
   
    virtual task start (); fork  start_ (); join_none endtask

   task wait_for_completion (); wait_for_completion_(); completed_ = 1; endtask

   function void report (string prefix);
       if (completed_) begin log_.debug ({prefix, " Completed as expected."}); end
       else begin log_.error ({prefix, " Did not complete!"});  end
    endfunction

//Protected interface
    virtual protected task start_ ();
       log_.debug ("start_() for test_component  begin");
       completed_ = 0;
       start_components_ ();
       run_component_traffic_ ();
       log_.debug ("start_() for test_component  end");
    endtask // start_
   

   virtual task run_component_traffic_ (); randomize2 (); generate2 (); endtask
   
  `PURE virtual protected task start_components_ ();
   //generate some data 
  `PURE  protected virtual task generate2 ();
  `PURE virtual protected task wait_for_completion_ ();
 endclass // test_component


  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
virtual class irritator  extends test_component;
    local bit generate_;

   function new (string n);
      super.new (n);
      generate_ = 0;
   endfunction // new

   task stop_generation (); generate_ = 0; endtask

   protected virtual task  start_ ();
       log_.debug ("start_() for irritator begin");
       generate_ = 1;
       super.start_ ();
       log_.debug ("start_() for irritator end");
    endtask 
      

   virtual protected task run_component_traffic_ ();
       log_.debug ("run_trafic_() for irritator begin");
       while (continue_generation ()) begin
	  super.run_component_traffic_ ();
	  inter_generate_gap ();
       end
       log_.debug ("run_trafic_() for irritator begin");
    endtask 
      


   virtual protected function bit continue_generation (); return generate_; endfunction

    //subclass to do things like manage an amount in_flight, random delay
    //CAUTION: It's generally a good idea to have this method consume time. Otherwise, an infinate loop can occur.
    //At least one of the following three methods MUST consume time: 
    //                      continue_generation(), run_traffic() [i.e randomize2(); generate();], or inter_generate_gap()
    `PURE protected virtual task inter_generate_gap ();
    endclass 

typedef class shutdown;
typedef class verification_component;
      

//used in the .v as well


//put the wires in the interface to not change watchdog.v
//MUST copy to /testbench/$config/interfaces_dut.svh
`ifdef virtual_interfaces_in_packages
   `ifdef virtual_interface_declarations_in_interface
interface watchdog_interface (
   wire hdl_timeout_,
   wire [COUNTER_WIDTH-1:0] hdl_timeout_count_;
  );
endinterface // watchdog_interface
   `endif
`endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class watchdog extends verification_component;
`ifdef virtual_interfaces_in_packages   
   virtual watchdog_interface  watchdog_interface_;
   
    extern function new (string name, virtual watchdog_interface pins, shutdown s);
`else
    extern function new (string name, shutdown s);
`endif       

    virtual task time_zero_setup (); endtask
    virtual task out_of_reset (reset r); endtask
    virtual function void randomize2 (); endfunction
    virtual task write_to_hardware (); endtask
    virtual task start (); fork start_ (); join_none endtask
    extern virtual task wait_for_completion ();

    extern virtual function void report (string prefix);

    //for remote or other watchdog mechanisms to create a timeout
    extern task shutdown_now (string prefix);

    extern local task start_ ();
    local shutdown shutdown_;
    local bit timeout_occurred_;
    local bit hdl_timeout_occurred_;
//    local virtual watchdog_interface watchdog_interface_;
    endclass // truss_watchdog
   
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   function string version (); return  "truss_2.00";   endfunction
endpackage

//interfaces are not allowed in a package, so the folowing cannot be inside of truss :-(
`include "truss_watchdog.svh"
`endif
