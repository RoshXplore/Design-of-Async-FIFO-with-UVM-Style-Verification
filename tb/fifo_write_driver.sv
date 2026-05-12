class async_fifo_write_driver;

    virtual fifo_if.WRITE_DRV vif;

    mailbox #(fifo_transaction) wr_mbox;
    mailbox #(bit)              wr_done_mbox;
    int unsigned txn_count;

    function new (virtual fifo_if.WRITE_DRV vif,
                  mailbox #(fifo_transaction) wr_mbox,
                  mailbox #(bit) wr_done_mbox,
                  int unsigned txn_count);
        this.vif          = vif;
        this.wr_done_mbox = wr_done_mbox;
        this.wr_mbox      = wr_mbox;
        this.txn_count    = txn_count;
    endfunction

    task reset (int cycles = 4);
        $display("Applying reset task");
        vif.wr_rstn     <= 0;
        vif.wr_cb.wr_en <= 0;
        vif.wr_cb.wdata <= 0;
        repeat(cycles) @(vif.wr_cb);
        vif.wr_rstn <= 1'b1;
        $display("Reset deasserted");
    endtask

    task drive(fifo_transaction txn);
        int valid_writes = 0;
        bit en_driven = 1'b0;
        
        // Setup initial driver state
        vif.wr_cb.wr_en <= 1'b0;
        vif.wr_cb.wdata <= txn.wdata;

        while (valid_writes < txn.burst_len) begin
            @(vif.wr_cb); // Synchronize to clock edge

            // 1. Did the previously requested write succeed?
            if (en_driven == 1'b1 && !vif.wr_cb.full) begin
                valid_writes++;
                
                // If burst is done, drop enable and exit loop immediately
                if (valid_writes == txn.burst_len) begin
                    vif.wr_cb.wr_en <= 1'b0;
                    break;
                end
                
                // Randomize data for the next beat in the burst
                txn.wdata = $urandom();
                vif.wr_cb.wdata <= txn.wdata;
            end

            // 2. Drive enable for the NEXT cycle if FIFO is ready
            if (!vif.wr_cb.full) begin
                vif.wr_cb.wr_en <= 1'b1;
                en_driven = 1'b1;
            end else begin
                vif.wr_cb.wr_en <= 1'b0;
                en_driven = 1'b0;
            end
        end
    endtask

    task run();
        fifo_transaction txn;
        forever begin
            wr_mbox.get(txn);
            drive(txn);
            txn_count++;
            wr_done_mbox.put(1'b1);
        end
    endtask

endclass