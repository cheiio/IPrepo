----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.07.2018 18:39:03
-- Design Name: 
-- Module Name: float2int_IP - Behavioral
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
use ieee.numeric_std.all;

    use work.entities.all;
    use work.fpupack.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity float2int_IP is
    Generic(
        FLOAT_WIDTH : integer := 32;
        INTEGER_WIDTH : integer := 16
    );
    Port ( 
        clk     : in std_logic;
        reset_n : in std_logic; 
        
        start   : in std_logic;
        
        ready : out std_logic;
        
        float_in : in STD_LOGIC_VECTOR (FLOAT_WIDTH-1 downto 0);
        int_out : out STD_LOGIC_VECTOR (FLOAT_WIDTH-1 downto 0));
end float2int_IP;

architecture Behavioral of float2int_IP is

type   t_state is ( Idle, state_1, state_2, state_3);
signal state : t_state;

constant sumdata : std_logic_vector(FP_WIDTH-1 downto 0) := "010010000111111111111111111"; -- (1 << 18)
--constant mask_out : std_logic_vector(FP_WIDTH-1 downto 0):= "000000000011111111111111111";

-- AddSub_1 signals
--signal start_as : std_logic :='0';
signal op_b   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
signal out_as   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
signal ready_as : std_logic;
signal reset_as : std_logic;

begin

op_b <= '0' & float_in(FLOAT_WIDTH-2 downto FLOAT_WIDTH-FP_WIDTH);
reset_as <= not reset_n;
AddSub: addsubfsm_v6
port map (reset         => reset_as,
          clk           => clk,
          op            => '0',
          op_a          => sumdata,
          op_b          => op_b,
          start_i       => start,
          addsub_out    => out_as,
          ready_as      => ready_as);


process(clk) is
    begin
        if rising_edge(clk) then
            
            if reset_n='0' then
                int_out <= (others => 'X');
                ready <= '0';
            else
                if ready_as = '1' then
                    if float_in(FLOAT_WIDTH-1) = '0' then
                        int_out(INTEGER_WIDTH-1 downto 0) <= out_as(INTEGER_WIDTH-1 downto 0);
                        int_out(FLOAT_WIDTH-1 downto INTEGER_WIDTH) <= (others => '0');
                    else
                        int_out(INTEGER_WIDTH-1 downto 0) <= std_logic_vector(unsigned(not(out_as(INTEGER_WIDTH-1 downto 0))) + 1);
                        int_out(FLOAT_WIDTH-1 downto INTEGER_WIDTH) <= (others => '1');
                    end if;
                    ready <= '1';
                else
                    ready <= '0';    
                end if;
            end if;
        end if;
        
end process;


end Behavioral;
