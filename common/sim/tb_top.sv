//`timescale 1ns/10ps

interface top_if (input bit clk);
    logic start;
    logic [7:0] R, S1, S2;

    logic [9:0] AddressS1, AddressS2;
    logic [7:0] BestDist, AddressR;
    logic [3:0] motionX, motionY;
    logic completed;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output start;
        input completed;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input start, BestDist, motionX, motionY, completed;
    endclocking
endinterface




module top_testbench;

    class Transaction;
        rand int Xoff, Yoff;
        constraint X { Xoff < 8; Xoff > -9;};
        constraint Y { Yoff < 8; Yoff > -9;};
        constraint c_dist {
            Xoff dist {-8 := 10, 7 := 10, [-7:6] :/ 80};
            Yoff dist {-8 := 10, 7 := 10, [-7:6] :/ 80};
        }

        reg [7:0] expected_dist;
        reg [7:0] Rmem_write[256];
        rand reg [7:0] Smem_write[1024];

        function new();
            Rmem_write = '{default:0};
        endfunction

        function void post_randomize();
            expected_dist = 0;
            for (int i = 0; i < 16; i++) begin
                for (int j = 0; j < 16; j++) begin
                    reg [7:0] s;
                    Rmem_write[16*j+i] = Smem_write[32*(j+8+Yoff) + (i+8+Xoff)];
                end
            end
        endfunction


    endclass

    class Coverage;
    Transaction t;

    covergroup cg;

    MotionX: coverpoint t.Xoff{
      bins neg_4 = {[-8:-7]};
      bins neg_3 = {[-6:-5]};
      bins neg_2 = {[-4:-3]};
      bins neg_1 = {[-2:-1]};
      bins pos_1 = {[0:1]};
      bins pos_2 = {[2:3]};
      bins pos_3 = {[4:5]};
      bins pos_4 = {[6:7]};
    }
    MotionY: coverpoint t.Yoff{
      bins neg_4 = {[-8:-7]};
      bins neg_3 = {[-6:-5]};
      bins neg_2 = {[-4:-3]};
      bins neg_1 = {[-2:-1]};
      bins pos_1 = {[0:1]};
      bins pos_2 = {[2:3]};
      bins pos_3 = {[4:5]};
      bins pos_4 = {[6:7]};

    }
    
    Total_Offset: cross MotionX, MotionY;
    endgroup

    function new();
        cg = new();
    endfunction

    function void report();
        $display("[COV] total = %0.1f%%", cg.get_coverage());
    endfunction

    function void sample(Transaction tr);
    t = tr;
    cg.sample();
    endfunction

    endclass

    class Generator;
        mailbox #(Transaction) gen2drv;
        int count;

        function new(mailbox #(Transaction) m, int n);
            gen2drv = m;
            count = n;
        endfunction


        task run();
        Transaction t;

        repeat(count) begin
            t = new();
            if (!t.randomize()) $fatal(1, "randomize failed");
            gen2drv.put(t);
        end

        endtask
    endclass

    class Driver;
    virtual top_if vif;
    mailbox #(Transaction) gen2drv, drv2scb;
    int count;

    function new(virtual top_if v, mailbox #(Transaction) m, mailbox #(Transaction) ms, int n);
        vif = v;
        gen2drv = m;
        drv2scb = ms;
        count = n;
    endfunction

    task run();
        Transaction t;
        repeat (count) begin
            gen2drv.get(t);

            memR_u.Rmem = t.Rmem_write;
            memS_u.Smem = t.Smem_write;

            vif.drv_cb.start <= 0;
            repeat (2) @(vif.drv_cb);
            vif.drv_cb.start <= 1;
            wait(vif.drv_cb.completed == 1);
            repeat (2) @(vif.drv_cb);

            drv2scb.put(t);
        end
    endtask
    endclass

    class Results;
        reg [7:0] best_dist;
        reg [3:0] x, y;
    endclass

    class Monitor;
    Results r;
    virtual top_if vif;
    mailbox #(Results) mon2scb;
    int count;

    function new(virtual top_if v, mailbox #(Results) m, int n);
        vif = v;
        mon2scb = m;
        count = n;
    endfunction

    task run();
        int completes = 0;

        repeat (count) begin
            @(posedge vif.completed);
            repeat(2) @(vif.mon_cb);

            r = new();
            r.x     = vif.mon_cb.motionX;
            r.y     = vif.mon_cb.motionY;
            r.best_dist  = vif.mon_cb.BestDist;
            completes++;
            $display("[MON] t=%0t run %0d: BestDist=%0d motionX=%0d motionY=%0d",
                     $time, completes, r.best_dist, $signed(r.x), $signed(r.y));
            mon2scb.put(r);
        end
    endtask
    endclass

    class Scoreboard;
        mailbox #(Results) mon2scb;
        mailbox #(Transaction) drv2scb;
        Coverage cov;
        int count, successes, failures;
        real accuracy;

        function new(mailbox #(Transaction) m, mailbox #(Results) mr, int n);
            mon2scb = mr;
            drv2scb = m;
            count = n;
            successes = 0;
            failures = 0;
            cov = new();
        endfunction

        task run();
            Transaction t;
            Results r;
            int signed x, y;

            repeat (count) begin
                mon2scb.get(r);
                drv2scb.get(t);
                cov.sample(t);

                x = $signed(r.x);
                y = $signed(r.y);

            if(t.Xoff != x || t.Yoff != y || t.expected_dist != r.best_dist) begin
        $display("[SCB] FAIL: expected X=%0d Y=%0d Dist=%0d, got X=%0d Y=%0d Dist=%0d",
                t.Xoff, t.Yoff, t.expected_dist, x, y, r.best_dist);
        failures += 1;
      end else begin
        //$display("[SCB] PASS: X=%0d Y=%0d Dist=%0d", x, y, r.best_dist);
        successes += 1;
      end
      
      // accuracy
      
      
        end
        endtask

        function void report();
            $display("[SCB] checked=%0d correct=%0d errors=%0d  %s",
            successes + failures, successes, failures, (failures == 0 && successes == count) ? "PASS" : "FAIL");

            accuracy = ((successes) * 100.0/(failures + successes));
            $display("Accuracy: %f%%", accuracy);
        endfunction
    endclass

    logic clk = 0;
    always #5 clk = ~clk;

    top_if intf(clk);
       top dut (
     .BestDist(intf.BestDist [7:0]),
     .motionX(intf.motionX [3:0]),
     .motionY(intf.motionY [3:0]),
     .clock(clk),
     .start(intf.start),
     .AddressR(intf.AddressR),
     .AddressS1(intf.AddressS1),
     .AddressS2(intf.AddressS2),
     .R(intf.R),
     .S1(intf.S1),
     .S2(intf.S2),
     .completed(intf.completed)
   );

    ROM_R memR_u(.clock(clk), .AddressR(intf.AddressR), .R(intf.R));
    ROM_S memS_u(.clock(clk), .AddressS1(intf.AddressS1), .AddressS2(intf.AddressS2), .S1(intf.S1), .S2(intf.S2));

    initial begin
        mailbox #(Transaction) gen2drv = new();
        mailbox #(Transaction) drv2scb = new();
        mailbox #(Results) mon2scb = new();
        Generator gen;
        Driver drv;
        Monitor mon;
        Scoreboard scb;

        gen = new(gen2drv, 400);
        drv = new(intf, gen2drv, drv2scb, gen.count);
        mon = new(intf, mon2scb, gen.count);
        scb = new(drv2scb, mon2scb, gen.count);

        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join

        scb.report();
        scb.cov.report();
        $finish;
    end

    initial begin
        #1_000_000_000;
        $display("TIMEOUT");
        $finish;
    end
endmodule