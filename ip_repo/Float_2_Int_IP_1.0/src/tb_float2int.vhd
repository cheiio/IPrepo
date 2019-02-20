----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.07.2018 21:58:24
-- Design Name: 
-- Module Name: tb_float2int - Behavioral
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

    use work.entities.all;
    use work.fpupack.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_float2int is
--  Port ( );
end tb_float2int;

architecture Behavioral of tb_float2int is

Constant ClockPeriod : TIME := 5 ns;
Constant ClockPeriod2 : TIME := 10 ns;
shared variable ClockCount : integer range 0 to 50_000 := 10;

constant FLOAT_WIDTH : integer := 32;
constant INTEGER_WIDTH : integer := 16;

signal clk      :  std_logic;
signal start    :  std_logic := '0';
signal reset    :  std_logic; 
signal ready    :  std_logic;
signal float_in :  STD_LOGIC_VECTOR (FLOAT_WIDTH-1 downto 0);
signal int_out  :  STD_LOGIC_VECTOR (FLOAT_WIDTH-1 downto 0);

begin

utt: entity work.float2int_IP
generic map (
    FLOAT_WIDTH  => FLOAT_WIDTH ,
    INTEGER_WIDTH => INTEGER_WIDTH
)
port map(
    clk     => clk     ,
    start   => start   ,
    reset_n   => reset   ,
    ready   => ready   ,
    float_in=> float_in,
    int_out => int_out 
);

GENERATE_REFCLOCK : process
 begin
   wait for (ClockPeriod / 2);
   ClockCount:= ClockCount+1;
   clk <= '1';
   wait for (ClockPeriod / 2);
   clk <= '0';
 end process;

tb : PROCESS
 BEGIN
        reset<='0';
    wait for ClockPeriod*3;
        reset<='1';
    wait for ClockPeriod*3;
        float_in <= "01000011001010001001000101101000"; --168.568
        start <= '1';
    wait for ClockPeriod;
        start <= '0';
    
    wait for ClockPeriod*3;
        float_in <= "01000100011111011111100110011010"; -- 1015.9
        start <= '1';
    wait for ClockPeriod;
        start <= '0';
        
    wait for ClockPeriod*3;
        float_in <= "11000100000001110100011001100110"; -- -541.1
        start <= '1';
    wait for ClockPeriod;
        start <= '0';
        
    wait;
end process tb;

end Behavioral;
