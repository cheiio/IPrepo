----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.04.2018 14:31:03
-- Design Name: 
-- Module Name: tb_MotorDriver - Behavioral
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

entity tb_MotorDriver is
generic (
		-- Users to add parameters here
        sys_clk         : INTEGER := 50_000_000; --system clock frequency in Hz
        pwm_freq        : INTEGER := 31_372;    --PWM switching frequency in Hz
        nMOTORS         : integer := 3;            -- 7 motors
        bits_resolution : INTEGER := 10;         -- bits of resolution setting the duty cycle
        motor_addr_with : INTEGER := 4;
               -- User parameters ends
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
	);
--  Port ( );
end tb_MotorDriver;

architecture Behavioral of tb_MotorDriver is

constant CLK_PERIOD: time := 10 ns;
constant RST_HOLD_DURATION: time := 200 ns;
constant MOD_TIME: time := 3 us;

signal S_AXI_ACLK : std_logic := '0';
signal SLV_REG_WREN : std_logic := '0';
signal AXI_AWADDR : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0) := (others=>'0');
signal S_AXI_WDATA : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others=>'0');
signal PWM_OUT : std_logic_vector((nMOTORS*2)-1 downto 0) := (others=>'0');
signal S_AXI_ARESETN : std_logic := '0';

begin

-- Add user logic here
    U1: entity work.motorDriver 
        generic map (
            sys_clk             => sys_clk,
            pwm_freq            => pwm_freq,
            nMOTORS             => nMotors,
            bits_resolution     => bits_resolution,
            motor_addr_with     => motor_addr_with,
            
            C_S_AXI_DATA_WIDTH    => C_S_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH    => C_S_AXI_ADDR_WIDTH
        )
    port map(
            S_AXI_ACLK      =>  S_AXI_ACLK,
            SLV_REG_WREN    =>  SLV_REG_WREN,
            AXI_AWADDR      =>  AXI_AWADDR,
            S_AXI_WDATA     =>  S_AXI_WDATA,
            S_AXI_ARESETN   =>  S_AXI_ARESETN,
            PWM_OUT         =>  PWM_OUT
    );
	-- User logic ends
	
	stimuli: process
	begin
        wait for RST_HOLD_DURATION + RST_HOLD_DURATION;
        SLV_REG_WREN <= '1';
        AXI_AWADDR <= "0000";
        S_AXI_WDATA <= "00000000000000000001111101000001"; -- CH 3 PWM 500
                                           
        wait for CLK_PERIOD * 2;
        SLV_REG_WREN <= '0';
        wait for CLK_PERIOD / 2;

        wait for 1 ms;
 
        SLV_REG_WREN <= '1';
        AXI_AWADDR <= "0000";
        S_AXI_WDATA <= "00000000000000000010101111000010"; -- CH 2 PWM 700
                                          
        wait for CLK_PERIOD / 2;
        SLV_REG_WREN <= '0';
        wait for CLK_PERIOD / 2;
 
        wait for 1 ms;
    
        SLV_REG_WREN <= '1';
        AXI_AWADDR <= "0000";
        S_AXI_WDATA <= "11111111111111111111100111000000"; -- CH 5 PWM -100
    	                                     
        wait for CLK_PERIOD / 2;
        SLV_REG_WREN <= '0';
        wait for CLK_PERIOD / 2;

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
