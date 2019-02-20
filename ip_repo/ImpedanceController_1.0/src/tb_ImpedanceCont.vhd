library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;

entity testbench is
generic
(
  --volt2pwm                       : std_logic_vector := "010000110000000000000000000";          
  C_S_AXI_DATA_WIDTH             : integer              := 32;
  C_S_AXI_ADDR_WIDTH             : integer              := 6
);

end testbench;

architecture Behavioral of testbench is
    
    signal start    : std_logic := '0';
    signal input    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0):= (others => '0');
    signal x        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0):= (others => '0');
    signal xp       : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0):= (others => '0');
    signal ready    :  std_logic;
    signal busy     :  std_logic;
    signal output   :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    
    signal S_AXI_ACLK                     :  std_logic;
    signal S_AXI_ARESETN                  :  std_logic;
    signal S_AXI_AWADDR                   :  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal S_AXI_AWVALID                  :  std_logic;
    signal S_AXI_WDATA                    :  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal S_AXI_WSTRB                    :  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    signal S_AXI_WVALID                   :  std_logic;
    signal S_AXI_BREADY                   :  std_logic;
    signal S_AXI_ARADDR                   :  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal S_AXI_ARVALID                  :  std_logic;
    signal S_AXI_RREADY                   :  std_logic;
    signal S_AXI_ARREADY                  : std_logic;
    signal S_AXI_RDATA                    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal S_AXI_RRESP                    : std_logic_vector(1 downto 0);
    signal S_AXI_RVALID                   : std_logic;
    signal S_AXI_WREADY                   : std_logic;
    signal S_AXI_BRESP                    : std_logic_vector(1 downto 0);
    signal S_AXI_BVALID                   : std_logic;
    signal S_AXI_AWREADY                  : std_logic;
    signal S_AXI_AWPROT                   : std_logic_vector(2 downto 0);
    signal S_AXI_ARPROT                   : std_logic_vector(2 downto 0);

    
    Constant ClockPeriod : TIME := 5 ns;
    Constant ClockPeriod2 : TIME := 10 ns;
    shared variable ClockCount : integer range 0 to 50_000 := 10;
    signal sendIt : std_logic := '0';
    signal readIt : std_logic := '0';

