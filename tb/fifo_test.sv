class fifo_test;
    fifo_env env;
    int unsigned global_ops_sent;

    function new(virtual fifo_if vif);
        env             = new(vif);
        global_ops_sent = 0;
    endfunction

    task test_sanity();
        $display("\n=== STARTING SANITY TEST ===");
        env.gen.num_writes = 15;
        env.gen.total_sent = 0;
        env.gen.run_writes();   
        env.gen.run_reads();
        global_ops_sent += env.gen.total_sent;
        wait(env.sb.pass_count + env.sb.fail_count == global_ops_sent);
        $display("=== SANITY TEST COMPLETE ===\n");
    endtask

    task test_stress();
        $display("\n=== STARTING STRESS TEST ===");
        env.reset_dut();
        env.gen.total_sent = 0;
        env.gen.run_full_stress();
        wait(env.wr_mon.vif.wr_mon_cb.full === 1'b1);
        $display("STRESS TEST: FIFO is FULL. Starting reads...");
        env.gen.run_reads();
        global_ops_sent += env.gen.total_sent;
        wait(env.sb.pass_count + env.sb.fail_count == global_ops_sent);
        $display("=== STRESS TEST COMPLETE ===\n");
    endtask

    task test_concurrent();
        $display("\n========================================");
        $display("=== [TEST 3] CONCURRENT R/W TRAFFIC  ===");
        $display("========================================");
        env.reset_dut();
        env.gen.num_writes = 100;   
        env.gen.total_sent = 0;
        fork
            env.gen.run_writes();
            env.gen.run_reads();
        join
        global_ops_sent += env.gen.total_sent;
        wait(env.sb.pass_count + env.sb.fail_count == global_ops_sent);
        $display("=== [TEST 3] COMPLETE ===\n");
    endtask

    task test_starvation();
        $display("\n========================================");
        $display("=== [TEST 4] STARVATION / SLOW WRITE ===");
        $display("========================================");
        env.reset_dut();
        env.gen.total_sent = 0;
        fork
            env.gen.run_writes_staggered(3, 10, 500); 
            env.gen.run_reads();
        join
        global_ops_sent += env.gen.total_sent;
        wait(env.sb.pass_count + env.sb.fail_count == global_ops_sent);
        $display("=== [TEST 4] COMPLETE ===\n");
    endtask

    task test_burst_full();
        $display("\n========================================");
        $display("=== [TEST 5] BURST INTO FULL WALL    ===");
        $display("========================================");
        env.reset_dut();
        env.gen.num_writes = 25;   
        env.gen.total_sent = 0;
        fork
            env.gen.run_writes();  
        join_none
        wait(env.wr_mon.vif.wr_mon_cb.full === 1'b1);
        $display("BURST TEST: FIFO hit the FULL wall! Releasing reads...");
        env.gen.run_reads();
        global_ops_sent += env.gen.total_sent;
        wait(env.sb.pass_count + env.sb.fail_count == global_ops_sent);
        $display("=== [TEST 5] COMPLETE ===\n");
    endtask

    task run();
        env.start_env();
        test_sanity();
        test_stress();
        test_concurrent();
        test_starvation();
        test_burst_full();
        #100;
        $display("========================================");
        $display("=== FINAL SCOREBOARD SUMMARY ===");
        $display("PASS: %0d | FAIL: %0d", env.sb.pass_count, env.sb.fail_count);
        $display("========================================");
        env.cov.report();
        $finish;
    endtask
endclass
