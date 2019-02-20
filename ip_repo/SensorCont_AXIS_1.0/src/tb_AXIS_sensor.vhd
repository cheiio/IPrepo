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
    
entity tb_AXIS_sensor is
--  Port ( );
end tb_AXIS_sensor;

architecture Behavioral of tb_AXIS_sensor is

Constant ClockPeriod : TIME := 10 ns;
Constant ClockPeriod2 : TIME := 5 ns;
shared variable ClockCount : integer range 0 to 50_000 := 10;

constant C_AXIS_TDATA_WIDTH : integer := 32;


-- User ports ends
-- Do not modify the ports beyond this line
signal aclk	: std_logic := '0';
signal aresetn	: std_logic  := '0';
signal modMaster_ready : std_logic;
signal modMaster_busy : std_logic ;
signal modMaster_busy_vector : std_logic_vector(2 downto 0) ;

-- Ports of Axi Slave Bus Interface S00_AXIS
signal s_axis_tready	: std_logic;
signal s_axis_tdata	: std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
signal s_axis_tstrb	: std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0) := (others => '0');
signal s_axis_tlast	: std_logic := '0';
signal s_axis_tvalid	: std_logic := '0';

-- Ports of Axi Master Bus Interface M00_AXIS
signal m_axis_tvalid	: std_logic;
signal m_axis_tdata	: std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
signal m_axis_tstrb	: std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
signal m_axis_tlast	: std_logic;
signal m_axis_tready	: std_logic := '0';

begin

utt: entity work.SensorCont_AXIS_v1_0
port map(
    modMaster_aclk    => aclk ,
    modMaster_aresetn => aresetn,
                        
    modMaster_ready   => modMaster_ready ,
    modMaster_busy    => modMaster_busy  ,
    modMaster_busy_vector => modMaster_busy_vector  ,
                        
    s00_axis_aclk	      => aclk	    ,
    s00_axis_aresetn    => aresetn ,
    s00_axis_tready	  => s_axis_tready,	 
    s00_axis_tdata	  => s_axis_tdata	,  
    s00_axis_tstrb	  => s_axis_tstrb	 , 
    s00_axis_tlast	  => s_axis_tlast	  ,
    s00_axis_tvalid	  => s_axis_tvalid	 ,
                                           
    m00_axis_aclk	     =>  aclk	   ,
    m00_axis_aresetn   =>  aresetn ,
    m00_axis_tvalid	 =>  m_axis_tvalid,	 
    m00_axis_tdata	 =>  m_axis_tdata	, 
    m00_axis_tstrb	 =>  m_axis_tstrb	 ,
    m00_axis_tlast	 =>  m_axis_tlast	 ,
    m00_axis_tready	 =>  m_axis_tready	 
);

GENERATE_REFCLOCK : process
 begin
   wait for (ClockPeriod / 2);
   ClockCount:= ClockCount+1;
   aclk <= '1';
   wait for (ClockPeriod / 2);
   aclk <= '0';
 end process;

tb : PROCESS
 BEGIN
        aresetn<='0';
    wait for ClockPeriod*3;
        aresetn<='1';
    wait for ClockPeriod*3;
        s_axis_tvalid <= '1';
    
    for I in 0 to 3 loop
            s_axis_tdata <= "01000011001010001001000101101000"; --168.568
        wait for ClockPeriod;
            s_axis_tdata <= "01000100011111011111100110011010"; -- 1015.9
        wait for ClockPeriod;
            s_axis_tdata <= "11000100000001110100011001100110"; -- -541.1
        wait for ClockPeriod;
    end loop;
    
    s_axis_tvalid <= '0';
    
    m_axis_tready <= '1';
    wait until m_axis_tlast = '0';
    m_axis_tready <= '0';
        
    wait;
end process tb;

end Behavioral;