begin

  -- instance "led_controller_v1_0_1"
  ImpController: entity work.ImpedanceController_v1_0
    generic map (
      --volt2pwm => volt2pwm,
      C_S00_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
      C_S00_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH)
    port map (
      start   => start ,
      input   => input ,
      x       => x     ,
      xp      => xp    ,
      ready   => ready ,
      busy    => busy  ,
      output  => output,
      s00_axi_aclk    => S_AXI_ACLK,
      s00_axi_aresetn => S_AXI_ARESETN,
      s00_axi_awaddr  => S_AXI_AWADDR,
      s00_axi_awprot  => S_AXI_AWPROT,
      s00_axi_awvalid => S_AXI_AWVALID,
      s00_axi_awready => S_AXI_AWREADY,
      s00_axi_wdata   => S_AXI_WDATA,
      s00_axi_wstrb   => S_AXI_WSTRB,
      s00_axi_wvalid  => S_AXI_WVALID,
      s00_axi_wready  => S_AXI_WREADY,
      s00_axi_bresp   => S_AXI_BRESP,
      s00_axi_bvalid  => S_AXI_BVALID,
      s00_axi_bready  => S_AXI_BREADY,
      s00_axi_araddr  => S_AXI_ARADDR,
      s00_axi_arprot  => S_AXI_ARPROT,
      s00_axi_arvalid => S_AXI_ARVALID,
      s00_axi_arready => S_AXI_ARREADY,
      s00_axi_rdata   => S_AXI_RDATA,
      s00_axi_rresp   => S_AXI_RRESP,
      s00_axi_rvalid  => S_AXI_RVALID,
      s00_axi_rready  => S_AXI_RREADY);

 -- Generate S_AXI_ACLK signal
 GENERATE_REFCLOCK : process
 begin
   wait for (ClockPeriod / 2);
   ClockCount:= ClockCount+1;
   S_AXI_ACLK <= '1';
   wait for (ClockPeriod / 2);
   S_AXI_ACLK <= '0';
 end process;

 -- Initiate process which simulates a master wanting to write.
 -- This process is blocked on a "Send Flag" (sendIt).
 -- When the flag goes to 1, the process exits the wait state and
 -- execute a write transaction.
 send : PROCESS
 BEGIN
    S_AXI_AWVALID<='0';
    S_AXI_WVALID<='0';
    S_AXI_BREADY<='0';
    loop
        wait until sendIt = '1';
        wait until S_AXI_ACLK= '0';
            S_AXI_AWVALID<='1';
            S_AXI_WVALID<='1';
        wait until (S_AXI_AWREADY and S_AXI_WREADY) = '1';  --Client ready to read address/data        
            S_AXI_BREADY<='1';
        wait until S_AXI_BVALID = '1';  -- Write result valid
            assert S_AXI_BRESP = "00" report "AXI data not written" severity failure;
            S_AXI_AWVALID<='0';
            S_AXI_WVALID<='0';
            S_AXI_BREADY<='1';
        wait until S_AXI_BVALID = '0';  -- All finished
            S_AXI_BREADY<='0';
    end loop;
 END PROCESS send;

  -- Initiate process which simulates a master wanting to read.
  -- This process is blocked on a "Read Flag" (readIt).
  -- When the flag goes to 1, the process exits the wait state and
  -- execute a read transaction.
  read : PROCESS
  BEGIN
    S_AXI_ARVALID<='0';
    S_AXI_RREADY<='0';
     loop
         wait until readIt = '1';
         wait until S_AXI_ACLK= '0';
             S_AXI_ARVALID<='1';
             S_AXI_RREADY<='1';
         wait until (S_AXI_ARREADY) = '1';  --Client provided data
         wait until S_AXI_RVALID = '1';
         wait until S_AXI_RVALID = '0';
            assert S_AXI_RRESP = "00" report "AXI data not written" severity failure;
            S_AXI_RREADY<='0';
            S_AXI_ARVALID<='0';
     end loop;
  END PROCESS read;


 -- 
 tb : PROCESS
 BEGIN
        S_AXI_ARESETN<='0';
        sendIt<='0';
    wait for 15 ns;
        S_AXI_ARESETN<='1';
    wait for ClockPeriod*2;
        S_AXI_AWADDR<=b"000000";     -- reg0 1/M
        S_AXI_WDATA<= b"00111111_10001111_10111110_01110111";   --  1.123
        S_AXI_WSTRB<= b"1111";
        sendIt<='1';                --Start AXI Write to Slave
        wait for 1 ns; sendIt<='0'; --Clear Start Send Flag
    wait until S_AXI_BVALID = '1';
    wait until S_AXI_BVALID = '0';  --AXI Write finished
        S_AXI_WSTRB<=b"0000";
            
        S_AXI_AWADDR<=b"000100";     -- reg1 K
        S_AXI_WDATA<= b"00111111_10101001_00010110_10000111";   -- 1.321
        S_AXI_WSTRB<=b"1111";
        sendIt<='1';                --Start AXI Write to Slave
        wait for 1 ns; sendIt<='0'; --Clear Start Send Flag
    wait until S_AXI_BVALID = '1';
    wait until S_AXI_BVALID = '0';  --AXI Write finished
        S_AXI_WSTRB<=b"0000";
                
        S_AXI_AWADDR<=b"001000";     -- reg2 B
        S_AXI_WDATA<= b"00111111_10001111_10111110_01110111";   -- 1.123
        S_AXI_WSTRB<=b"1111";       
        sendIt<='1';                --Start AXI Write to Slave
        wait for 1 ns; sendIt<='0'; --Clear Start Send Flag
    wait until S_AXI_BVALID = '1';  
    wait until S_AXI_BVALID = '0';  --AXI Write finished
        S_AXI_WSTRB<=b"0000";
        
        S_AXI_AWADDR<=b"001100";     -- reg1 P
        S_AXI_WDATA<= b"01000011_00101000_11101100_01000010";   -- 1.321
        S_AXI_WSTRB<=b"1111";
        sendIt<='1';                --Start AXI Write to Slave
        wait for 1 ns; sendIt<='0'; --Clear Start Send Flag
    wait until S_AXI_BVALID = '1';
    wait until S_AXI_BVALID = '0';  --AXI Write finished
        S_AXI_WSTRB<=b"0000";
        
        S_AXI_AWADDR<=b"100000";     -- reg1 setpoint
        S_AXI_WDATA<= b"00111111_10101001_00010110_10000111";   -- 1.321
        S_AXI_WSTRB<=b"1111";
        sendIt<='1';                --Start AXI Write to Slave
        wait for 1 ns; sendIt<='0'; --Clear Start Send Flag
    wait until S_AXI_BVALID = '1';
    wait until S_AXI_BVALID = '0';  --AXI Write finished
        S_AXI_WSTRB<=b"0000";
        
    wait for ClockPeriod;
        start <= '1';
    wait for ClockPeriod;
        start <= '0';
     
     wait until ready = '1';
     
     x <= b"00111111_10000000_00000000_00000000";
     xp <= b"00111111_10000000_00000000_00000000";   
     wait for ClockPeriod*2;
             start <= '1';
     wait for ClockPeriod;
         start <= '0';
         
     wait; -- will wait forever
 END PROCESS tb;

end Behavioral;