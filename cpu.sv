import structs::*;

module cpu (
    input wire clk_in,
    input wire fpga_clk,
    input wire [7:0] rd_memory_data,
    input wire [15:0] keymap,
    output int cycle_counter,
    output logic [11:0] rd_memory_address,
    output logic [11:0] wr_memory_address,
    output logic [7:0] wr_memory_data,
    output logic wr_go,
    output logic lcd_clk,
    output logic lcd_data,
    output logic [5:0] led,
    input wire [3:0] row,
    input wire [3:0] col,
    input wire debug_overlay
);

logic [5:0] lcd_led;
  logic alu_rst;
  logic [7:0] alu_result;
  logic [15:0] alu_result_long;
  logic alu_overflow;
  logic alu_done;
  logic compute_of;

  assign led = state[5:0];

  alu alu (
      alu_rst,
      clk_in, 
      instr.alu_i,
      alu_result,
      alu_result_long,
      alu_overflow,
      alu_done
      );

  logic [7:0] vram [0:1023];

`ifdef DUMMY_GPU
  gpu gpu(
`endif
`ifndef DUMMY_GPU
  st7920_serial_driver gpu(
`endif
      fpga_clk,
      1'b1,
      vram,
      lcd_clk,
      lcd_data,
      lcd_led
);

  task write_pixels;
    input [31:0] x;
    input [31:0] y;

    begin
        // bottom left
        `define BLP ((y*128*2) + x*2 +128)
        if (vram[`BLP/8][7-(`BLP%8)] == 1) begin
          registers[15] <= 1;
        end
        vram[`BLP/8][7-(`BLP%8)] = vram[`BLP/8][7-(`BLP%8)] ^ 1;      

        // bottom right
        `define BRP ((y*128*2) + x*2 +129)
        vram[`BRP/8][7-(`BRP%8)] = vram[`BRP/8][7-(`BRP%8)] ^ 1;      

        // top left
        `define TLP ((y*128*2) + x*2)
        vram[`TLP/8][7-(`TLP%8)] =  vram[`TLP/8][7-(`TLP%8)] ^ 1;      

        // top right
        `define TRP ((y*128*2) + x*2+1)
        vram[`TRP/8][7-(`TRP%8)] = vram[`TRP/8][7-(`TRP%8)] ^ 1;      
    end
  endtask

  logic [15:0] program_counter;

  logic [7:0] registers[0:15];
  logic [15:0] index_reg;

  logic [15:0] stack[0:15];

  logic [3:0] stack_pointer;
  logic [15:0] opcode;

  logic [7:0] sound_timer;
  logic [7:0] delay_timer;

  logic [7:0] ldl_cnt;
  int clr_cnt;

  

  typedef enum {ST_FETCH_HI, ST_FETCH_LO, ST_FETCH_LO2, ST_DECODE, ST_EXEC, ST_DRAW, ST_FETCH_MEM, ST_WB, ST_CLEANUP, ST_HALT} cpu_state;
  cpu_state state;
  
  typedef enum {INIT, DRAW} draw_stage;
  
  typedef enum {CLS, LD, DRW, JP, ALU, CALU, CALL, RET, ALUJ, LDL, BCD, IOJ, IOW, NIOJ} cpu_opcode;
  typedef enum {REG, IDX_REG, BYTE, MEM, SPRITE_MEM, KEY, DELAY_TIMER, SOUND_TIMER} data_type;

  struct {
      draw_stage stage;
      logic [4:0] r;
      logic [4:0] c;
      logic [7:0] x;
      logic [7:0] y;
  } draw_state;


  struct packed {
      cpu_opcode op;
      data_type src;
      data_type dst;

      logic [3:0] dst_reg;
      logic [3:0] src_reg;

      alu_input alu_i; 

      logic [11:0] src_byte;
      logic [3:0] src_key;

      logic [(8*16)-1:0] src_sprite;
      logic [11:0] src_sprite_addr;
      logic [3:0] src_sprite_vx;
      logic [3:0] src_sprite_vy;
      logic [7:0] src_sprite_x;
      logic [7:0] src_sprite_y;
      logic [4:0] src_sprite_sz;
      logic [4:0] src_sprite_idx;

      logic [11:0] src_addr;
      logic [11:0] dst_addr;
  } instr;

  initial begin
    state = ST_FETCH_HI;
    cycle_counter = 0;
    program_counter = 'h200;
    wr_go = 0;
    alu_rst = 1;
    stack_pointer = 0;
    for (int i = 0; i < 1024; i++) begin
        vram[i] = 0;
    end
  end

  always_ff @(posedge clk_in) begin
`ifdef FAST_CLOCK
    if (cycle_counter % 100 == 0) begin
`endif
        if (delay_timer > 0)
            delay_timer <= delay_timer - 1;
        if (sound_timer > 0)
            sound_timer <= sound_timer - 1;
`ifdef FAST_CLOCK
    end
`endif
    case (state)
        ST_FETCH_HI: begin
            rd_memory_address <= program_counter[11:0];
            program_counter <= program_counter + 1;
            state <= ST_FETCH_LO;
        end

        ST_FETCH_LO: begin
            rd_memory_address <= program_counter[11:0];
            program_counter <= program_counter - 1;
            opcode <= { rd_memory_data, 8'h00 };
            state <= ST_FETCH_LO2;
        end

        ST_FETCH_LO2: begin
            opcode <= { opcode[15:8], rd_memory_data};
            state <= ST_DECODE;
        end

        ST_DECODE: begin
            casez (opcode)
                16'h0???: begin
                   if (opcode == 16'h00e0) begin
                        instr.op <= CLS;
                        state <= ST_EXEC;
                        clr_cnt <= 0;
                        program_counter <= program_counter + 2;
                    end else if (opcode == 16'h00EE) begin
                        instr.op <= RET;
                        state <= ST_EXEC;
                    end else begin
                        program_counter <= program_counter + 2;
                        state <= ST_CLEANUP;
                   end
                end
                16'h1???: begin
                    instr.op <= JP;
                    instr.src_byte <= opcode[11:0];
                    state <= ST_EXEC;
                end
                16'h2???: begin
                    instr.op <= CALL;
                    instr.src_byte <= opcode[11:0];
                    state <= ST_EXEC;
                end
                16'h3???: begin
                    instr.op <= CALU;
                    instr.alu_i.op <= structs::SE;
                    instr.alu_i.operand_a <= opcode[7:0];
                    instr.alu_i.operand_b <= registers[opcode[11:8]];
                    compute_of <= 0;
                    state <= ST_EXEC; 
                end
                16'h4???: begin
                    instr.op <= CALU;
                    instr.alu_i.op <= structs::SNE;
                    instr.alu_i.operand_a <= opcode[7:0];
                    instr.alu_i.operand_b <= registers[opcode[11:8]];
                    compute_of <= 0;
                    state <= ST_EXEC; 
                end
                16'h5??0: begin
                    instr.op <= CALU;
                    instr.alu_i.op <= structs::SE;
                    instr.alu_i.operand_a <= registers[opcode[7:4]];
                    instr.alu_i.operand_b <= registers[opcode[11:8]];
                    compute_of <= 0;
                    state <= ST_EXEC; 
                end
                16'h6???: begin
                   instr.op <= LD; 

                   instr.src <= BYTE;
                   instr.src_byte <= {4'h00, opcode[7:0]};

                   instr.dst <= REG;
                   instr.dst_reg <= opcode[11:8];

                   state <= ST_EXEC;
                end
                16'h7???: begin
                    instr.op <= ALU;

                    instr.src <= BYTE;

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];

                    instr.alu_i.op <= structs::ADD;
                    instr.alu_i.operand_a <= opcode[7:0];
                    instr.alu_i.operand_b <= registers[opcode[11:8]];
                    compute_of <= 0;

                    state <= ST_EXEC;
                end
                16'h8??0: begin
                    instr.op <= LD;

                    instr.src <= REG;
                    instr.src_reg <= opcode[7:4];

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];

                    state <= ST_EXEC;
                end
                16'h8??1: begin
                    instr.op <= ALU;

                    instr.src <= BYTE;

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];
                    
                    instr.alu_i.op <= structs::OR;
                    instr.alu_i.operand_a <= registers[opcode[7:4]];
                    instr.alu_i.operand_b <= registers[opcode[11:8]];
                    compute_of <= 1;

                    state <= ST_EXEC;
                end
                16'h8??2: begin
                    instr.op <= ALU;

                    instr.src <= BYTE;

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];
                    
                    instr.alu_i.op <= structs::AND;
                    instr.alu_i.operand_a <= registers[opcode[7:4]];
                    instr.alu_i.operand_b <= registers[opcode[11:8]];
                    compute_of <= 1;

                    state <= ST_EXEC;
                end
                16'h8??3: begin
                    instr.op <= ALU;

                    instr.src <= BYTE;

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];
                    
                    instr.alu_i.op <= structs::XOR;
                    instr.alu_i.operand_a <= registers[opcode[7:4]];
                    instr.alu_i.operand_b <= registers[opcode[11:8]];
                    compute_of <= 1;

                    state <= ST_EXEC;
                end
                16'h8??4: begin
                    instr.op <= ALU;

                    instr.src <= BYTE;

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];
                    
                    instr.alu_i.op <= structs::ADD;
                    instr.alu_i.operand_a <= registers[opcode[7:4]];
                    instr.alu_i.operand_b <= registers[opcode[11:8]];
                    compute_of <= 1;

                    state <= ST_EXEC;
                end
                16'h8??5: begin
                    instr.op <= ALU;

                    instr.src <= BYTE;

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];
                    
                    instr.alu_i.op <= structs::SUB;
                    instr.alu_i.operand_a <= registers[opcode[11:8]];
                    instr.alu_i.operand_b <= registers[opcode[7:4]];
                    compute_of <= 1;

                    state <= ST_EXEC;
                end
                16'h8??6: begin
                    instr.op <= ALU;

                    instr.src <= BYTE;

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];
                    
                    instr.alu_i.op <= structs::SHR;
                    instr.alu_i.operand_a <= registers[opcode[11:8]];
                    instr.alu_i.operand_b <= 1;
                    compute_of <= 1;

                    state <= ST_EXEC;
                end
                16'h8??7: begin
                    instr.op <= ALU;

                    instr.src <= BYTE;

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];
                    
                    instr.alu_i.op <= structs::SUB;
                    instr.alu_i.operand_a <= registers[opcode[7:4]];
                    instr.alu_i.operand_b <= registers[opcode[11:8]];
                    compute_of <= 1;

                    state <= ST_EXEC;
                end
                16'h8??E: begin
                    instr.op <= ALU;

                    instr.src <= BYTE;

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];
                    
                    instr.alu_i.op <= structs::SHL;
                    instr.alu_i.operand_a <= registers[opcode[11:8]];
                    instr.alu_i.operand_b <= 1;
                    compute_of <= 1;

                    state <= ST_EXEC;
                end
                16'h9??0: begin
                    instr.op <= CALU;
                    instr.alu_i.op <= structs::SNE;
                    instr.alu_i.operand_a <= registers[opcode[7:4]];
                    instr.alu_i.operand_b <= registers[opcode[11:8]];
                    compute_of <= 0;
                    state <= ST_EXEC; 
                end
                16'hA???: begin
                   instr.op <= LD; 

                   instr.src <= BYTE;
                   instr.src_byte <= opcode[11:0];

                   instr.dst <= IDX_REG;

                   state <= ST_EXEC;
                end
                16'hB???: begin
                    instr.op <= ALUJ; 

                    instr.op <= CALU;
                    instr.alu_i.op <= structs::ADDL;
                    instr.alu_i.operand_a <= registers[0];
                    instr.alu_i.operand_b_long <= opcode[11:0];
                    compute_of <= 0;
                    state <= ST_EXEC; 
                end
                16'hD???: begin
                   instr.op <= DRW; 

                   instr.src <= SPRITE_MEM;
                   instr.src_sprite_sz <= {1'b0, opcode[3:0]};
                   instr.src_sprite_addr <= index_reg[11:0];
                   instr.src_sprite_vx <= opcode[11:8];
                   instr.src_sprite_vy <= opcode[7:4];
                   instr.src_sprite_idx <= 0;

                   state <= ST_FETCH_MEM;
                end
                16'hE?9E: begin
                    instr.op <= IOJ; 
                    instr.src <=  KEY;
                    instr.src_key <= registers[opcode[11:8]][3:0];

                    state <= ST_EXEC;
                end
                16'hE?A1: begin
                    instr.op <= NIOJ; 
                    instr.src <=  KEY;
                    instr.src_key <= registers[opcode[11:8]][3:0];

                    state <= ST_EXEC;
                end
                16'hF?07: begin 
                    instr.op <= LD;

                    instr.src <= DELAY_TIMER;

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];

                    state <= ST_EXEC;
                end
                16'hF?0A: begin 
                        $display("IO waiting");
                    instr.op <= IOW;

                    instr.src <= KEY;

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];

                    state <= ST_EXEC;
                end
                16'hF?15: begin 
                    instr.op <= LD;

                    instr.src <= REG;
                    instr.src_reg <= opcode[11:8];

                    instr.dst <= DELAY_TIMER;

                    state <= ST_EXEC;
                end
                16'hF?18: begin 
                    instr.op <= LD;

                    instr.src <= REG;
                    instr.src_reg <= opcode[11:8];

                    instr.dst <= SOUND_TIMER;

                    state <= ST_EXEC;
                end
                16'hF?1E: begin 
                    instr.op <= ALU;

                    instr.src <= BYTE;

                    instr.dst <= IDX_REG;

                    instr.alu_i.op <= structs::ADDL;
                    instr.alu_i.operand_a <= registers[opcode[11:8]];
                    instr.alu_i.operand_b_long <= index_reg[11:0]; 
                    compute_of <= 0;

                    state <= ST_EXEC;
                end
                16'hF?29: begin 
                    instr.op <= LD;

                    instr.src <= BYTE;
                    instr.src_byte <= registers[opcode[11:8]] * 5;

                    instr.dst <= IDX_REG;

                    state <= ST_EXEC;
                end
                16'hF?33: begin 
                    instr.op <= BCD;

                    instr.src <= REG;
                    instr.src_reg <= opcode[11:8];

                    instr.dst <= MEM;
                    instr.dst_addr <= index_reg[11:0];

                    ldl_cnt <= 0;

                    state <= ST_EXEC;
                end
                16'hF?55: begin
                    instr.op <= LDL; 

                    instr.src <= REG;
                    instr.src_reg <= opcode[11:8]; //FIXME: need to expand mem?

                    instr.dst <= MEM;
