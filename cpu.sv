module cpu (
    input wire clk_in,
    input wire [7:0] rd_memory_data,
    output int cycle_counter,
    output logic [11:0] rd_memory_address,
    output logic [11:0] wr_memory_address,
    output logic [7:0] wr_memory_data,
    output logic wr_go,
    output logic lcd_clk,
    output logic lcd_data,
    output logic [5:0] led
);

  logic [7:0] vram [0:1023];

`ifdef DUMMY_GPU
  gpu gpu(
`endif
`ifndef DUMMY_GPU
  st7920_serial_driver gpu(
`endif
      clk_in,
      1'b1,
      vram,
      lcd_clk,
      lcd_data,
      led
);

  task write_pixels;
    input [31:0] x;
    input [31:0] y;

    begin
        // bottom left
        `define BLP ((y*128*2) + x*2 +127)
        if (vram[`BLP/8][7-(`BLP%8)] == 1) begin
          registers[15] <= 1;
        end
        vram[`BLP/8][7-(`BLP%8)] <= 1;      

        // bottom right
        `define BRP ((y*128*2) + x*2 +128)
        vram[`BRP/8][7-(`BRP%8)] <= 1;      

        // top left
        `define TLP ((y*128*2) + x*2-1)
        vram[`TLP/8][7-(`TLP%8)] <= 1;      

        // top right
        `define TRP ((y*128*2) + x*2)
        vram[`TRP/8][7-(`TRP%8)] <= 1;      
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
  

  typedef enum {ST_FETCH_HI, ST_FETCH_LO, ST_FETCH_LO2, ST_DECODE, ST_EXEC, ST_DRAW, ST_FETCH_MEM, ST_WB, ST_CLEANUP, ST_HALT} cpu_state;
  cpu_state state;
  
  typedef enum {INIT, DRAW} draw_stage;
  
  typedef enum {CLS, LD, DRW, JP} cpu_opcode;
  typedef enum {REG, IDX_REG, BYTE, MEM, SPRITE_MEM} data_type;

  struct {
      draw_stage stage;
      logic [4:0] r;
      logic [4:0] c;
      logic [7:0] x;
      logic [7:0] y;
  } draw_state;


  struct {
      cpu_opcode op;
      data_type src;
      data_type dst;

      logic [3:0] dst_reg;
      logic [3:0] src_reg;
      
      logic [11:0] src_byte;

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
    for (int i = 0; i < 2048; i++) begin
        vram[i] = 0;
    end
  end

  always_ff @(posedge clk_in) begin
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
            $display("CPU    : Opcode HI is %h", rd_memory_data);
            state <= ST_FETCH_LO2;
        end

        ST_FETCH_LO2: begin
            opcode <= { opcode[15:8], rd_memory_data};
            $display("CPU    : Opcode LO is %h", rd_memory_data);
            state <= ST_DECODE;
        end

        ST_DECODE: begin
            casez (opcode)
                16'h00E0: begin
                   instr.op <= CLS;
                   state <= ST_CLEANUP;
                   program_counter <= program_counter + 2;
                end
                16'h1???: begin
                    instr.op <= JP;
                    instr.src_byte <= opcode[11:0];
                    state <= ST_EXEC;
                end
                16'h6???: begin
                   $display("Instruction is LD Vx, Byte"); 
                   instr.op <= LD; 

                   instr.src <= BYTE;
                   instr.src_byte <= {4'h00, opcode[7:0]};

                   instr.dst <= REG;
                   instr.dst_reg <= opcode[11:8];

                   state <= ST_EXEC;
                end
                16'hA???: begin
                   $display("Instruction is LD I, Byte"); 
                   instr.op <= LD; 

                   instr.src <= BYTE;
                   instr.src_byte <= opcode[11:0];

                   instr.dst <= IDX_REG;

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
                default: begin
                    $display("ILLEGAL INSTRUCTION %h at PC 0x%h (%0d)", opcode, program_counter, program_counter);
                   $fatal(); 
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
                    $display("%b", rd_memory_data);
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
                    $display("sprite is %0d big at coord %d %d sprite=%b idx=%0d", instr.src_sprite_sz, instr.src_sprite_x, instr.src_sprite_y, instr.src_sprite, instr.src_sprite_addr);
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
            $display("CPU    : IN EXEC");
            case (instr.op) 
                LD: begin
                    if (instr.src == REG) begin
                        instr.src_byte <= { 4'h0, registers[instr.src_reg] };
                        instr.src <= BYTE;
                    end
                end
                JP: begin
                   program_counter <= {4'h00, instr.src_byte}; 
                   state <= ST_CLEANUP;
                end
            endcase

            case (instr.op) 
                LD,
                DRW,
                CLS: begin
                    
                    program_counter <= program_counter + 2;
                    state <= ST_WB; 
                end
            endcase
        end

        ST_WB: begin
            $display("CPU    : IN WB");
            if (instr.src != BYTE)
                $fatal();

            case (instr.dst) 
                MEM: begin
                   wr_memory_address <= instr.dst_addr;
                   wr_memory_data <= instr.src_byte[7:0];
                   wr_go <= 1'b1;
                   $display("writing back byte %b to %h", instr.src_byte, instr.dst_addr);
                end
                REG: registers[instr.dst_reg] <= instr.src_byte[7:0];
                IDX_REG: index_reg <= {4'h0, instr.src_byte};
            endcase 

            state <= ST_CLEANUP;
        end

        ST_CLEANUP: begin
           wr_go <= 0; 
           state <= ST_FETCH_HI;
        end
    endcase

    cycle_counter <= cycle_counter + 1;
  end
endmodule
