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

`ifndef __teal__
`define __teal__

`ifndef PURE
`define PURE pure
`endif


`ifndef aldec
   package teal;
`endif

  typedef bit[7:0] uint8;
  typedef bit[15:0] uint16;  
  typedef bit[31:0] uint32;  
  typedef bit[63:0] uint64;

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Teal predefined message IDs (reserved from 0x800 - 0xf00)
    //Note: Applications can use 0x00 through 0x7ff
    typedef enum {vout_first_id = 32'h800, vout_time, vout_thread_name, vout_functional_area,
		  vout_fatal, vout_error, vout_info, vout_debug, vout_message_data, vout_endl,
		  vout_file, vout_line, vout_endm, vout_last_id} teal_predefined_message_ids;

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class message; integer id; string value; endclass
class message_list;
   extern function void put_message (integer id, string value);
   extern function string convert_to_string (output bit fatal_seen);
    message the_list_[$]; //would like it to be friend to vlog
endclass

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
virtual class vlog;
   extern function new ();
   extern function vlog get ();

   extern function void output_message (message_list msg);
   extern function void local_print (string val);
    extern function integer how_many (integer an_id); //given a meta-info tag, how many got printed?


    protected virtual function automatic message_list output_message_ (message_list m);
	      return m;
            endfunction


`ifdef ncsim
    protected virtual function string local_print_ (string val); endfunction
`else
    `PURE protected virtual function string local_print_ (string val);
`endif


    static vlog the_;
    protected static int id_count_[*];

    protected vlog after_me_; //use by the push logic to create a chain (intrusive list)
    protected bit fatal_message_seen_;
  endclass

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class file_vlog  extends vlog;
    extern function new (string file_name, bit also_to_screen = 1);

    extern protected virtual function string local_print_ (string val);

      local integer out_file_;
      local bit also_to_screen_;
 endclass


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    parameter  integer debug = 1; //can be used with debug_level()
    parameter  integer no_debug = 0; //can be used with debug_level()

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 class vout;
	extern function new (string functional_area, integer initial_show_level = no_debug);
        extern function string name ();

	extern function void info (string msg);
	extern function void  error (string msg);
	extern function void  fatal (string msg);
	extern function void  debug (string msg);
	extern function void  debug_n (integer level, string msg);

	extern function integer show_debug_level (integer new_one);


	//nominally the enum info_type, but left as int for expansion
	//The first way to not print some bit of meta data.
      extern  virtual function /*previous*/ bit message_display (integer id, bit new_value);
	 extern protected function void put_line_ (integer id, string value, string msg, integer level);



	local string functional_area_;
	local integer show_debug_level_;
	local bit message_display_[*];
endclass // vout

   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void message_list::put_message (integer id, string value);
`ifdef ncsim
   message m;
  m = new ();
`else
   message m = new ();
`endif
   m.id = id;
   m.value = value;
   the_list_.push_back (m);
endfunction


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function string message_list::convert_to_string (output bit fatal_seen);
   string returned;
//   $display ("convert to string");
   for (integer i = 0; i < the_list_.size(); ++i) begin
//      $display ($psprintf ("Covert adding %s . Total is %s", the_list_[i].value, returned));
      returned = {returned, the_list_[i].value};
//	 $display ($psprintf ("Covert after adding %s . Line is %s", the_list_[i].value, returned));
    if (the_list_[i].id == vout_fatal) fatal_seen = 1;
   end
   return (returned);
endfunction

parameter integer string_npos = -1;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function integer str_find (string s1, string key);
//   $display ("str_find: look for key \"%s\" in \"%s\"", key, s1);
   if (s1 == key) return 0;

   for (integer i = 0; i < (s1.len () - key.len()); ++i) begin
      integer j;
      j = 0;
      for (int questa = 0; j <key.len (); ++j) begin
	// $display ("Compare %c (%0d) with %c (%0d)", s1.getc (i + j), i + j, key.getc (j), j);

	 if (s1.getc (i + j) != key.getc (j))begin
	    break;
	 end

      end
      if ((i != (s1.len () - key.len())) && (j == key.len ())) begin
	 //$display ("teal_vout_pre.sv, str_find returning found \"%s\" in \"%s\" at index %0d",  key, s1, i);
	 return i;
      end
   end
   return string_npos;
endfunction // str_find

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function vlog::new ();
   fatal_message_seen_ = 0;
   after_me_ = the_;
   the_ = this;
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class local_vlog extends vlog;
   protected virtual function string local_print_ (string val);
//      $display ("will print \"%s\"", val, 0, 0,0);  //don't ask
      $display (val);
      if ((fatal_message_seen_) && (str_find (val, "FATAL") != 0)) begin
	 $finish (); //not good enough ???
      end
      fatal_message_seen_ = 0;
      return val;
   endfunction // string

   protected virtual function automatic message_list output_message_ (message_list m);
