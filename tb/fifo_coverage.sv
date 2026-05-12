class fifo_coverage;
    virtual fifo_if vif;


    // 1. WRITE DOMAIN COVERAGE

    covergroup wr_cg @(posedge vif.wr_clk);
        cp_full: coverpoint vif.full {
            bins not_full = {0};
            bins full     = {1};
        }
        
        cp_wr_toggle: coverpoint vif.wr_en {
            bins single_write = (0 => 1 => 0);
            bins back_to_back = (0 => 1 [* 2:10] => 0); 
        }
        
        // Track the Burst-into-Wall natively
        cp_wr_en: coverpoint vif.wr_en;
        cx_burst_into_full: cross cp_wr_en, cp_full;
    endgroup

    // 2. READ DOMAIN COVERAGE

    covergroup rd_cg @(posedge vif.rd_clk);
        cp_empty: coverpoint vif.empty {
            bins not_empty = {0};
            bins empty     = {1};
        }
        
        cp_rd_toggle: coverpoint vif.rd_en {
            bins single_read  = (0 => 1 => 0);
            bins back_to_back = (0 => 1 [* 2:10] => 0); 
        }

        // Track the Drain-into-Wall natively
        cp_rd_en: coverpoint vif.rd_en;
        cx_drain_to_empty: cross cp_rd_en, cp_empty;
    endgroup

    function new(virtual fifo_if vif);
        this.vif = vif;
        wr_cg    = new();
        rd_cg    = new();
    endfunction

    function void report();
        $display("========================================");
        $display("=== ADVANCED COVERAGE METRICS        ===");
        $display("Write Domain (Full, Bursts, Cross) : %.1f%%", wr_cg.get_coverage());
        $display("Read Domain (Empty, Bursts, Cross) : %.1f%%", rd_cg.get_coverage());
        $display("========================================");
    endfunction
endclass