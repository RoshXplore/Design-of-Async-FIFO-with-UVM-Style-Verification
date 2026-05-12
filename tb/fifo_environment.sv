class fifo_env;

    async_fifo_write_driver  wr_drv;
    fifo_read_driver         rd_drv;
    fifo_write_monitor       wr_mon;
    fifo_read_monitor        rd_mon;
    fifo_ref_model           rm;
    fifo_scoreboard          sb;
    fifo_generator           gen;

    fifo_coverage            cov;

    // Mailboxes
    mailbox #(fifo_transaction) wr_mbox;
    mailbox #(fifo_transaction) rd_mbox;
    mailbox #(bit)              wr_done_mbox;
    mailbox #(bit)              rd_done_mbox;
    mailbox #(fifo_transaction) rm_wr_mbox;
    mailbox #(fifo_transaction) rm_rd_mbox;
    mailbox #(fifo_transaction) sb_rd_mbox;
    mailbox #(fifo_transaction) sb_exp_mbox;

    function new(virtual fifo_if vif);
        // Create mailboxes
        wr_mbox      = new();
        rd_mbox      = new();
        wr_done_mbox = new();
        rd_done_mbox = new();
        rm_wr_mbox   = new();
        rm_rd_mbox   = new();
        sb_rd_mbox   = new();
        sb_exp_mbox  = new();

        // Create components
        gen    = new(wr_mbox, rd_mbox);
        
        // FIX: Pass explicit modports to strictly typed classes
        wr_drv = new(vif.WRITE_DRV, wr_mbox, wr_done_mbox, 0);
        rd_drv = new(vif.READ_DRV, rd_mbox, rd_done_mbox);
        wr_mon = new(vif.WR_MON, rm_wr_mbox);
        rd_mon = new(vif.RD_MON, sb_rd_mbox, rm_rd_mbox);
        
        rm     = new(rm_wr_mbox, rm_rd_mbox, sb_exp_mbox);
        sb     = new(sb_rd_mbox, sb_exp_mbox);
        cov    = new(vif); 
    endfunction

  
    task reset_dut(int cycles = 4);
        fork
            wr_drv.reset(cycles);
            rd_drv.reset(cycles);
        join
    endtask

    task start_env();
        fork
            wr_drv.reset();
            rd_drv.reset();
        join

        fork
            wr_drv.run();
            rd_drv.run();
            wr_mon.run();
            rd_mon.run();
            rm.run_writes();
            rm.run_reads();
            sb.run_check();
        join_none

    endtask

endclass