`ifdef ncsim
      string val;
      vlog v;

     val = m.convert_to_string (fatal_message_seen_);
      v = vlog_get ();
`else
      string val = m.convert_to_string (fatal_message_seen_);
      vlog v = vlog_get ();
`endif
//   $display ("after convert: will print \"%s\"", val, 0, 0,0);  //don't ask
      for (integer i = 0; i < m.the_list_.size(); ++i) begin
	 id_count_[m.the_list_[i].id]++;
      end

      v.local_print (val);
     return m;
   endfunction
endclass

     //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   function vlog vlog_get ();
      static local_vlog lv;
      if (lv == null) lv = new ();
      return (lv.get ());
   endfunction

   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function vout::new (string functional_area, integer initial_show_level);
  functional_area_ = functional_area;
  show_debug_level_ = dictionary_find_integer ({functional_area, "_show_debug_level"}, initial_show_level);
//   show_debug_level_ = 1;

   for (integer i = vout_first_id; (i < vout_last_id); ++i) begin
    message_display_ [i] = 1;
  end
endfunction // vout

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   function void vlog::output_message (message_list msg);
`ifdef ncsim
      message_list msg2;
      msg2 = output_message_ (msg);
`else
      message_list msg2 = output_message_ (msg);
`endif
      if (after_me_ != null) after_me_.output_message (msg2);
    endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   function void  vlog::local_print (string val);
`ifdef ncsim
      string val2;
      val2 = local_print_ (val);
`else
      string val2 = local_print_ (val);
`endif
//      $display ("after local local_print_ after_me %0d will print \"%s\"", (after_me_ != null), val2, 0, 0,0);  //don't ask
      if ((after_me_ != null) && (val2 != "")) after_me_.local_print (val2);
    endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function string vout::name ();
  return (functional_area_);
endfunction // vout

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function /*previous*/ bit vout::message_display (integer id, bit new_value);
`ifdef ncsim
   bit returned;
   returned = message_display_[id];
`else
   bit returned = message_display_[id];
`endif
   message_display_[id] = new_value;
   return returned;
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void vout::info (string msg);
   put_line_ (vout_info, "[INFO]", msg, 0);
endfunction // vout

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void vout::error (string msg);
   put_line_ (vout_error, "[ERROR]", msg, 0);
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void vout::fatal (string msg);
   put_line_ (vout_fatal, "[FATAL]", msg, 0);
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void vout::debug (string msg);
   put_line_ (vout_debug, "[DEBUG]", msg, 1);
endfunction // vout

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void vout::debug_n (integer level, string msg);
   put_line_ (vout_debug, "[DEBUG]", msg, level);
endfunction // vout

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void vout::put_line_ (integer id, string value, string msg, integer level);
   string t;
`ifdef ncsim
   message_list a_message_list;
   a_message_list = new ();
`else
   message_list a_message_list = new ();
`endif

//   $display ("put line %d %s %s", id, value, msg);

    $sformat (t, "[%0t]", $time);

   if (message_display_[vout_time]) a_message_list.put_message (vout_time, t);
   if (message_display_[vout_info]) a_message_list.put_message (id, value);
   if (message_display_[vout_functional_area])
     a_message_list.put_message (vout_functional_area, {"[", functional_area_ ,"]"});
//  put_message (vout_thread_name, "[" + thread_name (pthread_self()) + "]");
   if (message_display_[vout_message_data])
     a_message_list.put_message (vout_message_data, msg);
   begin
`ifdef ncsim
      vlog one;
      one = vlog_get();
`else
      vlog one = vlog_get();
`endif
// $display ($psprintf ("current %d show %d", level , show_debug_level_));
      if (level <= show_debug_level_) one.output_message (a_message_list);
   end
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function integer vout::show_debug_level (integer new_one);
`ifdef ncsim
    integer returned;
    returned = show_debug_level_; show_debug_level_ = new_one; return (returned); endfunction
`else
    integer returned = show_debug_level_; show_debug_level_ = new_one; return (returned); endfunction
