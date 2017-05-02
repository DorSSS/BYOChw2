--
-- 
-- This module is the Fetch Unit
--  
--
--   
--
--
----------------------------------------------------------------------------------
library IEEE ;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- ************************************************************************************************
-- ************************************************************************************************

entity mux_4to1_32 is
    Port ( in0 	 		: in   STD_LOGIC_VECTOR(31 downto 0);
			  in1 	 		: in   STD_LOGIC_VECTOR(31 downto 0);
			  in2 	 		: in   STD_LOGIC_VECTOR(31 downto 0);
			  in3 	 		: in   STD_LOGIC_VECTOR(31 downto 0);
		     sel 	 		: in   STD_LOGIC_VECTOR(1 downto 0);			  
           out_y			: out  STD_LOGIC_VECTOR(31 downto 0));
end mux_4to1_32;

architecture Behavioral of mux_4to1_32 is

begin
	with sel select 
		out_y  <=
		in0 when "00",
		in1 when "01",
		in2 when "10",
		in3 when others;
end Behavioral;

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity register32 is 
	Port	(	CK_in 				:	in	STD_LOGIC;
				RESET_in			:	in	STD_LOGIC;
				HOLD_in				:	in	STD_LOGIC;
				REGISTER_value_in	:	in	STD_LOGIC_VECTOR(31 downto 0);
				REGISTER_default_val	:	in	STD_LOGIC_VECTOR(31 downto 0);
				REGISTER_out		:	out	STD_LOGIC_VECTOR(31 downto 0));
end register32;

architecture Behavioral of register32 is
	begin
		process(CK_in, RESET_in, HOLD_in)
		begin			
				if RESET_in = '1' and HOLD_in = '0' then											
					REGISTER_out <= REGISTER_default_val;
				elsif CK_in 'event and CK_in = '1' and HOLD_in = '0' then
					REGISTER_out <= REGISTER_value_in;
				end if;			
		end process;
end Behavioral;

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity Fetch_Unit is
Port	(	
--
CK_25MHz 		: in STD_LOGIC;
RESET_in 		: in STD_LOGIC;
HOLD_in 		: in STD_LOGIC;
-- IMem signals
MIPS_IMem_adrs	     : out STD_LOGIC_VECTOR (31 downto 0); 
MIPS_IMem_rd_data     : in STD_LOGIC_VECTOR (31 downto 0); 
--rdbk signals
rdbk0			 :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk1			 :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk2			 :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk3			 :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk4			 :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk5			 :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk6			 :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk7			 :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk8			 :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk9			 :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk10			  :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk11			  :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk12			  :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk13			  :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk14			  :out STD_LOGIC_VECTOR (31 downto 0); 
rdbk15			  :out STD_LOGIC_VECTOR (31 downto 0) 
		);
end Fetch_Unit; 


architecture Behavioral of Fetch_Unit is

component register32 is 
	Port	(	CK_in 				:	in	STD_LOGIC;
				RESET_in			:	in	STD_LOGIC;
				HOLD_in				:	in	STD_LOGIC;
				REGISTER_value_in	:	in	STD_LOGIC_VECTOR(31 downto 0);
				REGISTER_default_val	:	in	STD_LOGIC_VECTOR(31 downto 0);
				REGISTER_out		:	out	STD_LOGIC_VECTOR(31 downto 0));
end component;

component mux_4to1_32 is
    Port ( in0 	 		: in   STD_LOGIC_VECTOR(31 downto 0);
			  in1 	 		: in   STD_LOGIC_VECTOR(31 downto 0);
			  in2 	 		: in   STD_LOGIC_VECTOR(31 downto 0);
			  in3 	 		: in   STD_LOGIC_VECTOR(31 downto 0);
		     sel 	 		: in   STD_LOGIC_VECTOR(1 downto 0);			  
           out_y			: out  STD_LOGIC_VECTOR(31 downto 0));
end component;
-- ***********************************************************************************************
-- ***********************************************************************************************


--- ========================  Host intf signals  =====================================
--====================================================================================
signal  RESET 			:STD_LOGIC;-- is coming directly from the Fetch_Unit_Host_intf
signal  CK 				:STD_LOGIC;-- is coming directly from the Fetch_Unit_Host_intf
signal  HOLD 			:STD_LOGIC;-- is coming directly from the Fetch_Unit_Host_intf
signal	IMem_adrs 		: STD_LOGIC_VECTOR  (31 downto 0);
signal  IMem_rd_data	: STD_LOGIC_VECTOR  (31 downto 0);


-- ========================  MIPS signals  ==========================================
-- ==================================================================================

--=========================== IF phase ==============================================
--===================================================================================
--- IR & related signals
signal  IR_reg			: STD_LOGIC_VECTOR  (31 downto 0) := x"00000000";
signal  imm 			: STD_LOGIC_VECTOR  (15 downto 0);
signal  sext_imm 		: STD_LOGIC_VECTOR  (31 downto 0);
signal  opcode 			: STD_LOGIC_VECTOR  (5 downto 0);
signal  funct 			: STD_LOGIC_VECTOR  (5 downto 0);

