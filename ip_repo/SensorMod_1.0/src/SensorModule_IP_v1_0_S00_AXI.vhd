library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

    use work.fpupack.all;

entity SensorModule_IP_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here
        NumberOfModules : integer   := 3;
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 8
	);
	port (
		-- Users to add ports here
        busy : out STD_LOGIC;
        ready : out STD_LOGIC;
        
        position : out STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0);
        velocity : out STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0);
        current : out STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0);
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
end SensorModule_IP_v1_0_S00_AXI;

architecture arch_imp of SensorModule_IP_v1_0_S00_AXI is
    
    function or_reduct(slv : in std_logic_vector) return std_logic is
      variable res_v : std_logic := '0';  -- Null slv vector will also return '1'
    begin
      for i in slv'range loop
        res_v := res_v or slv(i);
      end loop;
      return res_v;
    end function;
    
    -- User Component
    component SensorMod is
        Port ( 
           clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start : in STD_LOGIC;
           positionSen : in STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0);
           currentSen : in STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0);
           volts : in STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0);
           
           busy : out STD_LOGIC;
           ready : out STD_LOGIC;
           
           position : out STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0);
           velocity : out STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0);
           current : out STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0);
           
           dt_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           R_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           center_current_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           Q_0_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           Q_12_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           Q_3_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           b01_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           a1_conf : in std_logic_vector(FP_WIDTH-1 downto 0)
           );
    end component;

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

	signal axi_wdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

	-- Example-specific design signals
	-- REG_ADDR is where the io register are located
	-- STATUS_ADDR_B is the bit reserved for the status
	-- IOREG_ADDR_B is the bit reserved for read or write register
	constant STATUS_ADDR_B : integer := 0;
	constant REG_ADDR_LSB  : integer := 1;
	constant REG_ADDR_SIZE : integer := 2;
	constant MOD_ADDR_LSB  : integer := 3;
	constant MOD_ADDR_SIZE : integer := 3;
	constant IOREG_ADDR_LSB  : integer := 6;
	constant IOREG_ADDR_SIZE  : integer := 2;
    
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	signal mod_addr_reg       : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal status_reg         : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal dt_reg             : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal R_reg              : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal center_current_reg : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Q_0_reg            : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Q_12_reg           : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Q_3_reg            : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal b01_reg            : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal a1_reg             : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    
	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal reg_data_out	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	: integer;
	signal aw_en	: std_logic;

	-- User Signals
	signal rst : std_logic := '0';
	signal sw_rst : std_logic := '0';
--    signal busy_reg : std_logic := '0';
--    signal ready_reg : std_logic := '0';
	signal busy_status_reg, ready_status_reg : std_logic_vector(NumberOfModules-1 downto 0) ;
	
	signal START_SENSORMOD : std_logic_vector(NumberOfModules-1 downto 0) ;
	signal my_busy         : std_logic_vector(NumberOfModules-1 downto 0) ;
	signal ready_sDATA     : std_logic_vector(NumberOfModules-1 downto 0) ;
	
	type sensor_array is array (1 to NumberOfModules) of std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal my_positionSen : sensor_array := (others => (others => '0'));
	signal my_voltsSen    : sensor_array := (others => (others => '0'));
	signal my_currentSen  : sensor_array := (others => (others => '0'));
	signal my_position    : sensor_array := (others => (others => '0'));
	signal my_velocity    : sensor_array := (others => (others => '0'));
	signal my_current     : sensor_array := (others => (others => '0'));
	
	signal cont_out : integer range 0 to 3 := 0;
        