`endif


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function string file_vlog::local_print_ (string val);
   $fwrite (out_file_, "%s\n", val);
//      $display ("file vout: after local local_print_ after_me %0d to_screen %0d will print \"%s\"", (after_me_ != null), also_to_screen_, val, 0, 0,0);  //don't ask

  if (also_to_screen_) return val; else return "";
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function vlog vlog::get ();
   return (the_);
endfunction // vlog

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function file_vlog::new (string file_name, bit also_to_screen);
   super.new ();
   out_file_ = $fopen (file_name, "w");
   if (out_file_ == 0) $display ({"Unable to open file: ", file_name});
   $display ({"opened file: ", file_name});
   also_to_screen_ = also_to_screen;
endfunction


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function integer vlog::how_many (integer an_id); //given a meta-info tag, how many got printed?
   return  id_count_[an_id];
endfunction // vlog

   ////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///////////////// Dictionary /////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

class dictionary_impl;
   extern function string find_on_command_line (string name, string default_name);
   extern task read (string path);
   extern task clear ();
   extern function bit put (string name, string value, input bit replace_existing = 1);
   extern function string find (string name); 
   extern function integer find_integer (string name, integer default_value);
   local string lines_[string];
      local vout log_;
      extern function new ();
    extern local task process_file_ (string path);
       extern local function string teal_scan_plusargs (string name);
 endclass // dictionary_impl


   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   function automatic dictionary_impl dictionary_get ();
      static dictionary_impl lv;  //singleton
      if (lv == null) lv = new ();
      return (lv);
   endfunction


//only seaches command line args. Useful to get a file name to start dictionary with.
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function string dictionary_find_on_command_line (string name, string default_name);
`ifdef ncsim
  dictionary_impl impl;
  impl = dictionary_get ();
`else
  dictionary_impl impl = dictionary_get ();
`endif
  return (impl.find_on_command_line (name, default_name));
endfunction

   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task dictionary_read (string path);
`ifdef ncsim
  dictionary_impl impl;
  impl = dictionary_get ();
`else
  dictionary_impl impl = dictionary_get ();
`endif

   impl.read (path);
endtask

   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//removes all entries
task dictionary_clear ();
`ifdef ncsim
  dictionary_impl impl;
  impl = dictionary_get ();
`else
  dictionary_impl impl = dictionary_get ();
`endif

   impl.clear ();
endtask
      

parameter bit replace_entry = 1;
parameter bit default_only = 0;

//returns 1 if placed or overwritten
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function bit dictionary_put (string name, string value, input bit replace_existing = 1);
`ifdef ncsim
  dictionary_impl impl;
  impl = dictionary_get ();
`else
  dictionary_impl impl = dictionary_get ();
`endif
   return (impl.put (name, value, replace_existing));
endfunction // bit
      

   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function string dictionary_find (string name);  //returns "" if not found in constraints or command line
`ifdef ncsim
  dictionary_impl impl;
  impl = dictionary_get ();
`else
  dictionary_impl impl = dictionary_get ();
`endif
   return (impl.find (name));
endfunction   
      

//sets to default if not found
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function automatic integer dictionary_find_integer (string name, integer default_value);
`ifdef ncsim
  dictionary_impl impl;
  impl = dictionary_get ();
`else
  dictionary_impl impl = dictionary_get ();
`endif
   return (impl.find_integer (name, default_value));
endfunction   
   
   function dictionary_impl::new ();
   //ARRGH because of no statics dictionary cannot have a logger!
   //This is to allow the logger to use the dictionary to see what level the user wants to debug at
   //This log feature is far more important than logger in the dictionary implementtaion class
//   log_ = new ("Dictionary");

endfunction // dictionary_impl

function string dictionary_impl::teal_scan_plusargs (string name);
   string returned;
`ifdef ncsim
   bit found;
   found  = $value$plusargs ({name, "+%s"},returned);
`else
   bit found = $value$plusargs ({name, "+%s"},returned);
`endif
//   $display ("plus args search for %s found %s", name, returned);

  if (found) return returned; else return "";
endfunction 


function string dictionary_impl::find_on_command_line ( string name,  string default_name);
`ifdef ncsim
  string arg;
  arg = teal_scan_plusargs (name);
`else
  string arg = teal_scan_plusargs (name);
`endif
  return (arg != "") ? arg : default_name;
endfunction



task dictionary_impl::process_file_ (string path);
`ifdef ncsim
    integer file_id;
   file_id = $fopen (path, "r");
`else
    integer file_id = $fopen (path, "r");
`endif
//   log_.debug ({"Process file: ", path});
$display ({"Process file: ", path});
//   if (file_id == 0) log_.error ({"unable to open file ", path}); return; end
   if (file_id == 0) begin $display ({"unable to open file ", path});    return; end  //non error now ;-(
   while (! $feof (file_id)) 
     begin
	//get frst word
	string param ;
	byte c;
	string value;
	integer unused;

	unused = $fscanf (file_id, "%s", param);
	if (param.len ()) begin
`ifndef ATHDL_SIM
	   c = $fgetc (file_id);  //eat the space between symbol and value
`endif
	   unused = $fgets (value, file_id);
	   value = value.substr (0, value.len() - 2);
	end
	
