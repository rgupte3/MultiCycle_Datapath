-- ECE 3056: Architecture, Concurrency and Energy in Computation
-- Sudhakar Yalamanchili
-- Multicycle MIPS Processor VHDL Behavioral Model
--			
--  Idecode module (implements the register file)
--
-- School of Electrical & Computer Engineering
-- Georgia Institute of Technology
-- Atlanta, GA 30332
-- 
-- Name: Ria Gupte
-- GT Id: 902758920
-- GT Username: rgupte3
-- Changes made: write_register_address_2 was added which take the rs value.
-- the mux for write_register was changed. RegDst is now a 2 bit select value.
-- some registers were also initialised to values used in the instructions.
--
LIBRARY IEEE; 			
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY Idecode IS
	  PORT(	        read_data_1	: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			read_data_2	: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Sign_extend     : OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );

			Instruction     : IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			read_data 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			ALU_result	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			RegWrite 	: IN 	STD_LOGIC;
			MemtoReg 	: IN 	STD_LOGIC;
			RegDst 		: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			clock,reset	: IN 	STD_LOGIC );
END Idecode;										   


ARCHITECTURE behavior OF Idecode IS
TYPE register_file IS ARRAY ( 0 TO 31 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );

	SIGNAL register_array		       	: register_file;
	SIGNAL write_register_address 		: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL write_data	      		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_register_1_address		: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL read_register_2_address		: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL write_register_address_1		: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL write_register_address_0		: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL write_register_address_2		: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL Instruction_immediate_value	: STD_LOGIC_VECTOR( 15 DOWNTO 0 );

BEGIN
        -- add write_register_2 to write back the value to rs in a swa instruction
	read_register_1_address 	<= Instruction( 25 DOWNTO 21 );
   	read_register_2_address 	<= Instruction( 20 DOWNTO 16 );
	write_register_address_2        <= Instruction( 25 DOWNTO 21 ); 
   	write_register_address_1	<= Instruction( 15 DOWNTO 11 );
   	write_register_address_0 	<= Instruction( 20 DOWNTO 16 );
   	Instruction_immediate_value 	<= Instruction( 15 DOWNTO 0 );
	
					-- Mux for Register Write Address. RegDst is now a 2 bit select value
    	write_register_address <= write_register_address_1 WHEN RegDst = "01"  ELSE 
				write_register_address_0 when RegDst ="00" else
				write_register_address_2 when RegDst = "10";

					-- Mux to bypass data memory for Rformat instructions
	write_data <= ALU_result( 31 DOWNTO 0 ) 
			WHEN ( MemtoReg = '0' ) 	ELSE read_data;

					-- Sign Extend 16-bits to 32-bits
    	Sign_extend <= X"0000" & Instruction_immediate_value
		WHEN Instruction_immediate_value(15) = '0'
		ELSE	X"FFFF" & Instruction_immediate_value;

PROCESS
	BEGIN
		WAIT UNTIL (rising_edge(clock));
		IF reset = '1' THEN
					-- Initial register values on reset are register = reg#
					-- use loop to automatically generate reset logic 
					-- for all registers
			FOR i IN 0 TO 31 LOOP
				register_array(i) <= CONV_STD_LOGIC_VECTOR( i, 32 );
 			END LOOP;
                -- initialise some register values used in the fetch code.
			register_array(1) <= X"00000000";
			register_array(9) <= X"00000002";
			register_array(10) <= X"00000000";
			register_array(11) <= X"00000001";
			register_array(12) <= X"00000004";
			 read_data_1 <= X"00000000";
			 read_data_2 <= X"00000000";
					-- Write back to register - don't write to register 0
  		ELSE
  		IF RegWrite = '1' AND write_register_address /= 0 THEN
		      register_array( CONV_INTEGER(write_register_address)) <= write_data;
		END IF;
						-- Read Register 1 Operation
	read_data_1 <= register_array( 
			      CONV_INTEGER( read_register_1_address ) );
					-- Read Register 2 Operation		 
	read_data_2 <= register_array( 
			      CONV_INTEGER( read_register_2_address ) );
	end if; 
	END PROCESS;
END behavior;


