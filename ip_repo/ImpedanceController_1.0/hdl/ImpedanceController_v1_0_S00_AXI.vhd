library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fpupack.all;

entity ImpedanceController_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here
        --volt2pwm : std_logic_vector(FP_WIDTH-1 downto 0) := "010000110000000000000000000"; -- 1024/8
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
	);
	port (
		-- Users to add ports here
        start    : in std_logic;
        input    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0):= (others => '0');
        x        : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0):= (others => '0');
        xp       : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0):= (others => '0');
        ready    : out std_logic;
        busy     : out std_logic;
        output   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end ImpedanceController_v1_0_S00_AXI;

architecture arch_imp of ImpedanceController_v1_0_S00_AXI is

	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 3;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers 16
	signal slv_reg0	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- 1/M
	signal slv_reg1	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- K
	signal slv_reg2	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- B
	signal slv_reg3	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- P
	signal slv_reg4	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- dt
	signal slv_reg5	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- dt_half
	signal slv_reg6	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- outMax
	signal slv_reg7	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- outMin
	signal slv_reg8	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- setPoint
	signal slv_reg9	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); -- output
	signal slv_reg10	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg11	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg12	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg13	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg14	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg15	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal reg_data_out	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	constant zero_constant	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal byte_index	: integer;
	signal aw_en	: std_logic;

-------------------------------------------------------------------------------------------
	-- User signals 
	signal my_reset    :  std_logic := '0';
	signal reset_proc    :  std_logic := '0';
	signal my_busy     :  std_logic ;
	signal my_ready    :  std_logic ;
    signal my_outMax   :  std_logic_vector(FP_WIDTH-1 downto 0) := "010000010000000000000000000"; --
    signal my_outMin   :  std_logic_vector(FP_WIDTH-1 downto 0) := "110000010000000000000000000"; --
    signal my_M        :  std_logic_vector(FP_WIDTH-1 downto 0) := "001111111111001000111101000"; -- 1/0.5284
    signal my_K        :  std_logic_vector(FP_WIDTH-1 downto 0) := "010000101011000100111100000"; -- 88.6173
    signal my_B        :  std_logic_vector(FP_WIDTH-1 downto 0) := "010000010001100101001000001"; -- 9.5801
    signal my_P        :  std_logic_vector(FP_WIDTH-1 downto 0) := "001111110000000100100000010"; -- 0.504
    signal my_dt       :  std_logic_vector(FP_WIDTH-1 downto 0) := "001110111010001111010111000";   -- dt = 0.005 
    signal my_dt_half  :  std_logic_vector(FP_WIDTH-1 downto 0) := "001110110010001111010111000";   -- dt/2
    signal my_input    :  std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_setpoint :  std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_output   :  std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_x   :  std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_xp  :  std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    
    constant SINGLE_FRAC_WIDTH : integer := 23;
    
    constant EXP_SIN2CUS_1 : integer := FP_WIDTH - 2;
    constant EXP_SIN2CUS_2 : integer := FP_WIDTH - EXP_WIDTH - 1;
    constant EXP_SIN2CUS_3 : integer := SINGLE_FRAC_WIDTH + EXP_WIDTH - 1;
    constant EXP_SIN2CUS_4 : integer := SINGLE_FRAC_WIDTH;
    
    constant FRAC_SIN2CUS_1 : integer := FRAC_WIDTH - 1;
    constant FRAC_SIN2CUS_2 : integer := 0;
    constant FRAC_SIN2CUS_3 : integer := SINGLE_FRAC_WIDTH - 1;
    constant FRAC_SIN2CUS_4 : integer := SINGLE_FRAC_WIDTH - FRAC_WIDTH;

