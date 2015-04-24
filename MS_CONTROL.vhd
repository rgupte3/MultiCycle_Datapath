-- ECE 3056: Architecture, Concurrency and Energy in Computation
-- Sudhakar Yalamanchili
-- Multicycle MIPS Processor VHDL Behavioral Modell
--		
-- control module (implements MIPS control unit)
--
-- School of Electrical & Computer Engineering
-- Georgia Institute of Technology
-- Atlanta, GA 30332
--
-- Name: Ria Gupte
-- GT Id: 902758920
-- GT Username: rgupte3
-- Changes made: The ROM table was changed completely as two more bits were added.
-- swa is set to be one when 101010 is the opcode.
-- the control signals were adjusted according to the bits added.
-- the swa instruction follows this path: 0-1-10-11-12-2-5
-- 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY control IS
   PORT( 	-- INPUT SIGNALS
	SIGNAL Opcode 		: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
	SIGNAL clock, reset	: IN 	STD_LOGIC;
	 
	 -- OUTPUT SIGNALS
	SIGNAL PCWrite     : OUT STD_LOGIC;
   	SIGNAL PCWriteCond : OUT STD_LOGIC;
   	SIGNAL IorD        : OUT STD_LOGIC;
   	SIGNAL MemRead 	   : OUT STD_LOGIC;
  	SIGNAL MemWrite	   : OUT STD_LOGIC;
   	SIGNAL IRWrite     : OUT STD_LOGIC;
   	SIGNAL MemtoReg    : OUT STD_LOGIC;
   	SIGNAL PCSource    : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);			 
   	SIGNAL ALUOp       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
   	SIGNAL ALUSrcB 	   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
   	SIGNAL ALUSrcA     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
   	SIGNAL RegWrite	   : OUT STD_LOGIC;
   	SIGNAL RegDst      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
   	SIGNAL micropc	   : OUT integer);

END control;

ARCHITECTURE behavior OF control IS
    -- Implementation of the microcode ROM
    -- Added 3 more states in the ROM table
TYPE ROM_MEM IS ARRAY (0 to 12) of STD_LOGIC_VECTOR (23 DOWNTO 0);
   SIGNAL   IROM : ROM_MEM := (
    X"250203",   -- fetch  
    X"000601",   -- decode 
    X"000482",   -- memory address 
    X"0C0003",   -- memory load  
    X"008040",   -- memory writeback 
    X"0A0000",   -- memory store 
    X"001083",   -- rformat execution 
    X"000050",   -- rformat writeback 
    X"102880",   -- BEQ  
    X"204000",   -- jump  
    X"000283",   -- rs+4
    X"000063",   -- WB to rs
    X"000604"    -- decode again and go to state 2
	
   );
    
    SIGNAL addr_control 		: std_logic_vector(3 downto 0); 
    SIGNAL microinstruction 		: std_logic_vector(23 downto 0);
    SIGNAL  R_format, Lw, Sw, Beq, Swa 	: STD_LOGIC;
    SIGNAL dispatch_1, dispatch_2, next_micro : integer; 
BEGIN    

-- record the type of instruction
R_format 	  <=  '1'  WHEN  Opcode = "000000"  ELSE '0';
Lw            <=  '1'  WHEN  Opcode = "100011"  ELSE '0';
Sw            <=  '1'  WHEN  Opcode = "101011"  ELSE '0';
Swa            <=  '1'  WHEN  Opcode = "101010"  ELSE '0';
Beq           <=  '1'  WHEN  Opcode = "000100"  ELSE '0';

-- Implementation of dispatch table 1
dispatch_1  <= 6 when R_format = '1' else
            8 when Beq = '1' else
            2 when (LW = '1') or (SW = '1') else
	    10 when (Swa = '1') else
            0;

-- Implementation of dispatch table 2
dispatch_2 <= 5 when (SW = '1') or (Swa = '1') else 3;


microinstruction <= IROM(next_micro) when next_micro >= 0 else X"123450";

-- The bits were rearranged to make up for the bits added in the microinstruction. 

PCWrite        <= microinstruction(21);
PCWriteCond    <= microinstruction(20);
IorD           <= microinstruction(19);
MemRead        <= microinstruction(18);
MemWrite       <= microinstruction(17);
IRWrite        <= microinstruction(16);
MemtoReg       <= microinstruction(15);
PCSource       <= microinstruction(14 downto 13);
ALUOp          <= microinstruction(12 downto 11);
ALUSrcB        <= microinstruction(10 downto 9);
ALUSrcA        <= microinstruction(8 downto 7);
RegWrite       <= microinstruction(6);
RegDst         <= microinstruction(5 downto 4);
addr_control   <= microinstruction(3 downto 0); 

micropc <= next_micro;

process
    -- implement the microcode interpreter loop
    begin
        wait until (rising_edge(clock));
        if (reset = '1') then
            next_micro <= 0;
            else
    -- select the next microinstruction
    -- next instruction is set to be 2 when addr_control is 0100.
            case addr_control is
            when "0000" => next_micro <= 0;
            when "0001" => next_micro <= dispatch_1;
            when "0010" => next_micro <= dispatch_2;
            when "0011" => next_micro <= (next_micro + 1);
	    when "0100" => next_micro <= 2;
            when others => next_micro <= 0;
        end case;
    end if;
    end process; 


   END behavior;