begin
	-- I/O Connections assignments

	S_AXI_AWREADY  <= axi_awready;
	S_AXI_WREADY   <= axi_wready;
	S_AXI_BRESP    <= axi_bresp;
	S_AXI_BVALID   <= axi_bvalid;
	S_AXI_ARREADY  <= axi_arready;
	S_AXI_RDATA    <= axi_rdata;
	S_AXI_RRESP	   <= axi_rresp;
	S_AXI_RVALID   <= axi_rvalid;
	
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
					axi_wdata <= S_AXI_WDATA;
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
		variable mod_addr :integer range 0 to 7;
		variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
		begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      my_positionSen   <= (others => (others => '0'));
	      my_voltsSen      <= (others => (others => '0'));
	      my_currentSen    <= (others => (others => '0')); 
	      dt_reg <= "00111011101000111101011100000000";   -- dt = 0.005 
				R_reg <= "00111010010110001011100011100000";    -- R = 8.2673e-04 
				center_current_reg <= "01000111000011101000011000100000";   -- 36486.206
				Q_0_reg <= "00110000000000001101100101000000";    -- (nQ*dt^4)/4  
				Q_12_reg <= "00110100010010010101001110000000";    -- (nQ*dt^3)/2 
				Q_3_reg <= "00111000100111010100100101000000";    --  nQ*dt 
				b01_reg <= "00111100111000010100011110100000";    --  0.0275 
				a1_reg <= "10111111011100011110101110000000";    --  -0.9450
				sw_rst <= '0';
	      cont_out <= 0;
			else
	      mod_addr := to_integer(unsigned(axi_wdata(MOD_ADDR_SIZE-1 downto 0)));
				loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
				if (slv_reg_wren = '1') then
	        case loc_addr is
	          when b"0000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- addr of module to be read registor 0
	                mod_addr_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"0001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- dt registor 1
	                dt_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
							end loop;
							sw_rst <= '1'; -- reset module when configuring
	          when b"0010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- R registor 2
	                R_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
							end loop;
							sw_rst <= '1'; -- reset module when configuring
	          when b"0011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- center current registor 3
	                center_current_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
							end loop;
							sw_rst <= '1'; -- reset module when configuring
	          when b"0100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- Q0 registor 4
	                Q_0_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
							end loop;
							sw_rst <= '1'; -- reset module when configuring
	          when b"0101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
									-- Q1 and Q2 registor 5
	                Q_12_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
							end loop;
							sw_rst <= '1'; -- reset module when configuring
	          when b"0110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- Q3 registor 6
	                Q_3_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
							end loop;
							sw_rst <= '1'; -- reset module when configuring
	          when b"0111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- b0 b1 registor 7
	                b01_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
							end loop;
							sw_rst <= '1'; -- reset module when configuring
	          when b"1000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- a1 registor 8
	                a1_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
							end loop;
							sw_rst <= '1'; -- reset module when configuring
	          when b"1001" =>
							-- slave registor 9
							my_positionSen(mod_addr) <= S_AXI_WDATA;
							cont_out <= cont_out + 1;
	          when b"1010" =>
							-- slave registor 10
							my_currentSen(mod_addr) <= S_AXI_WDATA;
							cont_out <= cont_out + 1;
	          when b"1011" =>
							-- slave registor 11
							my_voltsSen(mod_addr) <= S_AXI_WDATA;
							cont_out <= cont_out + 1;
	          when others =>
							my_positionSen <= my_positionSen;
							my_voltsSen <= my_voltsSen;
							my_currentSen <= my_currentSen;
							dt_reg <= dt_reg;    
							R_reg <= R_reg; 
							center_current_reg <= center_current_reg;
							Q_0_reg <= Q_0_reg;  
							Q_12_reg <= Q_12_reg; 
							Q_3_reg <= Q_3_reg; 
							b01_reg <= b01_reg; 
							a1_reg <= a1_reg;
							sw_rst <= '0'; cont_out <= 0;
					end case;
				elsif cont_out = 3 then
					cont_out <= 0; sw_rst <= '0';
				else
					sw_rst <= '0';
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

	process (my_positionSen, my_voltsSen, my_currentSen, my_position, my_velocity, my_current, axi_araddr, S_AXI_ARESETN, slv_reg_rden,
	   status_reg, dt_reg, R_reg, center_current_reg, Q_0_reg, Q_12_reg, Q_3_reg, b01_reg, a1_reg)
		variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
		variable mod_addr    : integer range 0 to 7; 
		begin
			-- Address decoding for reading registers
			loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
			mod_addr := to_integer(unsigned(mod_addr_reg(MOD_ADDR_SIZE-1 downto 0)));
			case loc_addr is
				when b"0000" =>
					reg_data_out <= status_reg;
				when b"0001" =>
					reg_data_out <= dt_reg;
				when b"0010" =>
					reg_data_out <= R_reg;
				when b"0011" =>
					reg_data_out <= center_current_reg;
				when b"0100" =>
					reg_data_out <= Q_0_reg;
				when b"0101" =>
					reg_data_out <= Q_12_reg;
				when b"0110" =>
					reg_data_out <= Q_3_reg;
				when b"0111" =>
					reg_data_out <= b01_reg;
				when b"1000" =>
					reg_data_out <= a1_reg;
				when b"1001" =>
					reg_data_out <= my_position(mod_addr);
				when b"1010" =>
					reg_data_out <= my_velocity(mod_addr);
				when b"1011" =>
					reg_data_out <= my_current(mod_addr);
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
	busy     <= or_reduct(my_busy);
	ready    <= or_reduct(ready_sDATA);    
	rst <= not(S_AXI_ARESETN) or sw_rst;

	sensorMod_gen: for i in 1 to NumberOfModules generate
		sensorMod_utt : 
		SensorMod port map(
				clk => S_AXI_ACLK,
				rst => rst,
				start => START_SENSORMOD(i-1),
				positionSen =>  my_positionSen(i),
				currentSen =>   my_currentSen(i),
				volts =>        my_voltsSen(i),
				
				busy => my_busy(i-1),
				ready => ready_sDATA(i-1),
				
				position =>     my_position(i),
				velocity  =>    my_velocity(i),
				current  =>     my_current(i),
				
				dt_conf  => dt_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH - FP_WIDTH),
				R_conf => R_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH - FP_WIDTH),
				center_current_conf => center_current_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH - FP_WIDTH),
				Q_0_conf => Q_0_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH - FP_WIDTH),
				Q_12_conf => Q_12_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH - FP_WIDTH),
				Q_3_conf => Q_3_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH - FP_WIDTH),
				b01_conf => b01_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH - FP_WIDTH),
				a1_conf => a1_reg(C_S_AXI_DATA_WIDTH-1 downto C_S_AXI_DATA_WIDTH - FP_WIDTH)            );
	end generate;
    
	process(S_AXI_ACLK)
	variable cont_mod : integer range 0 to NumberOfModules-1 := 0;
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
		if(rising_edge(S_AXI_ACLK))then
			if(S_AXI_ARESETN ='0')then
				status_reg <= (others => '0');
				busy_status_reg <= (others => '0');
				ready_status_reg <= (others => '0');
				START_SENSORMOD <= (others => '0');
				cont_mod := 0;