begin
	-- I/O Connections assignments

	S_AXI_AWREADY	<= axi_awready;
	S_AXI_WREADY	<= axi_wready;
	S_AXI_BRESP	<= axi_bresp;
	S_AXI_BVALID	<= axi_bvalid;
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA	<= axi_rdata;
	S_AXI_RRESP	<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	      aw_en <= '1';
	      
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	        axi_awready <= '1';
	        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	            aw_en <= '1';
	        	axi_awready <= '0';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

	process (S_AXI_ACLK)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      slv_reg0 <= (others => '0');
	      slv_reg1 <= (others => '0');
	      slv_reg2 <= (others => '0');
	      slv_reg3 <= (others => '0');
	      slv_reg4 <= (others => '0');
	      slv_reg5 <= (others => '0');
	      slv_reg6 <= (others => '0');
	      slv_reg7 <= (others => '0');
	      slv_reg8 <= (others => '0');
	      slv_reg9 <= (others => '0');
	      slv_reg10 <= (others => '0');
	      slv_reg11 <= (others => '0');
	      slv_reg12 <= (others => '0');
	      slv_reg13 <= (others => '0');
	      slv_reg14 <= (others => '0');
	      slv_reg15 <= (others => '0');
	      
	    else
	      loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	      if (slv_reg_wren = '1') then
	        case loc_addr is
	          when b"0000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 0
	                slv_reg0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"0001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 1
	                slv_reg1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"0010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 2
	                slv_reg2(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"0011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 3
	                slv_reg3(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"0100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 4
	                slv_reg4(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"0101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 5
	                slv_reg5(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"0110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 6
	                slv_reg6(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"0111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 7
	                slv_reg7(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"1000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 8
	                slv_reg8(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"1001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 9
	                slv_reg9(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"1010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 10
	                slv_reg10(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"1011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 11
	                slv_reg11(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"1100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 12
	                slv_reg12(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"1101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 13
	                slv_reg13(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"1110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 14
	                slv_reg14(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"1111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 15
	                slv_reg15(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when others =>
	            slv_reg0 <= slv_reg0;
	            slv_reg1 <= slv_reg1;
	            slv_reg2 <= slv_reg2;
	            slv_reg3 <= slv_reg3;
	            slv_reg4 <= slv_reg4;
	            slv_reg5 <= slv_reg5;
	            slv_reg6 <= slv_reg6;
	            slv_reg7 <= slv_reg7;
	            slv_reg8 <= slv_reg8;
	            slv_reg9 <= slv_reg9;
	            slv_reg10 <= slv_reg10;
	            slv_reg11 <= slv_reg11;
	            slv_reg12 <= slv_reg12;
	            slv_reg13 <= slv_reg13;
	            slv_reg14 <= slv_reg14;
	            slv_reg15 <= slv_reg15;
	        end case;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- Read Address latching 
	        axi_araddr  <= S_AXI_ARADDR;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	    else
	      if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
	        -- Valid read data is available at the read data bus
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        -- Read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

	process (slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4, slv_reg5, slv_reg6, slv_reg7, slv_reg8, slv_reg9, slv_reg10, slv_reg11, slv_reg12, slv_reg13, slv_reg14, slv_reg15, axi_araddr, S_AXI_ARESETN, slv_reg_rden)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
	    -- Address decoding for reading registers
	    loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	    case loc_addr is
	      when b"0000" =>
	        reg_data_out <= slv_reg0;
	      when b"0001" =>
	        reg_data_out <= slv_reg1;
	      when b"0010" =>
	        reg_data_out <= slv_reg2;
	      when b"0011" =>
	        reg_data_out <= slv_reg3;
	      when b"0100" =>
	        reg_data_out <= slv_reg4;
	      when b"0101" =>
	        reg_data_out <= slv_reg5;
	      when b"0110" =>
	        reg_data_out <= slv_reg6;
	      when b"0111" =>
	        reg_data_out <= slv_reg7;
	      when b"1000" =>
	        reg_data_out <= slv_reg8;
	      when b"1001" =>
	        reg_data_out(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH-FP_WIDTH) <=  
	                         my_output;
            reg_data_out(C_S_AXI_DATA_WIDTH-FP_WIDTH-1 downto 0) <= (others =>'0');                 
	      when b"1010" =>
	        reg_data_out <= slv_reg10;
	      when b"1011" =>
	        reg_data_out <= slv_reg11;
	      when b"1100" =>
	        reg_data_out <= slv_reg12;
	      when b"1101" =>
	        reg_data_out <= slv_reg13;
	      when b"1110" =>
	        reg_data_out <= slv_reg14;
	      when b"1111" =>
	        reg_data_out <= slv_reg15;
	      when others =>
	        reg_data_out  <= (others => '0');
	    end case;
	end process; 

	-- Output register or memory read data
	process( S_AXI_ACLK ) is
	begin
	  if (rising_edge (S_AXI_ACLK)) then
	    if ( S_AXI_ARESETN = '0' ) then
	      axi_rdata  <= (others => '0');
	    else
	      if (slv_reg_rden = '1') then
	        -- When there is a valid read address (S_AXI_ARVALID) with 
	        -- acceptance of read address by the slave (axi_arready), 
	        -- output the read dada 
	        -- Read address mux
	          axi_rdata <= reg_data_out;     -- register read data
	      end if;   
	    end if;
	  end if;
	end process;


	-- Add user logic here
  ----------------------------------------------------------------------------------------------
    my_reset <= not(S_AXI_ARESETN) or reset_proc;
    my_input <= input(C_S_AXI_DATA_WIDTH-1) & 
        input(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
        input(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
    my_x <= x(C_S_AXI_DATA_WIDTH-1) & 
        x(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
        x(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
    my_xp <= xp(C_S_AXI_DATA_WIDTH-1) & 
        xp(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
        xp(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
       
    impCont : entity work.ImpedanceCont
      --generic map(
          --volt2pwm    => volt2pwm 
      --)
      port map(
          clk         =>  S_AXI_ACLK,
          rst         =>  my_reset,
          start       =>  start,
          
          outMax      => my_outMax  ,   
          outMin      => my_outMin  ,   
          M           => my_M       ,
          K           => my_K       ,
          B           => my_B       ,
          P           => my_P       ,
          dt          => my_dt      ,
          dt_half     => my_dt_half ,
          
          input       => my_input,
          setpoint    => my_setpoint,
          
          x           => my_x,
          xp          => my_xp,
          
          ready       => ready,
          busy        => busy,
          output      => my_output
      );
      
    process( S_AXI_ACLK ) is
    variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
    begin
    if (rising_edge (S_AXI_ACLK)) then
      if S_AXI_ARESETN = '0' then
--          my_outMax   <= "010000010000000000000000000"; -- 8
          my_outMax   <= "010001000111111111000000000"; -- 1023
--          my_outMin   <= "110000010000000000000000000"; -- -8
          my_outMin   <= "110001000111111111000000000"; -- -1023
          my_M        <= "001111111111001000111101000"; -- 1/0.5284
          my_K        <= "010000101011000100111100000"; -- 88.6173
          my_B        <= "010000010001100101001000001"; -- 9.5801
          --my_P        <= "001111110000000100100000010"; -- 0.504
          my_P        <= "010000110010100011101100010"; -- 0.504*1023/8
          my_dt       <= "001110111010001111010111000"; -- dt = 0.005 
          my_dt_half  <= "001110110010001111010111000"; -- dt/2
          --my_busy     <= '0';
          --my_ready    <= '0';
          --my_output   <= (others => '0');
          
          reset_proc <= '1';
          --ready   <= '0';
          --busy    <= '0';
          output  <= (others => '0');
      else
          
          loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
          
          --busy <= my_busy;
          --output <= my_output;
          --ready <= my_ready;
          output(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH-FP_WIDTH) <= my_output;
              
          if    ( (SLV_REG_WREN='1') ) then
              case loc_addr is
                  when    b"0000" => 
                      my_M <= S_AXI_WDATA(C_S_AXI_DATA_WIDTH-1) & 
                              S_AXI_WDATA(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
                              S_AXI_WDATA(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
                      reset_proc <= '1';
                  when    b"0001" => 
                      my_K <= S_AXI_WDATA(C_S_AXI_DATA_WIDTH-1) & 
                              S_AXI_WDATA(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
                              S_AXI_WDATA(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
                      reset_proc <= '1'; 
                  when    b"0010" => 
                      my_B <= S_AXI_WDATA(C_S_AXI_DATA_WIDTH-1) & 
                              S_AXI_WDATA(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
                              S_AXI_WDATA(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
                      reset_proc <= '1'; 
                  when    b"0011" => 
                      my_P <= S_AXI_WDATA(C_S_AXI_DATA_WIDTH-1) & 
                              S_AXI_WDATA(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
                              S_AXI_WDATA(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
                      reset_proc <= '1'; 
                  when    b"0100" => 
                      my_dt <= S_AXI_WDATA(C_S_AXI_DATA_WIDTH-1) & 
                              S_AXI_WDATA(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
                              S_AXI_WDATA(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
                      reset_proc <= '1';  
                  when    b"0101" => 
                      my_dt_half <=  S_AXI_WDATA(C_S_AXI_DATA_WIDTH-1) & 
                              S_AXI_WDATA(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
                              S_AXI_WDATA(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
                      reset_proc <= '1'; 
                  when    b"0110" => 
                      my_outMax <=  S_AXI_WDATA(C_S_AXI_DATA_WIDTH-1) & 
                              S_AXI_WDATA(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
                              S_AXI_WDATA(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
                      reset_proc <= '1'; 
                  when    b"0111" => 
                      my_outMin <=  S_AXI_WDATA(C_S_AXI_DATA_WIDTH-1) & 
                              S_AXI_WDATA(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
                              S_AXI_WDATA(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
                      reset_proc <= '1'; 
                  when    b"1000" => 
                      my_setpoint <=  S_AXI_WDATA(C_S_AXI_DATA_WIDTH-1) & 
                            S_AXI_WDATA(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) & 
                            S_AXI_WDATA(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
                  when others =>
                      my_M <= my_M;
                      my_K <= my_K;
                      my_B <= my_B;
                      my_P <= my_P;
                      my_dt <= my_dt;
                      my_dt_half <= my_dt_half;
                      my_outMax <= my_outMax;
                      my_outMin <= my_outMin;
                      my_setpoint <= my_setpoint;
                      reset_proc <= '0';
              end case;
          else
              reset_proc <= '0';  
          end if;
        
      end if;
    end if;
    end process;
	-- User logic ends

end arch_imp;