/* verilator lint_off WIDTHEXPAND */
                    instr.dst_addr <= index_reg[11:0] + opcode[11:8] + 1; //FIXME: need to expand mem?

                    /* verilator lint_off WIDTHEXPAND */
                    ldl_cnt <= opcode[11:8];

                    state <= ST_EXEC;
                end
                16'hF?65: begin
                    instr.op <= LDL; 

                    instr.src <= MEM;
/* verilator lint_off WIDTHEXPAND */
                    instr.src_addr <= index_reg[11:0] + opcode[11:8]; //FIXME: need to expand mem?

                    instr.dst <= REG;
                    instr.dst_reg <= opcode[11:8];

                    state <= ST_FETCH_MEM;
                end
                default: begin
                    $display("ILLEGAL INSTRUCTION %h at PC 0x%h (%0d)", opcode, program_counter, program_counter);
                    state <= ST_HALT;
                end
            endcase
        end

        ST_FETCH_MEM: begin
            if (instr.src == MEM) begin
                if (rd_memory_address == instr.src_addr) begin
                    instr.src_byte <= { 4'h0, rd_memory_data};
                    instr.src <= BYTE;
                    state <= ST_EXEC;
                end else begin
                    rd_memory_address <= instr.src_addr;
                end
            end

            if (instr.src == SPRITE_MEM) begin
                if (instr.src_sprite_idx == 0) begin
                    rd_memory_address <= instr.src_sprite_addr + {7'b0000000, instr.src_sprite_idx}; 
                    instr.src_sprite_idx <= instr.src_sprite_idx + 1;
                end else if (instr.src_sprite_idx <= instr.src_sprite_sz) begin
                    rd_memory_address <= instr.src_sprite_addr + {7'b0000000, instr.src_sprite_idx}; 
                    instr.src_sprite_idx <= instr.src_sprite_idx + 1;
                    for (int l = 0; l < 8; l++) 
                        instr.src_sprite[(instr.src_sprite_idx)*8+l] <= rd_memory_data[7-l];
                end else begin
                    instr.src_sprite_x <= registers[instr.src_sprite_vx] % 8'd64;
                    instr.src_sprite_y <= registers[instr.src_sprite_vy] % 8'd32;
                    state <= ST_DRAW;
                    draw_state.stage <= INIT;
                end
            end
        end

        ST_HALT: begin end

        ST_DRAW: begin
            if (draw_state.stage == INIT) begin
                draw_state.x <= instr.src_sprite_x;
                draw_state.y <= instr.src_sprite_y;

                draw_state.r <= 0;
                draw_state.c <= 0;

                draw_state.stage <= DRAW;  
                registers[15] <= 0;
            end else begin
                if (draw_state.r == instr.src_sprite_sz + 1) begin
                    state <= ST_CLEANUP; 
                    program_counter <= program_counter + 2;
                end else begin
                    if (draw_state.c == 5'd8) begin
                        draw_state.c <= 0;
                        draw_state.r <= draw_state.r + 1;
                    end else begin
                        /* verilator lint_off WIDTHEXPAND */
                        if (draw_state.r + instr.src_sprite_y < 32 && draw_state.c + instr.src_sprite_x < 64) begin
`define DRAW_PX ((draw_state.r + instr.src_sprite_y)*64 + (draw_state.c + instr.src_sprite_x))
                           
                            /* verilator lint_off WIDTHEXPAND */
                            if (instr.src_sprite[(draw_state.r*8) + draw_state.c]) begin
                                write_pixels(draw_state.c + instr.src_sprite_x, draw_state.r + instr.src_sprite_y);
                            end
                        end
                        draw_state.c <= draw_state.c + 1; 
                    end
                end
                
            end
        end

        ST_EXEC: begin
            case (instr.op) 
                LD: begin
                    if (instr.src == REG) begin
                        instr.src_byte <= { 4'h0, registers[instr.src_reg] };
                        instr.src <= BYTE;
                    end else if (instr.src == DELAY_TIMER) begin
                        instr.src_byte <= { 4'h0, delay_timer };
                        instr.src <= BYTE;
                    end   
                end
                LDL: begin
                    if (instr.dst == REG) begin
                        registers[instr.dst_reg] <= instr.src_byte[7:0];

                        if (instr.dst_reg == 0) begin
                            program_counter <= program_counter + 2;
                            state <= ST_CLEANUP;
                        end else begin
                            instr.src <= MEM;
                            instr.dst_reg <= instr.dst_reg - 1;
                            instr.src_addr <= instr.src_addr - 1;
                            state <= ST_FETCH_MEM;
                        end
                    end
                    if (instr.dst == MEM) begin
                        instr.src <= BYTE;

                        instr.src_byte <= {4'h0, registers[instr.src_reg]};
                        instr.src_reg <= instr.src_reg - 1;
                        instr.dst_addr <= instr.dst_addr - 1;
                        ldl_cnt <= ldl_cnt - 1;


                        if (ldl_cnt > 15) begin
                            program_counter <= program_counter + 2;
                        //    state <= ST_HALT;
                            state <= ST_CLEANUP;
                        end else begin
                            state <= ST_WB;
                        end
                    end
                end
                BCD: begin 
                    instr.src <= BYTE;
                    ldl_cnt <= ldl_cnt + 1;
                    $display("%0d ldl", ldl_cnt);
                    case (ldl_cnt) 
                       0: begin 
                            instr.src_byte <= (registers[instr.src_reg]/100) % 10;
                            state <= ST_WB;
                       end
                       1:  begin 
                            instr.dst_addr <= instr.dst_addr + 1;
                            instr.src_byte <= (registers[instr.src_reg]/10) % 10;
                            state <= ST_WB;
                       end
                       2: begin 
                            instr.dst_addr <= instr.dst_addr + 1;
                            instr.src_byte <= registers[instr.src_reg] % 10;
                            state <= ST_WB;
                       end
                       3: begin 
                       program_counter <= program_counter + 2;
                            state <= ST_CLEANUP;
                        end
                    endcase
                end
                JP: begin
                   program_counter <= {4'h00, instr.src_byte}; 
                   state <= ST_CLEANUP;
                end
                CALU,
                ALUJ,
                ALU: begin
                    alu_rst <= 0;
                    if (alu_done) begin
                        instr.src <= BYTE;
                        if (instr.dst == IDX_REG) 
                            instr.src_byte <= alu_result_long[11:0];
                        else if (instr.dst_reg != 15 || !compute_of) begin 
                            instr.src_byte <= alu_result;
                        end else begin
                            instr.src_byte <= alu_overflow;
                        end

                        registers[15] <= compute_of ? alu_overflow : registers[15];
                        if (instr.op == ALU) begin
                            state <= ST_WB;
                            program_counter <= program_counter + 2;
                        end else if (instr.op == CALU) begin
                            state <= ST_CLEANUP;
                            if (|alu_result) begin
                                program_counter <= program_counter + 4;
                            end else begin
                                program_counter <= program_counter + 2;
                            end
                        end else begin
                            $display("Untested!");
                            state <= ST_CLEANUP;
                            program_counter <= alu_result_long;
                        end
                    end
                end
                CALL: begin
                    stack[stack_pointer] <= program_counter;
                    stack_pointer <= stack_pointer + 1;
                    program_counter <= instr.src_byte;
                    state <= ST_CLEANUP;
                end
                RET: begin
                    stack_pointer <= stack_pointer - 1;
                    program_counter <= stack[stack_pointer-1] + 2;
                    state <= ST_CLEANUP;
                end
                IOJ: begin
                    if (keymap[instr.src_key] == 1) begin
                        program_counter <= program_counter + 4;
                    end else begin
                        program_counter <= program_counter + 2;
                    end
                    state <= ST_CLEANUP;
                end
                NIOJ: begin
                    if (keymap[instr.src_key] != 1) begin
                        program_counter <= program_counter + 4;
                    end else begin
                        program_counter <= program_counter + 2;
                    end
                    state <= ST_CLEANUP;
                end
                IOW: begin
                    if (|keymap != 0) begin
                        $display("IO not waiting");
                        for(int m = 0; m < 16; m++) begin
                            if (keymap[m])
                                instr.src_byte <= m[11:0];
                        end
                        program_counter <= program_counter + 2;
                        state <= ST_WB;
                        instr.src <= BYTE;
                    end
                end
                CLS: begin
                    if (clr_cnt == 1024) begin
                        state <= ST_CLEANUP;
                        program_counter <= program_counter + 2;
                    end else begin
                        clr_cnt <= clr_cnt + 1;
                        vram[clr_cnt] <= 0;
                    end
                end

            endcase

            case (instr.op) 
                LD,
                DRW: begin
                    
                    program_counter <= program_counter + 2;
                    state <= ST_WB; 
                end
            endcase
        end

        ST_WB: begin
            if (instr.src != BYTE)
                $fatal();

            case (instr.dst) 
                MEM: begin
                   wr_memory_address <= instr.dst_addr;
                   wr_memory_data <= instr.src_byte[7:0];
                   wr_go <= 1'b1;
                end
                REG: registers[instr.dst_reg] <= instr.src_byte[7:0];
                IDX_REG: index_reg <= {4'h0, instr.src_byte};
                DELAY_TIMER: delay_timer <= instr.src_byte[7:0];
                SOUND_TIMER: sound_timer <= instr.src_byte[7:0];
            endcase 

            if (instr.op != LDL && instr.op != BCD)
                state <= ST_CLEANUP;
            else  begin
                state <= ST_EXEC;
                instr.src <= REG;
            end
        end

        ST_CLEANUP: begin
           wr_go <= 0; 
           state <= ST_FETCH_HI;
           alu_rst <= 1;
        end
    endcase

    if (debug_overlay) begin
        for(int w = 0; w < 16; w++) begin
            vram[16+w] <= keymap[w] ? 8'hff : 0;
        end
    
        for (int z = 0; z < 4; z++) begin
            vram[32 + z] = col[z] ? 8'hff : 0;
            vram[64 + z] = row[z] ? 8'hff : 0;
        end
    end

    cycle_counter <= cycle_counter + 1;
  end
endmodule