--              ready_reg <= '0';
--              busy_reg <= '0';
			else
				loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
				
				if (cont_out = 3 and cont_mod < NumberOfModules) then
					START_SENSORMOD(cont_mod) <= '1';
					if NumberOfModules > 1 then
						cont_mod := cont_mod + 1;
					end if;
				elsif (cont_mod >= NumberOfModules) then
					cont_mod := 0;
					START_SENSORMOD <=  (others => '0');
				else
					START_SENSORMOD <= (others => '0');
				end if;--  0 -  1  reserved
				
				--  2 - 15  busy_reg
				-- 16 - 29  ready_reg
				busy_status_reg <= my_busy;
				if ( unsigned(ready_sDATA) > 0 ) then
					ready_status_reg <= ready_status_reg or ready_sDATA;
				elsif (slv_reg_wren = '1' and loc_addr = b"0000" ) then 
					ready_status_reg <= (others => '0');
				end if;
				
				status_reg(NumberOfModules + 2-1  downto  2) <= busy_status_reg;
				status_reg(NumberOfModules + 16-1 downto 16) <= ready_status_reg;      
				
				if NumberOfModules = 1 then
					position <= my_position(1);
					velocity <= my_velocity(1);
					current  <= my_current(1);
				end if;
			end if;
		end if;
	end process;

	-- User logic ends

end arch_imp;
