package structs;

  typedef enum {
    ADD,
    ADDL,
    SUB,
    SE,
    SNE,
    OR,
    AND,
    XOR,
    SHR,
    SHL
  } alu_op;

  typedef struct packed {
    logic [7:0] operand_a;
    logic [7:0] operand_b;
    logic [11:0] operand_b_long;
    alu_op op;
  } alu_input;

endpackage
