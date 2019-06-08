`timescale 1ns / 1ps
// The instruction cache.
// Format:
// | Tag[18:0] | data... 64Bytes | * 128
// Address format:
// addr[31:13] as Tag
// addr[12:6] as Index
// addr[5:2] as Offset
// addr[1:0] is unused in i$

module instruction_cache(
        input                       clk,
        input                       rst,
        
        input  [31:0]               inst_addr, // Physics address, please
        input                       pc_changed, // We must consider this fucking condiction
        
        // To CPU
        output logic[31:0]          inst_data,
        output logic                inst_ok,
        
        // To MMU
        output logic[31:0]          inst_addr_mmu,
        output logic                inst_read_req,
        input                       inst_addr_ok,
        input  [31:0]               inst_read_data,
        input                       mmu_valid,
        input  [31:0]               mmu_last
);
    parameter [1:0] // ICache FSM
        SHAK = 2'b00, // In SHAK state, wait for the handshake done.
        IDLE = 2'b01, // In IDLE state, read from cache is OKAY.
        WIAT = 2'b10, // In WIAT state, the data is transformed into cache.
        PCCH = 2'b11; // In PCCH state, the current is wait for prevoois data load.

    reg [127:0]     icache_valid;
    reg [  1:0]     icache_curr;
    reg [  1:0]     icache_next;
    reg [ 31:0]     waiting_address;
    reg [ 31:0]     pending_address;
    
    reg [  3:0]     receive_counter;
    reg [ 31:0]     receive_buffer[0:15];
    
    wire [530:0]    icache_return;
    wire [ 31:0]    icache_return_data[0:15];
    wire [ 18:0]    inst_tag    = inst_addr[31:13];
    wire [  6:0]    inst_index  = inst_addr[12: 6];
    wire [  3:0]    inst_offset = inst_addr[5: 2];
    wire [ 18:0]    icache_return_tag = icache_return[18:0];
    
    logic [  6:0]    ram_a;
    wire  [530:0]    ram_d;
    logic            ram_we;
    
    assign icache_return_data[0] = icache_return[50:19];
    assign icache_return_data[1] = icache_return[82:51];
    assign icache_return_data[2] = icache_return[114:83];
    assign icache_return_data[3] = icache_return[146:115];
    assign icache_return_data[4] = icache_return[178:147];
    assign icache_return_data[5] = icache_return[210:179];
    assign icache_return_data[6] = icache_return[242:211];
    assign icache_return_data[7] = icache_return[274:243];
    assign icache_return_data[8] = icache_return[306:275];
    assign icache_return_data[9] = icache_return[338:307];
    assign icache_return_data[10] = icache_return[370:339];
    assign icache_return_data[11] = icache_return[402:371];
    assign icache_return_data[12] = icache_return[434:403];
    assign icache_return_data[13] = icache_return[466:435];
    assign icache_return_data[14] = icache_return[498:467];
    assign icache_return_data[15] = icache_return[530:499];
    assign ram_d[18:0] = waiting_address[31:13];
    assign ram_d[50:19] = receive_buffer[0];
    assign ram_d[82:51] = receive_buffer[1];
    assign ram_d[114:83] = receive_buffer[2];
    assign ram_d[146:115] = receive_buffer[3];
    assign ram_d[178:147] = receive_buffer[4];
    assign ram_d[210:179] = receive_buffer[5];
    assign ram_d[242:211] = receive_buffer[6];
    assign ram_d[274:243] = receive_buffer[7];
    assign ram_d[306:275] = receive_buffer[8];
    assign ram_d[338:307] = receive_buffer[9];
    assign ram_d[370:339] = receive_buffer[10];
    assign ram_d[402:371] = receive_buffer[11];
    assign ram_d[434:403] = receive_buffer[12];
    assign ram_d[466:435] = receive_buffer[13];
    assign ram_d[498:467] = receive_buffer[14];
    assign ram_d[530:499] = receive_buffer[15];
    
    always_ff @(posedge clk) begin : update_current_state
        if(rst)
            icache_curr <= IDLE;
        else
            icache_curr <= icache_next;
    end

    always_ff @(posedge clk) begin : update_valid
        if(rst)
            icache_valid <= 128'd0;
        else begin
            if(icache_curr != IDLE)
                icache_valid[waiting_address[12:6]] <= 1'b1;
        end
    end
    
    
    always_comb begin : update_fsm_status
        case(icache_curr)
        WIAT: begin // Receving data...
            inst_ok = 1'b0;
            inst_data = 32'd0;
            inst_addr_mmu = 32'd0;
            inst_read_req = 1'd0;
            if(mmu_valid) begin
                receive_buffer[receive_counter] = inst_read_data;
                receive_counter = receive_counter + 1;
                if(mmu_last) begin
                    ram_we = 1'd1;
                    icache_next = IDLE;
                    inst_ok = 1'b1;
                    inst_data = receive_buffer[waiting_address[5:2]];
                end
            end
            if(pc_changed) begin
                pending_address = inst_addr;
                icache_next = PCCH;
            end 
        end
        PCCH: begin
            inst_ok = 1'b0;
            inst_data = 32'd0;
            inst_addr_mmu = 32'd0;
            inst_read_req = 1'd0;
            if(mmu_valid) begin
                receive_buffer[receive_counter] = inst_read_data;
                receive_counter = receive_counter + 1;
                if(mmu_last) begin
                    ram_we = 1'd1;
                    icache_next = SHAK; // Handshake failed.
                end
            end
        end
        SHAK: begin
                inst_ok = 1'b0;
                inst_data = 32'd0;
                inst_addr_mmu = {pending_address[31:6], 6'b0};
                inst_read_req = 1'b1;
                if(inst_addr_ok) begin
                    icache_next = WIAT;
                    receive_counter = 4'd0;
                    waiting_address = pending_address;
                end
                else
                    icache_next = SHAK; // Handshake failed.
        end
        default: begin // IDLE
            if(icache_valid[inst_index] && 
                 icache_return_tag == inst_tag) begin // Gotcha!
                ram_a = inst_index;
                inst_ok = 1'b1;
                inst_data = icache_return_data[inst_offset];
                inst_addr_mmu = 32'd0;
                inst_read_req = 1'd0;
                icache_next = IDLE;
            end
            else begin // Cache miss
                inst_ok = 1'b0;
                inst_data = 32'd0;
                inst_addr_mmu = {inst_addr[31:6], 6'b0};
                inst_read_req = 1'b1;
                    if(inst_addr_ok) begin
                        icache_next = WIAT;
                        receive_counter = 4'd0;
                        waiting_address = inst_addr;
                    end
                    else
                        icache_next = IDLE; // Handshake failed.
            end
        end
        endcase
    end

    dist_mem_gen_icache icache_ram(
        .clk            (clk),
        .a              (ram_a),
        .d              (ram_d),
        .we             (ram_we),
        .spo            (icache_return)
    );
endmodule
