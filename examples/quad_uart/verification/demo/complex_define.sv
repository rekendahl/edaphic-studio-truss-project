`ifndef __ANA_COV_SV
`define __ANA_COV_SV

`define bin_vi(a,b) \
           bins R_``a_``b = {[a*cfg.max_voltage.i/16:b*cfg.max_voltage.i/16-1]}

class ana_cov extends uvm_component;
  `uvm_component_utils(ana_cov);

  int vin_i;
  ana_cfg cfg;

  covergroup cg_vin;
    cp_vi: coverpoint vin_i {
           `bin_vi(0,1);
           `bin_vi(1,2);
           `bin_vi(2,3);
           `bin_vi(3,4);
           `bin_vi(4,5);
           `bin_vi(5,6);
           `bin_vi(6,7);
           `bin_vi(7,8);
           `bin_vi(8,9);
           `bin_vi(9,10);
           `bin_vi(10,11);
           `bin_vi(11,12);
           `bin_vi(12,13);
           `bin_vi(13,14);
           `bin_vi(14,15);
           `bin_vi(15,16);
    }
    cp_vmax: coverpoint cfg.max_voltage.i {
        bins VMIN = {[1600:1749]};
        bins VNOM = {[1750:1850]};
        bins VMAX = {[1851:2000]};
    }
    cc: cross cp_vmax, cp_vi;
  endgroup

  function new(string name = "ana cov", uvm_component parent = null);
    super.new(name, parent);
    if(!uvm_resource_db#(ana_cfg)::read_by_name(get_full_name(), "ana_cfg", cfg))
      `uvm_error("TESTERROR", $sformatf("%s %s", "no valid configuratiuon available at path=", get_full_name()));
    this.cfg = cfg;
    cg_vin = new();
  endfunction

  function void cover_vals(sv_ams_real v);
    vin_i = v.i;
    cg_vin.sample();
  endfunction

endclass
`endif
