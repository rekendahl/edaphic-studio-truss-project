 function void atm_cell::save(int file);
    bit [7:0] bytes[];
    int   i;

    foreach (bytes[i])
       $fwrite(file, "%x", bytes[i]);
    $fwrite(file, "%0d\n", i);
endfunction