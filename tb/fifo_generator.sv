class fifo_generator;
    mailbox #(fifo_transaction) wr_mbox;
    mailbox #(fifo_transaction) rd_mbox;
    
    int unsigned num_writes;
    int unsigned num_reads;
    int unsigned total_sent;
    
    bit is_writing;

    function new(mailbox #(fifo_transaction) wr_mbox,
                 mailbox #(fifo_transaction) rd_mbox,
                 int unsigned num_writes = 8,
                 int unsigned num_reads  = 8);
        this.wr_mbox    = wr_mbox;
        this.rd_mbox    = rd_mbox;
        this.num_writes = num_writes;
        this.num_reads  = num_reads;
        this.total_sent = 0;
        this.is_writing = 0; 
    endfunction

    task run_writes();
        fifo_transaction txn;
        is_writing = 1; 
        for (int i = 0; i < num_writes; i++) begin
            txn    = new();
            txn.op = fifo_transaction::WRITE;
            if (!txn.randomize() with {op == fifo_transaction::WRITE;})
                $display("Randomization failed");
            total_sent += txn.burst_len; 
            wr_mbox.put(txn);
        end
        is_writing = 0;
    endtask

    task run_full_stress();
        fifo_transaction txn;
        $display("GENERATOR: Initiating Full Stress Test (64 writes)...");
        is_writing = 1;
        for (int i = 0; i < 64; i++) begin
            txn           = new();
            txn.op        = fifo_transaction::WRITE;
            txn.burst_len = 1;
            txn.wdata     = $urandom();
            total_sent += txn.burst_len;
            wr_mbox.put(txn);
        end
        is_writing = 0;
    endtask

    // FIX: is_writing held high across all bursts and inter-burst delays
    task run_writes_staggered(int num_bursts, int writes_per_burst, int delay_ns);
        fifo_transaction txn;
        is_writing = 1;
        for (int b = 0; b < num_bursts; b++) begin
            for (int i = 0; i < writes_per_burst; i++) begin
                txn    = new();
                txn.op = fifo_transaction::WRITE;
                if (!txn.randomize() with {op == fifo_transaction::WRITE;})
                    $display("Randomization failed");
                total_sent += txn.burst_len;
                wr_mbox.put(txn);
            end
            if (b < num_bursts - 1) #(delay_ns);
        end
        is_writing = 0;
    endtask

    task run_reads(); 
        fifo_transaction txn;
        int total_read = 0;
        
        while (is_writing || (total_read < total_sent)) begin
            if (total_read >= total_sent) begin
                #1; 
                continue; 
            end
            txn    = new();
            txn.op = fifo_transaction::READ;
            if (!txn.randomize() with {op == fifo_transaction::READ;})
                $display("Randomization failed");
            if (total_read + txn.burst_len > total_sent)
                txn.burst_len = total_sent - total_read;
            total_read += txn.burst_len;
            rd_mbox.put(txn);
        end
    endtask

endclass