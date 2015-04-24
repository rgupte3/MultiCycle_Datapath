-- ECE 3056: Architecture, Concurrency and Energy in Computation
-- Sudhakar Yalamanchili
-- Multicycle MIPS Processor VHDL Behavioral Model
--
-- Ifetch module (provides the PC, instruction, and data memory) 
-- 
-- School of Electrical & Computer Engineering
-- Georgia Institute of Technology
-- Atlanta, GA 30332
--
-- Name: Ria Gupte
-- GT Id: 902758920
-- GT Username: rgupte3
-- Changes made: The instruction data memory was changed to the test program given
-- 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY Ifetch IS
	PORT(	-- Input signals
        	SIGNAL PC_Plus_4	       	: IN STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	SIGNAL Branch_PC            	: in STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	SIGNAL PCWrite, PCWriteCond, IRWrite : IN STD_LOGIC;
        	SIGNAL PCSource 	       	: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        	SIGNAL Zero, MemRead, MemWrite, IorD  : in STD_LOGIC;
        	SIGNAL clock, reset 		: IN STD_LOGIC;
        	SIGNAL memory_data_in   	: IN std_logic_vector(31 downto 0);
        	SIGNAL memory_addr_in   	: IN std_logic_vector(31 downto 0);
        	-- Output signals
        	SIGNAL PC_out 			: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	SIGNAL Memory_data_out 		: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	SIGNAL Instruction 		: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 ));
END Ifetch;
														   
ARCHITECTURE behavior OF Ifetch IS
   TYPE INST_MEM IS ARRAY (0 to 7) of STD_LOGIC_VECTOR (31 DOWNTO 0);
   SIGNAL iram : INST_MEM := (
      X"00006820", -- add $t5, $0, $0
      X"01aa6820", -- add $t5, $t5, $t2
      X"01a96820", -- add $t5, $t5, $t1
      X"a98d0000", -- swa  $t5, 0($t4)++
      X"014b5020", -- add $t2, $t2, $t3
      X"1000fffa", -- beq  $0, $0, loop  
      X"00000000",    --
      X"00000000"
                     
   );
    
     TYPE DATA_RAM IS ARRAY (0 to 31) OF STD_LOGIC_VECTOR (31 DOWNTO 0);
   SIGNAL dram: DATA_RAM := (
      X"00000000",
      X"11111111",
      X"22222222",
      X"33333333",
      X"44444444",
      X"55555555",
      X"66666666",
      X"77777777",
      X"0000000A",
      X"1111111A",
      X"2222222A",
      X"3333333A",
      X"4444444A",
      X"5555555A",
      X"6666666A",
      X"7777777A",
      X"0000000B",
      X"1111111B",
      X"2222222B",
      X"3333333B",
      X"4444444B",
      X"5555555B",
      X"6666666B",
      X"7777777B",
      X"000000BA",
      X"111111BA",
      X"222222BA",
      X"333333BA",
      X"444444BA",
      X"555555BA",
      X"666666BA",
      X"777777BA"
   );
	SIGNAL PC, Next_PC, Jump_PC	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL PC_Update 			: boolean; 
	SIGNAL Local_IR, Local_Data 	: std_logic_vector(31 downto 0);
BEGIN 						
					             
Local_IR <=  iram(CONV_INTEGER(PC(4 downto 2)))when IorD ='0' 
           else X"0000FFFF"; -- read instr pointed to by PC
Local_data <= dram(CONV_INTEGER(memory_addr_in(6 downto 2))) when IorD ='1'
           else X"0000AAAA"; --read data from data addr		
	
Jump_PC <= "0000" & Local_IR(25 downto 0) & "00"; -- compute jump address
			   
-- compute value of next PC

Next_PC <=  PC_Plus_4    when PCSource = "00" else
            Branch_PC    when PCSource = "01" else
            Jump_PC      when PCSource = "10" else
            X"CCCCCCCC";
			   
-- check if the PC is to be updated on the next clock cycle
PC_Update <= ((PCWrite = '1') or ((PCWriteCond = '1') and (Zero ='1')));
	PROCESS
		BEGIN
			WAIT UNTIL (rising_edge(clock));
			IF (reset = '1') THEN
				PC<= X"00000000" ;
				pc_out <= x"00000000"; 
				Instruction <= x"00000000";
				Memory_data_out <= X"00000000";
			ELSE 
				if (PC_update) then 
					
						PC      <= next_PC; 	 
						PC_out  <= next_PC;
				end if;
			      if (IRWrite ='1') then Instruction <= Local_IR; end if;
			      IF (MemRead = '1')then Memory_data_out <= Local_Data; end if;
			      if (MemWrite = '1') then dram(CONV_INTEGER(memory_addr_in(6 downto 2))) 
			                              <= memory_data_in; end if;
			  	
			 end if; 
			  
	END PROCESS; 
			 
END behavior;


