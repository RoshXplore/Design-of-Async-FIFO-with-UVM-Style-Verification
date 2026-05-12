class fifo_ref_model;

    logic [31:0] shadow_fifo[$];

    mailbox #(fifo_transaction) rm_wr_mbox; //Write
    mailbox #(fifo_transaction) rm_rd_mbox; //Read 
    mailbox #(fifo_transaction) sb_exp_mbox; //Expected scoreboard

    int unsigned wr_processed;
    int unsigned rd_processed;

    function new(mailbox #(fifo_transaction) rm_wr_mbox,
                 mailbox #(fifo_transaction) rm_rd_mbox,
                 mailbox #(fifo_transaction) sb_exp_mbox);
        
        this.rm_rd_mbox = rm_rd_mbox;
        this.rm_wr_mbox = rm_wr_mbox;
        this.sb_exp_mbox = sb_exp_mbox;
    
    endfunction

    // WRITE TASK

    task run_writes();

        fifo_transaction txn;

        $display("[RM] write task started");

        forever begin

            txn = new();

            rm_wr_mbox.get(txn);
            shadow_fifo.push_back(txn.wdata);
            

            wr_processed++;

            $display("[RM]data is %h ", txn.wdata);

        end

    endtask

    // READ TASK

    task run_reads();

        fifo_transaction txn;

        $display("[RM] read task started");

        forever begin

            txn = new();

            rm_rd_mbox.get(txn);
            if (shadow_fifo.size() > 0)
                txn.rdata = shadow_fifo.pop_front();
            else begin
                $display("[RM] ERROR: read from empty shadow FIFO");
                txn.rdata = 32'hDEAD_BEEF;  // sentinel to make scoreboard fail visibly
            end

            sb_exp_mbox.put(txn);

            rd_processed++;

        end

    endtask




endclass