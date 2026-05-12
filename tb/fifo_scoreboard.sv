class fifo_scoreboard;

    mailbox #(fifo_transaction) sb_rd_mbox;
    mailbox #(fifo_transaction) sb_exp_mbox;


    int unsigned pass_count;
    int unsigned fail_count;

    function new(mailbox #(fifo_transaction) sb_rd_mbox,
                 mailbox #(fifo_transaction) sb_exp_mbox);

        this.sb_exp_mbox = sb_exp_mbox;
        this.sb_rd_mbox = sb_rd_mbox;


    endfunction

    task run_check();

        fifo_transaction actual, expected;

        $display("sb started");

        forever begin

            sb_rd_mbox.get(actual);
            sb_exp_mbox.get(expected);

            check(actual,expected);

        end

    endtask

    function void check(fifo_transaction actual, fifo_transaction expected);

        bit data_match;
   
        data_match = (actual.rdata == expected.rdata);

        if(data_match)begin
            pass_count++;
            $display("sb passed data = %h", actual.rdata);
        end
        else begin
            fail_count++;  
            $display("sb FAIL: actual = %0h, expected = %0h", actual.rdata, expected.rdata);
        end
        

    endfunction
    
endclass