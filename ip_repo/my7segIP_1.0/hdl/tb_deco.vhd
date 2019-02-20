----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.05.2018 21:10:56
-- Design Name: 
-- Module Name: tb_deco - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_deco is
generic (
		-- Users to add parameters here
        sys_clk_freq : integer := 100_000_000;  -- frequencia do clock do sistema (100MHz)
        sevenSeg_freq : integer := 1_000;       -- frequencia de sincronização dos 7 seg (1KHz)
        anNum : integer := 4;                   -- numero de ánodos
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
	);
--  Port ( );
end tb_deco;

architecture Behavioral of tb_deco is
component deco is
    generic (
            -- Users to add parameters here
        sys_clk_freq : integer := 100_000_000;  -- frequencia do clock do sistema (100MHz)
        sevenSeg_freq : integer := 1_000;       -- frequencia de sincronização dos 7 seg (1KHz)
        anNum : integer := 4;                   -- numero de ánodos
        -- User parameters ends
        -- Do not modify the parameters beyond this line

        -- Width of S_AXI data bus
        C_S_AXI_DATA_WIDTH    : integer    := 32;
        -- Width of S_AXI address bus
        C_S_AXI_ADDR_WIDTH    : integer    := 4
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
    end component;

    constant CLK_PERIOD: time := 10 ns;
    constant RST_HOLD_DURATION: time := 200 ns;
    constant MOD_TIME: time := 3 us;
    
     -- clock and reset
    signal S_AXI_ACLK    : std_logic := '0';
    signal S_AXI_ARESETN : std_logic := '0';
     -- write data channel
    signal S_AXI_WDATA  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal SLV_REG_WREN  : std_logic := '0';
     -- address channel 
    signal AXI_AWADDR    : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
     -- my inputs / outputs --
     -- output
    signal sevenSegOut:    STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal anPinOut:       STD_LOGIC_VECTOR (anNum-1 downto 0) := (others => '0');
    
begin
utt: deco
    generic map(
        sys_clk_freq        => sys_clk_freq,
        sevenSeg_freq       => sevenSeg_freq,     
        anNum               => anNum,              
        
        C_S_AXI_DATA_WIDTH  => C_S_AXI_DATA_WIDTH, 
        C_S_AXI_ADDR_WIDTH  => C_S_AXI_ADDR_WIDTH 
    )            
    Port map (              
        S_AXI_ACLK          => S_AXI_ACLK    ,
        S_AXI_ARESETN       => S_AXI_ARESETN ,
        S_AXI_WDATA         => S_AXI_WDATA   ,
        SLV_REG_WREN        => SLV_REG_WREN  ,
        AXI_AWADDR          => AXI_AWADDR    ,
        sevenSegOut         => sevenSegOut   ,
        anPinOut            => anPinOut      
    );
    
    stimuli: process
    begin
        wait for RST_HOLD_DURATION + RST_HOLD_DURATION;
        SLV_REG_WREN <= '1';
        AXI_AWADDR <= "0000";
        S_AXI_WDATA <= "00000000000000000000000000000111"; -- CH 0 val 7
                                           
        wait for CLK_PERIOD * 2;
        SLV_REG_WREN <= '0';
        wait for CLK_PERIOD / 2;

        wait for 1.5 ms;
        
        wait for RST_HOLD_DURATION + RST_HOLD_DURATION;
        SLV_REG_WREN <= '1';
        AXI_AWADDR <= "0100";
        S_AXI_WDATA <= "00000000000000000000000000000101"; -- CH 1 val 5
                                           
        wait for CLK_PERIOD * 2;
        SLV_REG_WREN <= '0';
        wait for CLK_PERIOD / 2;

        wait for 1.5 ms;

        wait for RST_HOLD_DURATION + RST_HOLD_DURATION;
        SLV_REG_WREN <= '1';
        AXI_AWADDR <= "1000";
        S_AXI_WDATA <= "00000000000000000000000000001000"; -- CH 2 val 8
                                           
        wait for CLK_PERIOD * 2;
        SLV_REG_WREN <= '0';
        wait for CLK_PERIOD / 2;

        wait for 1.5 ms;
        
        wait for RST_HOLD_DURATION + RST_HOLD_DURATION;
        SLV_REG_WREN <= '1';
        AXI_AWADDR <= "1100";
        S_AXI_WDATA <= "00000000000000000000000000001010"; -- CH 3 val 10
                                           
        wait for CLK_PERIOD * 2;
        SLV_REG_WREN <= '0';
        wait for CLK_PERIOD / 2;

        wait for 1.5 ms;
        wait ;
    
    end process;
    
    clock_p: process is
    begin
        S_AXI_ACLK <= '0';
        wait for CLK_PERIOD / 2;
        S_AXI_ACLK <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    
    reset_p: process is
    begin
        S_AXI_ARESETN <= '0';
        
        wait for RST_HOLD_DURATION;
        wait until rising_edge(S_AXI_ACLK);
        S_AXI_ARESETN <= '1';
        wait;
    end process;

end Behavioral;
