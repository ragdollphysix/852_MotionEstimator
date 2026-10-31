//`timescale 1ns/10ps

interface pe_if (input bit clk);
    logic [7:0] R, S1, S2;
    logic S1S2mux, newDist;
    logic [7:0] Accumulate, Rpipe;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output R, S1, S2;
        output S1S2mux, newDist;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input R, S1, S2;
        input S1S2mux, newDist;
        input Accumulate, Rpipe;
    endclocking
endinterface

package PE_package;
    class Transaction;
        rand logic [7:0] R, S1, S2;
        rand logic S1S2mux, newDist;
        logic [7:0] Accumulate, Rpipe;
        static logic [7:0] prev_acc = 0;
        logic [7:0] exp_Accumulate, exp_Rpipe;

        constraint c_dist {
            R dist {0 := 5, 255 := 5, [1:254] :/ 90};
            S1 dist {0 := 5, 255 := 5, [1:254] :/ 90};
            S2 dist {0 := 5, 255 := 5, [1:254] :/ 90};
            newDist dist {0 := 70, 1 := 30};
        }

        function void model();
            bit [7:0] difference;
            bit [7:0] selection;
            bit carry;
            selection = (S1S2mux ? S1:S2);
            prev_acc = (newDist) ? 0 : prev_acc;
            difference = (R > selection) ? (R - selection) : (selection - R);
            {carry, exp_Accumulate} = {1'b0, prev_acc} + difference;
            if (carry) exp_Accumulate = 8'hFF;
            exp_Rpipe = R;
            prev_acc = exp_Accumulate;
        endfunction

        static function void reset_state();
            prev_acc = 0;
        endfunction
    endclass

    class Coverage;
    Transaction t;

    covergroup cg;

    option.per_instance = 1;
    cp_R : coverpoint t.R {
        bins zero = {0};
        bins first_quart = {[1: 64]};
        bins second_quart = {[65: 128]};
        bins third_quart = {[129: 192]};
        bins fourth_quart = {[193: 254]};
        bins max = {255};
    }

    cp_S1 : coverpoint t.S1 {
        bins zero = {0};
        bins first_quart = {[1: 64]};
        bins second_quart = {[65: 128]};
        bins third_quart = {[129: 192]};
        bins fourth_quart = {[193: 254]};
        bins max = {255};
    }
    
    cp_S2 : coverpoint t.S2 {
        bins zero = {0};
        bins first_quart = {[1: 64]};
        bins second_quart = {[65: 128]};
        bins third_quart = {[129: 192]};
        bins fourth_quart = {[193: 254]};
        bins max = {255};
    }

    cp_S1S2mux : coverpoint t.S1S2mux {
        bins zero = {0};
        bins one = {1};
    }

    cp_newDist : coverpoint t.newDist {
        bins zero = {0};
        bins one = {1};
    }

    cx_RS1 : cross cp_R, cp_S1, cp_S1S2mux{
        ignore_bins mux_not_S1 = binsof(cp_S1S2mux.zero);
    }
    cx_RS2 : cross cp_R, cp_S2, cp_S1S2mux{
        ignore_bins mux_not_S2 = binsof(cp_S1S2mux.one);
    }

    cx_RnewDist : cross cp_R, cp_newDist;
    endgroup

    function new();
        cg = new();
    endfunction

    function void sample(Transaction tr);
    t = tr;
    cg.sample();
    endfunction

    function void report();
        $display("[COV] total = %0.1f%%, R = %0.1f%%, S1 = %0.1f%%, S2 = %0.1f%%, S1S2mux = %0.1f%%, newDist = %0.1f%%, R x S1 = %0.1f%%, R x S2 = %0.1f%%, R x newDist = %0.1f%%",
        cg.get_coverage(), cg.cp_R.get_coverage(), cg.cp_S1.get_coverage(), cg.cp_S2.get_coverage(),
        cg.cp_S1S2mux.get_coverage(), cg.cp_newDist.get_coverage(), cg.cx_RS1.get_coverage(),
        cg.cx_RS2.get_coverage(), cg.cx_RnewDist.get_coverage());
    endfunction
    endclass

    class Generator;
        mailbox #(Transaction) gen2drv;
        int n_random;
        int n_total;

        function new(mailbox #(Transaction) m, int n);
            gen2drv = m;
            n_random = n;
            n_total = n + 4;
        endfunction

        task send(logic [7:0] R, logic [7:0] S1, logic [7:0] S2, logic S1S2mux, logic newDist);
            Transaction t = new();

            t.R = R;
            t.S1 = S1;
            t.S2 = S2;
            t.S1S2mux = S1S2mux;
            t.newDist = newDist;

            gen2drv.put(t);
        endtask

        task run();
        Transaction t;

        send(0, 1, 0, 1, 1); // R = S1 = 0
        send(0, 0, 1, 0, 1); // R = S2 = 0
        send(255, 1, 255, 1, 1); // R = S1 = 255
        send(255, 255, 1, 1, 1); // R = S2 = 255

        repeat(n_random) begin
            t = new();
            if (!t.randomize()) $fatal(1, "randomize failed");
            gen2drv.put(t);
        end

        endtask
    endclass

    class Driver;
    virtual pe_if vif;
    mailbox #(Transaction) gen2drv;
    int count;

    function new(virtual pe_if v, mailbox #(Transaction) m, int n);
        vif = v;
        gen2drv = m;
        count = n;
    endfunction

    task run();
        Transaction t;
        repeat (count) begin
            gen2drv.get(t);
            @(vif.drv_cb);
            vif.drv_cb.R <= t.R;
            vif.drv_cb.S1 <= t.S1;
            vif.drv_cb.S2 <= t.S2;
            vif.drv_cb.S1S2mux <= t.S1S2mux;
            vif.drv_cb.newDist <= t.newDist;
        end
    endtask
    endclass

    class Monitor;
    virtual pe_if vif;
    mailbox #(Transaction) mon2scb;
    Coverage cov;
    int count;

    function new(virtual pe_if v, mailbox #(Transaction) m, int n);
        vif = v;
        mon2scb = m;
        count = n;
        cov = new();
    endfunction

    task run();
        Transaction t;
        @(vif.mon_cb);
        repeat (count) begin
            @(vif.mon_cb);
            t = new();
            t.R = vif.mon_cb.R;
            t.S1 = vif.mon_cb.S1;
            t.S2 = vif.mon_cb.S2;
            t.S1S2mux = vif.mon_cb.S1S2mux;
            t.newDist = vif.mon_cb.newDist;
            t.Accumulate = vif.mon_cb.Accumulate;
            t.Rpipe = vif.mon_cb.Rpipe;
            cov.sample(t);
            mon2scb.put(t);
        end
    endtask
    endclass

    class Scoreboard;
        mailbox #(Transaction) mon2scb;
        int count, correct, errors;
        logic [7:0] prev_exp_acc, prev_exp_pipe;
        bit not_first;

        function new(mailbox #(Transaction) m, int n);
            mon2scb = m;
            count = n;
            correct = 0;
            errors = 0;
        endfunction

        task run();
            Transaction t;

            repeat (count) begin
                mon2scb.get(t);
                if (not_first) begin
                if ((prev_exp_acc === t.Accumulate) && (prev_exp_pipe === t.Rpipe)) correct++;
                else begin
                    errors++;
                    $display("[SCB] R = %d, S1 = %d, S2 = %d, S1S2mux = %d, newDist = %d, Accumulate = %d, Rpipe = %d, exp_Accumulate = %d, expRpipe = %d",
                    t.R, t.S1, t.S2, t.S1S2mux, t.newDist, t.Accumulate, t.Rpipe, prev_exp_acc, prev_exp_pipe);
                end
            end
            t.model();
            prev_exp_acc = t.exp_Accumulate;
            prev_exp_pipe = t.exp_Rpipe;
            not_first = 1;
            end
        endtask

        function void report();
            $display("[SCB] checked=%0d correct=%0d errors=%0d  %s",
               correct + errors, correct, errors, (errors == 0 && correct == count-1) ? "PASS" : "FAIL");
        endfunction
    endclass
endpackage

module tb_pe;
    import PE_package::*;

    logic clk = 0;
    always #5 clk = ~clk;

    pe_if intf(clk);
    PE dut(.clock(clk), .R(intf.R), .S1(intf.S1),
    .S2(intf.S2), .S1S2mux(intf.S1S2mux), .newDist(intf.newDist),
    .Accumulate(intf.Accumulate), .Rpipe(intf.Rpipe));

    initial begin
        mailbox #(Transaction) gen2drv = new();
        mailbox #(Transaction) mon2scb = new();
        Generator gen;
        Driver drv;
        Monitor mon;
        Scoreboard scb;

        gen = new(gen2drv, 10000);
        drv = new(intf, gen2drv, gen.n_total);
        mon = new(intf, mon2scb, gen.n_total);
        scb = new(mon2scb, gen.n_total);

        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join

        scb.report();
        mon.cov.report();
        $finish;
    end

    initial begin
        #1_000_000;
        $display("TIMEOUT");
        $finish;
    end
endmodule