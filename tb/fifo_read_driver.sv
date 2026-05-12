class fifo_read_driver;

    virtual fifo_if.READ_DRV vif;

    mailbox #(fifo_transaction) rd_mbox;
    mailbox #(bit)              rd_done_mbox;
    int unsigned txn_count;

    function new (virtual fifo_if.READ_DRV vif,
                  mailbox #(fifo_transaction) rd_mbox,
                  mailbox #(bit) rd_done_mbox);
        this.vif          = vif;
        this.rd_done_mbox = rd_done_mbox;
        this.rd_mbox      = rd_mbox;
        this.txn_count    = 0;
    endfunction

    task reset (int cycles = 4);
        $display("Applying Read Domain reset");
        vif.rd_rstn     <= 0;
        vif.rd_cb.rd_en <= 0;
        repeat(cycles) @(vif.rd_cb);
        vif.rd_rstn <= 1'b1;
        $display("Read Reset deasserted");
    endtask

    task drive (fifo_transaction txn);
        int valid_reads = 0;
        bit en_driven = 1'b0;
        
        vif.rd_cb.rd_en <= 1'b0;

        while (valid_reads < txn.burst_len) begin
            @(vif.rd_cb); // Synchronize to clock edge

            // 1. Did the previously requested read succeed?
            if (en_driven == 1'b1 && !vif.rd_cb.empty) begin
                valid_reads++;
                
                if (valid_reads == txn.burst_len) begin
                    vif.rd_cb.rd_en <= 1'b0;
                    break;
                end
            end

            // 2. Drive for the NEXT cycle
            if (!vif.rd_cb.empty) begin
                vif.rd_cb.rd_en <= 1'b1;
                en_driven = 1'b1;
            end else begin
                vif.rd_cb.rd_en <= 1'b0;
                en_driven = 1'b0;
            end
        end
    endtask

    task run();
        fifo_transaction txn;
        forever begin
            rd_mbox.get(txn);
            drive(txn);
            txn_count++;
            rd_done_mbox.put(1'b1);
        end
    endtask

endclass