//	$display ($psprintf ("got \"%s\" and \"%s\" ", param, value));

	if (param == "#include") begin
	   process_file_ (value);
	end
	else begin
	   lines_[param] = value;
//	      $display ("lines22[%s] is \"%s\"", param, lines_[param]);
	end
     end // while (! feof (file_id))
//      log_.debug ({"Completed process file: ", path});
   $display ({"Completed process file: ", path});
endtask

task dictionary_impl::read ( string path);
   process_file_ (path);
endtask


task dictionary_impl::clear ();
   lines_.delete ();
endtask

function bit dictionary_impl::put ( string name,  string value, input bit replace_existing);
`ifdef ncsim
  bit returned;
  returned = (find (name) != "");
`else
  bit returned = (find (name) != "");
`endif
  if ( (! returned) || (replace_existing)) begin
    lines_[name] = value;
  end
  return returned;
endfunction

function string dictionary_impl::find ( string name); 
`ifdef ncsim
  string arg;
  arg = teal_scan_plusargs (name);
`else
  string arg = teal_scan_plusargs (name);
`endif
//   $display ("%t lines \"%s\" is \"%s\" command line is \"%s\"", $time, name, lines_[name], arg);
   
  return (arg != "") ? arg : lines_[name];
endfunction

function integer dictionary_impl::find_integer ( string name, integer default_value);
`ifdef ncsim
   string value;
   integer returned;
   integer scan_count;

   value = find (name);
   scan_count = 0;
`else
   string value = find (name);
   integer returned;
   integer scan_count = 0;
`endif
   if (name != "") begin
      scan_count = $sscanf (value, "%d", returned);
   end
//   $display ("%t lines \"%s\" is \"%s\" ret is %0d", $time, name, lines_[name],  (scan_count == 1) ? returned : default_value);   
   return (scan_count == 1) ? returned : default_value;
endfunction

   

   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class vrandom;
   extern function new  ();  //no overloaded new, no static methods, so two phase it is!
      
    extern function void set (string file, bit[31:0] line);
    extern function bit[47:0] draw ();

   extern task init_with_file (string master_seed_path);
   extern task init_with_seed (bit [63:0] m);
       
       local bit[15:0] _rand48_seed[3];  //keep variable names consistent with the original
      local bit[15:0] _rand48_mult[3];
      local bit[63:0] _rand48_add;
    local bit[15:0] seed__[3];
     
      
      
    static bit[15:0] master_seed_[3];
   endclass // vrandom


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   task vrandom_init_with_file (string master_seed_path);
`ifdef ncsim
      vrandom hack;
      hack = new ();
`else
      vrandom hack = new ();
`endif
      hack.init_with_file (master_seed_path);
   endtask

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   task vrandom_init_with_seed (bit [63:0]  master_seed);
`ifdef ncsim
      vrandom hack;
      hack = new ();
`else
      vrandom hack = new ();
`endif
      hack.init_with_seed (master_seed);
   endtask // init_with_seed



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //NOTE: The min,max values are not put in the ctor to allow different ranges after the 
  //object is created. This is important to allow one range,random to affect another.
class random_range_8 extends  vrandom;
   extern function new  (string file_name, bit[31:0] line);
   extern function bit[7:0] draw_val ();
endclass // random_range

class random_range_32 extends  vrandom;
   extern function new  (string file_name, bit[31:0] line);
   extern function bit[31:0] draw_val ();
endclass // random_range

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //NOTE: The min,max values are not put in the ctor to allow different ranges after the 
  //object is created. This is important to allow one range,random to affect another.
class random_range extends  random_range_32;
   extern function new  (string file_name, bit[31:0] line);
   extern function bit[31:0]draw_val2 (bit[31:0] low, bit[31:0] up); //any order
endclass 
     

`ifdef ncsim
`define RAND_8(x) begin teal::random_range_8 r; r = new ("x",11); x = r.draw_val (); end
`define RAND_32(x) begin teal::random_range_32 r; r = new ("x", 3); x = r.draw_val (); end
`define RAND_RANGE(x,y,z) begin teal::random_range r; r = new ({"x", "y", "z"}, 11); x = r.draw_val2 (y,z); end
`else
`define RAND_8(x) begin static teal::random_range_8 r = new ("x",11); x = r.draw_val (); end
`define RAND_32(x) begin static teal::random_range_32 r = new ("x", 3); x = r.draw_val (); end
`define RAND_RANGE(x,y,z) begin static teal::random_range r = new ({"x", "y", "z"}, 11); x = r.draw_val2 (y,z); end
`endif
`define RAND48_SEED_0   63'h330e
`define RAND48_SEED_1   63'habcd
`define RAND48_SEED_2   63'h1234
`define RAND48_MULT_0   63'he66d
`define RAND48_MULT_1   63'hdeec
`define RAND48_MULT_2   63'h0005
`define RAND48_ADD      63'h000b

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function vrandom::new  ();
//constants in the cpp impl 
   _rand48_seed[0] = `RAND48_SEED_0;
   _rand48_seed[1] = `RAND48_SEED_1;
   _rand48_seed[2] = `RAND48_SEED_2;
   
   _rand48_mult[0] = `RAND48_MULT_0;
   _rand48_mult[1] = `RAND48_MULT_1;
   _rand48_mult[2] = `RAND48_MULT_2;
   _rand48_add = `RAND48_ADD;
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void vrandom::set  (string file, bit[31:0] line);
  seed__[0] = master_seed_[0];
  seed__[1] = master_seed_[1];
  seed__[2] = master_seed_[2];
  
  //first, fold in the string part
  for (int i = 0; i < file.len (); ++i) begin
    //CONSIDER: some ascii function like ! is_printable ()
