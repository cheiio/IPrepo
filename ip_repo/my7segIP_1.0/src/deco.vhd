library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity deco is
    generic (
		-- Users to add parameters here
        sys_clk_freq : integer := 100_000_000;  -- frequencia do clock do sistema (100MHz)
        sevenSeg_freq : integer := 200;       -- frequencia de sincroniza??o dos 7 seg (200Hz)
        anNum : integer := 4;                   -- numero de ?nodos
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 4;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
	);
    Port ( 
        -- clock and reset
        S_AXI_ACLK    : in std_logic;
        S_AXI_ARESETN : in std_logic;
        -- write data channel
        S_AXI_WDATA  : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SLV_REG_WREN  : in std_logic;
        -- address channel 
        AXI_AWADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        -- my inputs / outputs --
        -- output
        sevenSegOut:    out STD_LOGIC_VECTOR (7 downto 0);
        anPinOut:       out STD_LOGIC_VECTOR (anNum-1 downto 0)
        );
end deco;

architecture Behavioral of deco is

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 1;
    
    type t_sevenSegments is array (0 TO anNum-1) of std_logic_vector(7 downto 0); --data type for array of sevenSegmentsValues
    signal sevenSegments : t_sevenSegments := (others => "11111111");

    type t_state1 is (Idle, state_1, state_2, state_3);
    signal state : t_state1;
   
   
begin

    process (S_AXI_ACLK, S_AXI_ARESETN)
    
    constant seveSeg_period : integer := sys_clk_freq/sevenSeg_freq;
    variable counter : integer range 0 to sys_clk_freq/sevenSeg_freq;
    variable flag_an_counter : std_logic ; 
    variable an_counter : integer range 0 to anNum-1;
    
    begin 
        if S_AXI_ARESETN = '0' then
            sevenSegOut <= (others=>'1');
            anPinOut <= (others => '0');
            counter := 0;
            an_counter := 0;  
            flag_an_counter := '0';  
               
        elsif rising_edge(S_AXI_ACLK) then
            
            if (counter = seveSeg_period) then
                counter := 0;
                flag_an_counter := '1';     
            else 
                counter := counter + 1;
                flag_an_counter := '0';     
            end if;
            
            if (flag_an_counter = '1') then
                if (an_counter = anNum-1) then
                    an_counter := 0;
                else 
                    an_counter := an_counter + 1;
                end if;
                
                sevenSegOut <= sevenSegments(an_counter);
                case an_counter is
                    when 0 => anPinOut <= "1110";  
                    when 1 => anPinOut <= "1101";  
                    when 2 => anPinOut <= "1011";  
                    when 3 => anPinOut <= "0111";  
                    when others => anPinOut <= "1111";  
                end case;
                
                
            end if;
            
        end if;
    end process;
			
	process(S_AXI_ACLK, S_AXI_ARESETN)
	   variable an_addr : std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	   variable sevenSeg_decoVal : std_logic_vector(7 downto 0);
	   variable sevenSeg_val: std_logic_vector(3 downto 0);
	begin
	   if S_AXI_ARESETN = '0' then
            sevenSegments <= (others => "11111111");
            
       elsif rising_edge(S_AXI_ACLK) then
	       
           case state is
               when state_1 =>
                   if(SLV_REG_WREN='1') then
                       sevenSeg_val := S_AXI_WDATA(3 downto 0);
                       an_addr := AXI_AWADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
                       state <= state_2;
                   end if;
               
               when state_2 =>
                   case sevenSeg_val is
                       --when "xxxx" => res <= "pgfedcba";
                       when "0000" => sevenSeg_decoVal := "11000000"; --0
                       when "0001" => sevenSeg_decoVal := "11111001"; --1
                       when "0010" => sevenSeg_decoVal := "10100100"; --2
                       when "0011" => sevenSeg_decoVal := "10110000"; --3
                       when "0100" => sevenSeg_decoVal := "10011001"; --4
                       when "0101" => sevenSeg_decoVal := "10010010"; --5
                       when "0110" => sevenSeg_decoVal := "10000010"; --6
                       when "0111" => sevenSeg_decoVal := "11111000"; --7
                       when "1000" => sevenSeg_decoVal := "10000000"; --8
                       when "1001" => sevenSeg_decoVal := "10010000"; --9
                       when "1010" => sevenSeg_decoVal := "10001000"; --A
                       when "1011" => sevenSeg_decoVal := "10000011"; --B
                       when "1100" => sevenSeg_decoVal := "11000110"; --C
                       when "1101" => sevenSeg_decoVal := "10100001"; --D
                       when "1110" => sevenSeg_decoVal := "10000110"; --E
                       when "1111" => sevenSeg_decoVal := "10001110"; --F
                       when others => sevenSeg_decoVal := "11111111"; --outros casos
                   end case;
                   state <= state_3;
                    
               when state_3 =>
                   case an_addr is
                        when "00" =>
                            sevenSegments(0) <=  sevenSeg_decoVal;
                        when "01" =>
                            sevenSegments(1) <=  sevenSeg_decoVal;
                        when "10" =>
                            sevenSegments(2) <=  sevenSeg_decoVal;
                        when "11" =>
                            sevenSegments(3) <=  sevenSeg_decoVal;
                        when others => state <= state_1;
                   end case;
                   state <= state_1;
                   
               when others => state <= state_1; 
           end case;
	   end if;
		
		  
	end process;
	
end Behavioral;	
