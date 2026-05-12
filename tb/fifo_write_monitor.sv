class fifo_write_monitor;

    virtual fifo_if.WR_MON vif;

    mailbox #(fifo_transaction) rm_wr_mbox; // To ref model

    int unsigned observed_count;

    function new(virtual fifo_if.WR_MON vif,
                 mailbox #(fifo_transaction) rm_wr_mbox);
        this.vif        = vif;
        this.rm_wr_mbox = rm_wr_mbox;
    endfunction

    task run();

        fifo_transaction txn;

        $display("WR_MON started");

        forever begin
            @(vif.wr_mon_cb);
            if (vif.wr_mon_cb.wr_en == 1'b1 && !vif.wr_mon_cb.full) begin

                txn       = new();
                txn.op    = fifo_transaction::WRITE;
                txn.wdata = vif.wr_mon_cb.wdata;
                txn.full  = vif.wr_mon_cb.full;


                observed_count++;

                txn.print("wr_mon");

                rm_wr_mbox.put(txn);
            end
        end

    endtask

endclass