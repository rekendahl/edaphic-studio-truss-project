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
/*Copyright (C) 2006 Mike Mintz and Robert Holy-Ekendahl

This file is part of the Trusster IP Library. 

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
*/

`ifndef __uart_generator__
`define __uart_generator__

`include "teal.svh"
`include "uart_bfm_agent.svh"

typedef class uart_configuration;
   
//The following dictionary control knows are used. All the prefixed with the name of the generator.
//_min_word_delay, _max_word_delay

virtual class uart_generator;
   extern function new (string n, uart_configuration c);

    //send one block of words to the uart bfm, delay the block by delay
    //not that the individual words and word delay are controlled by dictionary knobs.
    extern task send_block (teal::uint32 num_words, teal::uint32 block_delay);

    string name;

    `PURE protected virtual task send_block_ (uart_block the_block);
    protected teal::vout log_;

    local teal::uint8 word_size_;

    local teal::uint32 min_bit_delay_;
    local teal::uint32 max_bit_delay_;
    local rand teal::uint32 bit_delay_;
    constraint bit_delay_valid { bit_delay_ >= min_bit_delay_; bit_delay_ <= max_bit_delay_;}

    protected uart_configuration configuration_;
endclass
`endif
