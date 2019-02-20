----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.06.2017 13:24:01
-- Design Name: 
-- Module Name: SensorMod - Behavioral
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


entity SensorMod is
    Port ( 
           clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start : in STD_LOGIC;
           positionSen : in STD_LOGIC_VECTOR (SINGLE_WIDTH-1 downto 0);
           currentSen : in STD_LOGIC_VECTOR (SINGLE_WIDTH-1 downto 0);
           volts : in STD_LOGIC_VECTOR (SINGLE_WIDTH-1 downto 0);
           
           busy : out STD_LOGIC;
           ready : out STD_LOGIC;
           
           position : out STD_LOGIC_VECTOR (SINGLE_WIDTH-1 downto 0);
           velocity : out STD_LOGIC_VECTOR (SINGLE_WIDTH-1 downto 0);
           current : out STD_LOGIC_VECTOR (SINGLE_WIDTH-1 downto 0);
           
           dt_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           R_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           center_current_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           Q_0_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           Q_12_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           Q_3_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           b01_conf : in std_logic_vector(FP_WIDTH-1 downto 0);
           a1_conf : in std_logic_vector(FP_WIDTH-1 downto 0)
           );
end SensorMod;

architecture Behavioral of SensorMod is
    
    component Filter_PosCurr_Mod is
        port(
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            start : in STD_LOGIC;
            z : in STD_LOGIC_VECTOR(FP_WIDTH - 1 downto 0);
            x : in STD_LOGIC_VECTOR(FP_WIDTH - 1 downto 0);
            busy : out STD_LOGIC;
            ready : out STD_LOGIC;
            z_p : out STD_LOGIC_VECTOR(FP_WIDTH - 1 downto 0);
            v_p : out STD_LOGIC_VECTOR(FP_WIDTH - 1 downto 0);
            y_p : out STD_LOGIC_VECTOR(FP_WIDTH - 1 downto 0);
            
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
       
   --Signal 
    signal my_positionSen : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_currentSen : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_volts : std_logic := '0';
    
    signal my_position : std_logic_vector(SINGLE_WIDTH-1 downto 0) := (others => '0');
    signal my_velocity : std_logic_vector(SINGLE_WIDTH-1 downto 0) := (others => '0');
    signal my_current : std_logic_vector(SINGLE_WIDTH-1 downto 0) := (others => '0');
        
   --Signals Filters
    signal start_filter: STD_LOGIC := '0';
    signal z_position: STD_LOGIC_VECTOR(FP_WIDTH - 1 downto 0) := (others => '0');
    signal x_current: STD_LOGIC_VECTOR(FP_WIDTH - 1 downto 0) := (others => '0');
    signal busy_filter: STD_LOGIC := '0';
    signal ready_filter: STD_LOGIC := '0';
    signal z_p_position: STD_LOGIC_VECTOR(FP_WIDTH - 1 downto 0) := (others => '0');
    signal v_p_position: STD_LOGIC_VECTOR(FP_WIDTH - 1 downto 0) := (others => '0');
    signal y_current: STD_LOGIC_VECTOR(FP_WIDTH - 1 downto 0);
    
    -- Constant    
    signal dt_conf_reg : std_logic_vector(FP_WIDTH-1 downto 0);
    signal R_conf_reg : std_logic_vector(FP_WIDTH-1 downto 0);
    signal center_current_conf_reg : std_logic_vector(FP_WIDTH-1 downto 0);
    signal Q_0_conf_reg : std_logic_vector(FP_WIDTH-1 downto 0);
    signal Q_12_conf_reg : std_logic_vector(FP_WIDTH-1 downto 0);
    signal Q_3_conf_reg : std_logic_vector(FP_WIDTH-1 downto 0);
    signal b01_conf_reg : std_logic_vector(FP_WIDTH-1 downto 0);
    signal a1_conf_reg : std_logic_vector(FP_WIDTH-1 downto 0);
        
    constant EXP_SIN2CUS_1 : integer := FP_WIDTH - 2;
    constant EXP_SIN2CUS_2 : integer := FP_WIDTH - EXP_WIDTH - 1;
    constant EXP_SIN2CUS_3 : integer := SINGLE_FRAC_WIDTH + EXP_WIDTH - 1;
    constant EXP_SIN2CUS_4 : integer := SINGLE_FRAC_WIDTH;
    
    constant FRAC_SIN2CUS_1 : integer := FRAC_WIDTH - 1;
    constant FRAC_SIN2CUS_2 : integer := 0;
    constant FRAC_SIN2CUS_3 : integer := SINGLE_FRAC_WIDTH - 1;
    constant FRAC_SIN2CUS_4 : integer := SINGLE_FRAC_WIDTH - FRAC_WIDTH;
        
    type t_state1 is (Idle, state_1, state_2, state_3);
    signal stateSensor : t_state1;
begin

    Filter_PosCurr_Mod_inst: Filter_PosCurr_Mod
       port map (
           clk      => clk,
           reset    => rst,
           start    => start_filter,
           z        => z_position,
           x        => x_current,
           busy     => busy_filter,
           ready    => ready_filter,
           z_p      => z_p_position,
           v_p      => v_p_position,
           y_p      => y_current,
           
           dt_conf  => dt_conf,
           R_conf => R_conf,
           center_current_conf => center_current_conf,
           Q_0_conf => Q_0_conf,
           Q_12_conf => Q_12_conf,
           Q_3_conf => Q_3_conf,
           b01_conf => b01_conf,
           a1_conf => a1_conf
       );
    
    process(clk,rst) is
     begin
         if rising_edge(clk) then
             if rst = '1' then
                stateSensor   <= Idle;
                
                position <= (others => '0');
                velocity <= (others => '0');
                current <= (others => '0');
                ready <= '0';
                busy <= '0';
                
                my_positionSen <= (others => '0');
                my_currentSen <= (others => '0');
                
                my_volts <= volts(SINGLE_WIDTH-1);
                
                start_filter <= '0';

             else
                 case stateSensor is
                     when Idle =>
                         if (start = '1') then
                             
                             my_positionSen <= positionSen(SINGLE_WIDTH-1 downto SINGLE_WIDTH - FP_WIDTH);
                             my_currentSen <= currentSen(SINGLE_WIDTH-1 downto SINGLE_WIDTH - FP_WIDTH);
                             my_volts <= volts(SINGLE_WIDTH-1);
                             
                             stateSensor <= state_1;
                             
                             busy <= '1';
                             ready <= '0';
    
                         else
                            stateSensor <= Idle; 
                            ready <= '0';                                  
                         end if;

                     when state_1 =>
                             
                        z_position <= my_positionSen;
                        x_current <= my_currentSen;
                        start_Filter <= '1';
                        
                        stateSensor <= state_2;
                        
                     when state_2 =>
                     
                        start_Filter <= '0';
                        if (ready_Filter = '1')  then
                            
                            my_position <= z_p_position & "00000"; 
                            my_velocity <= v_p_position & "00000"; 
                            my_current(SINGLE_WIDTH-1) <= my_volts; 
                            my_current(SINGLE_WIDTH-2 downto 0) <= y_current(FP_WIDTH-2 downto 0) & "00000"; 
                            
                            stateSensor <= state_3;
                            
                        else
                            stateSensor <= state_2;
                        end if;
                        
                        when state_3 =>
                            position <= my_position;
                            velocity <= my_velocity;
                            current <= my_current;
                            
                            busy <= '0'; 
                            ready <= '1'; 
                            
                            stateSensor <= Idle;

                     when others => stateSensor <= Idle;
                 end case;
                                     
             end if;
         end if;
 end process;

end Behavioral;