//    if (! isalnum (file[i])) continue;  //skip the non-meat
    seed__[i % 3] = seed__[i % 3] ^ file.getc (i);
  end
  //now the integer part. Seperate close integers by mult with a big prime
  line *= 1103515245;
  seed__[0] = seed__[0] ^ (line & 'hff);
  seed__[1] = seed__[1] ^ ((line >> 8) & 'hff); 
  seed__[2] = seed__[2] ^ (line >> 16);

   `ifdef learn_how_to_get_thread_name
  //now the thread name so that same instances in multiple threads are unique
  string t = teal::thread_name (pthread_self ());
  for (int j= 0; j < t.len (); ++j) begin
    if (! isalnum (t[j])) continue;  //skip the non-meat
    seed__[j % 3] ^= t[j];
  end
   `endif
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function bit[47:0] vrandom::draw ();
   bit[63:0] accu;
   bit [15:0] temp[2];
   accu = _rand48_mult[0] * seed__[0] +  _rand48_add;
   temp[0] = accu[15:0];        /* lower 16 bits */
   accu >>= 16;
   accu += (_rand48_mult[0] * seed__[1]) +  (_rand48_mult[1] * seed__[0]);
   temp[1] = accu [15:0];        /* middle 16 bits */
   accu >>= 16;
   accu += (_rand48_mult[0] * seed__[2]) + (_rand48_mult[1] * seed__[1]) + 
	   (_rand48_mult[2] * seed__[0]);
   seed__[0] = temp[0];
   seed__[1] = temp[1];
   seed__[2] = accu[15:0];
  // $display ("%m draw returned %0d", {seed__[2], seed__[1], seed__[0]});
   return {seed__[2], seed__[1], seed__[0]};
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function bit[31:0] random_range::draw_val2 (bit[31:0] low, bit[31:0] up);
  if (low == up) return low;
begin
`ifdef ncsim
  bit[31:0] lower;
  bit[31:0] upper;
   bit [31:0] delta;
   bit[47:0] value;
   bit [31:0] returned;

   lower=  ((low < up) ? low : up);
   upper = ((low < up) ? up : low);
   delta = (up - low + 1);
   returned = (value % (delta)) + lower;
   value = draw ();
`else
  bit[31:0] lower=  ((low < up) ? low : up);
  bit[31:0] upper = ((low < up) ? up : low);
  bit[31:0] delta = (up - low + 1);
   bit [47:0] value = draw ();
   bit [31:0] returned = (value % (delta)) + lower;
`endif
// $display ("%m returning %0d", returned);
   return returned;
end
   
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function random_range::new (string file_name, bit[31:0] line);
   super.new (file_name, line);
endfunction




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task vrandom::init_with_file (string master_seed_path);
`ifdef ncsim
   integer    file_id;
   bit 	      found;
file_id = $fopen (master_seed_path, "r");
found = 0;
`else
      integer   file_id = $fopen (master_seed_path, "r");
   bit 	     found = 0;
`endif
   if (file_id) begin //cannot rely on short circuit &&
      while ((!found) && (! $feof(file_id))) begin
	 integer unused;
	 string dummy; 

	 unused = $fscanf (file_id, "%s", dummy);
	 if (dummy == "master_seed") begin
	    found = 1;
	    unused = $fscanf (file_id, "%d %d %d", master_seed_[0], master_seed_[1], master_seed_[2]);
//	    $display ("found master_seed: %0d %0d %0d", master_seed_[0], master_seed_[1], master_seed_[2]);	
	 end
      end
      $fclose (file_id);
   end // if (file_id)
   
   if (! found) begin //write it there, so next run will find it
      //     integer foo = $time();
      //     $ramdom (foo);
`ifdef ncsim
      integer foo;
      master_seed_[0] = $urandom (foo); master_seed_[1] = $urandom (foo); master_seed_[2] = $urandom (foo);
`else
      master_seed_[0] = $urandom (); master_seed_[1] = $urandom (); master_seed_[2] = $urandom ();
`endif      
      begin
`ifdef ncsim
	 integer file_id;
	 string msg;
	 integer dummy;
	 file_id = $fopen (master_seed_path, "w+");
	 dummy = $ferror (file_id, msg);
`else
	 integer file_id = $fopen (master_seed_path, "w+");
	 string msg;
	 integer dummy = $ferror (file_id, msg);
`endif
	 if (! file_id) begin
	    $display ("%t %m %s", $time, msg);
	    $finish (04101962);
	 end
	 
	 $fwrite (file_id, "%0d %0d %0d", master_seed_[0], master_seed_[1], master_seed_[2]);
	 $fclose (file_id);
      end
   end
endtask

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task vrandom::init_with_seed (bit[63:0] m);
  m *=  1103515245; //generate big difference from close to same seed
  master_seed_[0] = m;
  master_seed_[1] = (m >> 8); 
  master_seed_[2] = (m >> 16);

  master_seed_[0] ^= (m >> 24);
  master_seed_[1] ^= (m >> 32); 
  master_seed_[2] ^= (m >> 40);

  master_seed_[0] ^= (m >> 48);
  master_seed_[1] ^= (m >> 56); 
endtask


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function random_range_8::new  (string file_name, bit[31:0] line);
   super.new ();
   set (file_name, line);
endfunction // random_range_8


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function bit[7:0] random_range_8::draw_val ();
   bit [47:0] value;
   bit [7:0]  returned;
   value = draw ();
`ifdef kjljjjkljkljl
   returned[0] = ^{value[0], value[8],  value[16], value[24], value[32], value[40]};
   returned[1] = ^{value[1], value[9],  value[17], value[25], value[33], value[41]};
   returned[2] = ^{value[2], value[10], value[18], value[26], value[34], value[42]};
   returned[3] = ^{value[3], value[11], value[19], value[27], value[35], value[43]};
   returned[4] = ^{value[4], value[12], value[20], value[28], value[36], value[44]};
   returned[5] = ^{value[5], value[13], value[21], value[29], value[37], value[45]};
   returned[6] = ^{value[6], value[14], value[22], value[30], value[38], value[46]};
   returned[7] = ^{value[7], value[15], value[23], value[31], value[39], value[47]};
`else
   returned = value;
`endif // !`ifdef kjljjjkljkljl
   
   return returned;
endfunction // bit



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function random_range_32::new  (string file_name, bit[31:0] line);
   super.new ();
   set (file_name, line);
endfunction // random_range_8


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function bit[31:0] random_range_32::draw_val ();
   bit [47:0] value;
   bit [31:0] returned;
   
   value = draw ();
`ifdef kl
   
//now distribute the 48-32 16 bits
   returned[0] ^= value[32];
   returned[2] ^= value[33];
   returned[4] ^= value[34];
   returned[6] ^= value[35];
   returned[8] ^= value[36];
   returned[10] ^= value[37];
   returned[12] ^= value[38];
   returned[14] ^= value[39];
   returned[16] ^= value[40];
   returned[18] ^= value[41];
   returned[20] ^= value[42];
   returned[22] ^= value[43];
   returned[24] ^= value[44];
   returned[26] ^= value[45];
   returned[28] ^= value[46];
   returned[30] ^= value[47];
`else // !`ifdef kl
   returned = value;
`endif
   return returned;
endfunction // bit

   
   parameter int MAX_DATA = 1024;

virtual class memory_bank;
   extern function new  (string path);

      //the two methods are pure virtual, you must implement them
`ifdef ncsim
 virtual task from_memory (bit [63:0] address, output bit [MAX_DATA - 1:0] value, input int size); endtask
 virtual task to_memory (bit [63:0] address, bit [MAX_DATA - 1:0]  value, int size); endtask
`else
 `PURE virtual task from_memory (bit [63:0] address, output bit [MAX_DATA - 1:0] value, input int size); 
 `PURE virtual task to_memory (bit [63:0] address, bit [MAX_DATA - 1:0]  value, int size); 
`endif
   extern function bit contains1 (string path);
   extern function integer contains2 (bit [63:0] address);
   extern function string stats ();
   extern function void locate (bit [63:0] first_address, bit [63:0] last_address);
      
   local bit [63:0] first_address_;
   local bit [63:0] last_address_;
   protected vout log_;
endclass


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//internal singleton
class memory_impl;
   extern function void add_map (string path, bit [63:0] first_address, bit [63:0] last_address);
   extern task read (bit [63:0] global_address, output bit [MAX_DATA - 1:0] value, input int size = MAX_DATA);
   extern task write (bit [63:0] global_address, input bit [MAX_DATA - 1:0] value, int size = MAX_DATA);
   extern function void add_memory_bank (/*owner*/ memory_bank bank);
   extern function /*cached*/ memory_bank lookup1 (bit [63:0] address_in_range);
   extern function /*cached*/ memory_bank lookup2 (string partial_path);

   local memory_bank memory_banks_[$];
   local vout log_;
   function new (); log_ = new ("teal::memory_implmentation"); endfunction
endclass 


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function memory_impl memory_get ();
   static memory_impl lv;// = new ();  //singleton
   if (lv == null) lv = new ();
   return (lv);
endfunction


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//The "normal" way to access memory...

//setup a mapping between some global address space and some memory
function void  add_map (string path, bit [63:0] first_address, bit [63:0] last_address);
`ifdef ncsim
   memory_impl impl;
   impl = memory_get ();
`else
   memory_impl impl = memory_get ();
`endif
   impl.add_map (path, first_address, last_address);
endfunction


//now access it...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task read (bit [63:0] global_address, output bit [MAX_DATA - 1:0] value, input int size = MAX_DATA);
`ifdef ncsim
   memory_impl impl;
   impl = memory_get ();
`else
   memory_impl impl = memory_get ();
`endif

   impl.read (global_address, value, size);
endtask // teal_add_map

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task write (bit [63:0] global_address, input bit [MAX_DATA - 1:0] value, int size = MAX_DATA);
`ifdef ncsim
   memory_impl impl;
   impl = memory_get ();
`else
   memory_impl impl = memory_get ();
`endif

   impl.write (global_address, value, size);
endtask // teal_add_map

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void add_memory_bank (/*owner*/ memory_bank bank);
`ifdef ncsim
   memory_impl impl;
   impl = memory_get ();
`else
   memory_impl impl = memory_get ();
`endif

   impl.add_memory_bank (bank);
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function /*cached*/ memory_bank memory_lookup1 (bit [63:0] address_in_range);
`ifdef ncsim
   memory_impl impl;
   impl = memory_get ();
`else
   memory_impl impl = memory_get ();
`endif

   return (impl.lookup1 (address_in_range));
endfunction

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function /*cached*/ memory_bank memory_lookup2 (string partial_path);
`ifdef ncsim
   memory_impl impl;
   impl = memory_get ();
`else
   memory_impl impl = memory_get ();
`endif

   return (impl.lookup2 (partial_path));
endfunction
   
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function memory_bank::new  (string path);
   log_ = new (path);
endfunction // new

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function bit memory_bank::contains1 (string path);
   return ((str_find (log_.name (), path) == string_npos) ? 0 : 1);
endfunction

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function integer memory_bank::contains2 (bit [63:0] address);
   return ((address >= first_address_) && (address <= last_address_) ? (address - first_address_) : -1);
endfunction

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void memory_bank::locate (bit [63:0] first_address, bit [63:0] last_address);
   first_address_ = first_address;
   last_address_ = last_address;
//   log_.info ($psprintf ("Locate [0x%0x to 0x%0x]", first_address, last_address));
endfunction


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function string memory_bank::stats ();
   return $psprintf ("name: \"%s\" [0x%x, 0x%x]", log_.name (), first_address_, last_address_);
endfunction 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void memory_impl::add_map (string path, bit [63:0] first_address, bit [63:0] last_address);
   int found_index;
  found_index = -1;
   for (int i = 0; i < memory_banks_.size (); ++i) begin
      if (memory_banks_[i].contains1 (path)) begin
	 if (found_index == -1) begin
	    found_index = i;
	 end
	 else begin
	    log_.error ( $psprintf ("teal::add_map() Found two banks that match path \"%s\"  %s and %s",
			      path, memory_banks_[i].stats (), memory_banks_[found_index].stats ()));
	 end
      end
   end // for (int i = 0; i < memory_banks_.size (); ++i)
   
   if (found_index == -1) begin
      log_.error ($psprintf ("teal::add_map() Found no banks (of %0d)  that match path \"%s\"", memory_banks_.size (), path));      
   end
   else memory_banks_[found_index].locate (first_address, last_address);
endfunction

   
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task memory_impl::read (bit [63:0] global_address, output bit [MAX_DATA - 1:0] value, input int size);
`ifdef ncsim
   bit found;
   int found_index;
   found = 0;
   found_index = -1;
`else
   bit found = 0;
   int found_index = -1;
`endif
   for (int i = 0; i < memory_banks_.size (); ++i) begin
`ifdef ncsim
      integer offset;
      offset = memory_banks_[i].contains2 (global_address);
`else
      integer offset = memory_banks_[i].contains2 (global_address);
`endif
      if (offset != -1) begin
	 if (found) begin
	    log_.error ($psprintf ("Found two banks that contain address 0x%x. %s and %s",
			      global_address, memory_banks_[i].stats (), memory_banks_[found_index].stats ()));
	 end
	 else begin
	    found = 1;
	    found_index = i;
	    memory_banks_[i].from_memory (offset, value, size);
	 end
      end
   end
   if (!found) begin
      log_.error ($psprintf ("Unable to read from address 0x%x", global_address));
   end
endtask // read

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
task memory_impl::write (bit [63:0] global_address,  input bit [MAX_DATA - 1:0] value, int size);
`ifdef ncsim
   bit found;
   int found_index;
   found = 0;
   found_index = -1;
`else
   bit found = 0;
   int found_index = -1;
`endif
   for (int i = 0; i < memory_banks_.size (); ++i) begin
`ifdef ncsim
      integer offset;
      offset = memory_banks_[i].contains2 (global_address);
`else
      integer offset = memory_banks_[i].contains2 (global_address);
`endif
      if (offset != -1) begin
	 if (found) begin
	    log_.error ($psprintf ("Found two banks that contain address 0x%x. %s and %s",
			      global_address, memory_banks_[i].stats (), memory_banks_[found_index].stats ()));
	 end
	 else begin
	    found = 1;
	    found_index = i;
	    memory_banks_[i].to_memory (offset, value, size);
	 end
      end
   end
   if (!found) begin
      log_.error ($psprintf ("Unable to write to address 0x%x", global_address));
   end
endtask 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function void memory_impl::add_memory_bank (/*owner*/ memory_bank bank);
   memory_banks_.push_back (bank);   
endfunction

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function /*cached*/ memory_bank memory_impl::lookup1 (bit [63:0] address_in_range);
`ifdef ncsim
   bit found;
   int found_index;
   memory_bank returned;

   found = 0;
   found_index = -1;
   returned = null;
`else
   bit found = 0;
   int found_index = -1;
   memory_bank returned = null;
`endif

   
   for (int i = 0; i < memory_banks_.size (); ++i) begin
`ifdef ncsim
      integer offset;
     offset = memory_banks_[i].contains2 (address_in_range);
`else
      integer offset = memory_banks_[i].contains2 (address_in_range);
`endif
      if (offset != -1) begin
	 if (found) begin
	    log_.error ($psprintf ("Found two banks that contain address 0x%x. %s and %s",
			      address_in_range, memory_banks_[i].stats (), memory_banks_[found_index].stats ()));
	 end
	 else begin
	    found = 1;
	    found_index = i;
	    returned = memory_banks_[i];
	 end
      end
   end
   if (!found) begin
      log_.error ($psprintf ("Unable to find memory bank which contains address 0x%x", address_in_range));
   end
   return returned;
endfunction

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function /*cached*/ memory_bank memory_impl::lookup2 (string partial_path);
`ifdef ncsim
   bit found;
   int found_index;
   memory_bank returned;

   found = 0;
   found_index = -1;
   returned = null;
`else
   bit found = 0;
   int found_index = -1;
   memory_bank returned = null;
`endif
   
   for (int i = 0; i < memory_banks_.size (); ++i) begin
      if (memory_banks_[i].contains1 (partial_path)) begin
	 if (found) begin
	    string msg;
	    log_.error ($psprintf ("Found two banks that contain partial path \"%s\". %s and %s",
			      partial_path, memory_banks_[i].stats (), memory_banks_[found_index].stats ()));
	 end
	 else begin
	    found = 1;
	    found_index = i;
	    returned = memory_banks_[i];
	 end
      end
   end
   if (!found) begin
      log_.error ($psprintf ("Unable to find memory bank which contains string \"%s\"", partial_path));
   end
   return returned;
endfunction

   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class latch;
   local bit set_;
   local bit reset_value_;
   local event event_;
   local vout log_;

   function new (string name, bit reset_on_wait);
      log_ = new (name);
      set_ = 0;
      reset_value_ = !reset_on_wait;
   endfunction // new

   task signal ();
      set_ = 1;
      ->event_;
   endtask

   task clear ();
      set_ = 0;
   endtask

   function bit is_signaled (); return set_; endfunction

   task pause ();
//      $display ("pause reset val is %0d set value is %0d", reset_value_, set_);
      
      if (set_) begin
	 set_ = reset_value_;
	 return;
      end
//      wait (event_.triggered);  //will report again if we reset and wait at the same time.
      @(event_);  
      
      set_ = reset_value_;
   endtask // wait_for_set

   task reset_on_wait (bit r);
      reset_value_ = !r;
   endtask

endclass 

`ifndef aldec
  endpackage
`endif

`ifdef ncsim
import teal::*;
`endif

`endif
