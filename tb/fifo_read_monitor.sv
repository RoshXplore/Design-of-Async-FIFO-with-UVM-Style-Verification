class fifo_read_monitor;

    virtual fifo_if.RD_MON vif;

    mailbox #(fifo_transaction) sb_rd_mbox; //To scoreboard
    mailbox #(fifo_transaction) rm_rd_mbox; //To ref model
 
    int unsigned observed_count;

    function new( virtual fifo_if.RD_MON vif,
                  mailbox #(fifo_transaction) sb_rd_mbox,
                  mailbox #(fifo_transaction) rm_rd_mbox);
        this.vif = vif;
        this.sb_rd_mbox = sb_rd_mbox;
        this.rm_rd_mbox = rm_rd_mbox;
    endfunction

    task run();
        bit pending_read = 0;
        $display("RD_MON started");
        
        forever begin
            @(vif.rd_mon_cb);

            // 1. Capture data from the read that was requested LAST cycle
            if (pending_read) begin
                fifo_transaction txn = new();
                txn.op    = fifo_transaction::READ;
                txn.rdata = vif.rd_mon_cb.rdata;
                txn.empty = vif.rd_mon_cb.empty;
                
                txn.print("rd_mon");
                sb_rd_mbox.put(txn);
                rm_rd_mbox.put(txn);
                
                observed_count++;
            end

            // 2. Check if a valid read is happening THIS cycle
            pending_read = (vif.rd_mon_cb.rd_en === 1'b1 && !vif.rd_mon_cb.empty);
        end
    endtask

endclass