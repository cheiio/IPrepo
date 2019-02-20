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
           current : out STD_LOGIC_VECTOR (SINGLE_WIDTH-1 downto 0)
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
            y_p : out STD_LOGIC_VECTOR(FP_WIDTH - 1 downto 0)
        );
    end component;
    
--    -- AddSub signals
--    signal opA_as   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
--    signal opB_as   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
--    signal op_as    : std_logic;
--    signal start_as : std_logic :='0';
--    signal out_as   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
--    signal ready_as : std_logic;

--    -- Multiplier signals
--    signal start_mul : std_logic := '0';
--    signal opA_mul : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
--    signal opB_mul : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
--    signal out_mul : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
--    signal ready_mul : std_logic := '0';
   
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
    
--    -- Constant
--    constant RAD_ADC : std_logic_vector(FP_WIDTH-1 downto 0)                := "001110000010110101100000111";   -- RAD_ADC = (pi/2)/(60000-22000)
--    constant center_current_const : std_logic_vector(FP_WIDTH-1 downto 0)   := "010001110000111010000110001";   -- 36486.206
--    constant A_ADC : std_logic_vector(FP_WIDTH-1 downto 0)                  := "001110101111010010000111001";   -- A_ADC = 0.0018656
    
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
           y_p      => y_current
       );
    
--    AddSub: addsubfsm_v6
--       port map (reset         => rst,
--                 clk           => clk,
--                 op            => op_as,
--                 op_a          => opA_as,
--                 op_b          => opB_as,
--                 start_i       => start_as,
--                 addsub_out    => out_as,
--                 ready_as      => ready_as
--     );

--    Multiplier: multiplierfsm_v2
--       port map (reset         => rst,
--                 clk           => clk,
--                 op_a          => opA_mul,
--                 op_b          => opB_mul,
--                 start_i       => start_mul,
--                 mul_out       => out_mul,
--                 ready_mul     => ready_mul
--     );
                 
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
                 
                 --y_current <= (others => '0');
                 --z_position <= (others => '0');
                 start_filter <= '0';

--                 opA_mul <= (others => '0');
--                 opB_mul <=  (others => '0');
--                 start_mul <= '0';

             else
                 case stateSensor is
                     when Idle =>
                         if (start = '1') then
                             
                             my_positionSen(FP_WIDTH-1)  <= positionSen(SINGLE_WIDTH-1);
                             my_positionSen(EXP_SIN2CUS_1 downto EXP_SIN2CUS_2)  <= positionSen(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4);
                             my_positionSen(FRAC_SIN2CUS_1 downto FRAC_SIN2CUS_2)  <= positionSen(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
                             
                             my_currentSen(FP_WIDTH-1)  <= currentSen(SINGLE_WIDTH-1);
                             my_currentSen(EXP_SIN2CUS_1 downto EXP_SIN2CUS_2)  <= currentSen(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4);
                             my_currentSen(FRAC_SIN2CUS_1 downto FRAC_SIN2CUS_2)  <= currentSen(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4);
                             
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
                            
                            my_position(SINGLE_WIDTH-1) <= z_p_position(FP_WIDTH-1) ; 
                            my_position(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) <= z_p_position(EXP_SIN2CUS_1 downto EXP_SIN2CUS_2) ; 
                            my_position(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4) <= z_p_position(FRAC_SIN2CUS_1 downto FRAC_SIN2CUS_2) ; 
                            
                            my_velocity(SINGLE_WIDTH-1) <= v_p_position(FP_WIDTH-1) ; 
                            my_velocity(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) <= v_p_position(EXP_SIN2CUS_1 downto EXP_SIN2CUS_2) ; 
                            my_velocity(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4) <= v_p_position(FRAC_SIN2CUS_1 downto FRAC_SIN2CUS_2) ; 
                            
                            my_current(SINGLE_WIDTH-1) <= y_current(FP_WIDTH-1) ; 
                            my_current(EXP_SIN2CUS_3 downto EXP_SIN2CUS_4) <= y_current(EXP_SIN2CUS_1 downto EXP_SIN2CUS_2) ; 
                            my_current(FRAC_SIN2CUS_3 downto FRAC_SIN2CUS_4) <= y_current(FRAC_SIN2CUS_1 downto FRAC_SIN2CUS_2) ; 
                            
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
