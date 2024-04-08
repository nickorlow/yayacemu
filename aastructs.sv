package structs;

    typedef enum {ADD} alu_op;
    
    typedef struct {
        logic [7:0] operand_a;
        logic [7:0] operand_b;
        alu_op op;
    } alu_input;

endpackage