-- PC 
signal  PC_reg			: STD_LOGIC_VECTOR  (31 downto 0) := x"00000000";

-- PC_mux
-- control 
signal  PC_Source 		: STD_LOGIC_VECTOR  (1 downto 0);-- 0=PC+4, 1=BRANCH, 2=JR, 3=JUMP 
-- inputs to PC_mux
signal  PC_plus_4 		: STD_LOGIC_VECTOR  (31 downto 0);
signal  jump_adrs 		: STD_LOGIC_VECTOR  (31 downto 0);
signal  branch_adrs 	: STD_LOGIC_VECTOR  (31 downto 0);
signal  jr_adrs 		: STD_LOGIC_VECTOR  (31 downto 0);
-- output
signal  PC_mux_out		: STD_LOGIC_VECTOR  (31 downto 0);


signal  PC_plus_4_pID 	: STD_LOGIC_VECTOR  (31 downto 0);
-- ================== End of MIPS signals ==========================================
-- =================================================================================


-- additional rdbk signals 
signal  rdbk_vec1 		: STD_LOGIC_VECTOR  (31 downto 0);
signal  rdbk_vec2 		: STD_LOGIC_VECTOR  (31 downto 0);




-- ***************************************************************************************************


begin

-- Connecting the Fetch_Unit pins to inner signals
-- =============================================================
-- MIPS signals    [to be used by students]
CK			<=		CK_25MHz;
RESET		<=		RESET_in;
HOLD		<=   	HOLD_in;
MIPS_IMem_adrs 	<=  IMem_adrs;
IMem_rd_data <=		MIPS_IMem_rd_data; 
-- RDBK signals    [to be used by students]
rdbk0 		<= 		PC_reg;
rdbk1 		<= 		PC_plus_4;
rdbk2 		<= 		branch_adrs;
rdbk3 		<= 		jr_adrs;
rdbk4 		<= 		jump_adrs;
rdbk5 		<= 		PC_plus_4_pID;
rdbk6 		<= 		IR_reg;
rdbk7 		<= 		rdbk_vec1;-- PC_source
rdbk8 		<= 		PC_mux_out;
rdbk9 		<= 		x"00000000";
rdbk10 		<= 		x"00000000";
rdbk11 		<= 		x"00000000";
rdbk12 		<= 		x"00000000";
rdbk13 		<= 		x"00000000";
rdbk14 		<= 		x"00000000";
rdbk15 		<= 		x"00000000";
--

-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- your Fetch_Unit code starts here @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

-- INSTRUCTION: You will make sure that all reset signals of all 
-- registers in your design are connected to the MIPS_reset signal

-- ============================= IF phase processes ======================================
-- ========================================= =============================================
--PC register
PC_REG_INST : register32	
	port map(
		CK_in 	=> CK_25MHz,
		RESET_in	=> RESET_in,
		HOLD_in	=> HOLD_in,
		REGISTER_value_in	=> PC_mux_out,
		REGISTER_default_val	=> x"40000000",
		REGISTER_out => PC_reg
	);
	
IMem_adrs <= PC_reg; -- connect PC_reg to IMem

--PC source mux
PC_SRC_MUX	:	mux_4to1_32
		port map(
			in0 => PC_plus_4, 
			in1 => branch_adrs, 
			in2 => x"00400004",
			in3 => jump_adrs,
			sel => PC_source,
			out_y => PC_mux_out );
			
-- PC Adder - incrementing PC by 4  (create the PC_plus_4 signal)
PC_plus_4 <= PC_reg + 4;

-- IR_reg   (rename of the IMem_rd_data signal)
IR_reg <= IMem_rd_data;

-- imm sign extension	  (create the sext_imm signal)
imm <= IR_reg(15 downto 0);
sext_imm <= std_logic_vector(resize(signed(imm), sext_imm'length));

-- BRANCH address  (create the branch_adrs signal)
branch_adrs <= PC_plus_4_pID + (sext_imm(29 downto 0) & b"00"); -- branch_adrs = PC_plus_4_pID + sext_imm*4		

-- JUMP address    (create the jump_adrs signal)
jump_adrs <= PC_plus_4_pID(31 downto 28) & (IR_reg(25 downto 0) & b"00");


-- JR address    (create the jr_adrs signal)  
jr_adrs <= x"00400004";
	
-- PC_plus_4_pID register   (create the PC_plus_4_pID signal)
PC_plus_4_pID_REG : register32
	port map(
		CK_in 	=> CK_25MHz,
		RESET_in	=> RESET_in,
		HOLD_in	=> HOLD_in,
		REGISTER_value_in	=> PC_plus_4,
		REGISTER_default_val	=> x"00000000",
		REGISTER_out => PC_plus_4_pID );
 

-- INSTRUCTION: The MIPS instruction coding is described in Appendix A
-- instruction decoder
opcode <= IR_reg(31 downto 26);
funct  <= IR_reg(5 downto 0);


-- PC_source decoder  (create the PC_source signal)



-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
-- your Fetch_Unit code ends here   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



-- rdbk signals
rdbk_vec1  <=  x"0000000" & b"00" & PC_source;






end Behavioral;

-- ******************************************************************************************
-- ******************************************************************************************




