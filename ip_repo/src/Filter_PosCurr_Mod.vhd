-- Create Date: 07.04.2017 13:40:08
-- Design Name: 
-- Module Name: KalmanPos_Mod - Behavioral
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
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.numeric_std.all;

    use work.entities.all;
    use work.fpupack.all;

entity Filter_PosCurr_Mod is
    port ( 
        clk : in STD_LOGIC;
        reset :  in STD_LOGIC;
        start : in STD_LOGIC;
        z : in STD_LOGIC_VECTOR (FP_WIDTH-1 downto 0);
        x : in STD_LOGIC_VECTOR (FP_WIDTH-1 downto 0);
        busy : out STD_LOGIC ;
        ready : out STD_LOGIC ;
        z_p : out STD_LOGIC_VECTOR (FP_WIDTH-1 downto 0);
        v_p : out STD_LOGIC_VECTOR (FP_WIDTH-1 downto 0);
        y_p : out STD_LOGIC_VECTOR (FP_WIDTH-1 downto 0)
    );
end Filter_PosCurr_Mod;

architecture Behavioral of Filter_PosCurr_Mod is

    -- AddSub_1 signals
    signal opA_as1   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal opB_as1   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal op_as1      : std_logic;
    signal start_as1 : std_logic :='0';
    signal out_as1   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal ready_as1 : std_logic;
    -- AddSub_2 signals
    signal opA_as2   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal opB_as2   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal op_as2     : std_logic;
    signal start_as2 : std_logic :='0';
    signal out_as2   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal ready_as2 : std_logic ;
    -- Multiplier signals
    signal start_mul : std_logic := '0';
    signal opA_mul : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal opB_mul : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal out_mul : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal ready_mul : std_logic := '0';
    -- Divider signals
    signal start_div : std_logic := '0';
    signal opA_div   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal opB_div   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal out_div   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal ready_div : std_logic := '0';
    -- Constant
    constant DEG_ADC : std_logic_vector(FP_WIDTH-1 downto 0)                := "001110110001101100110111100";   -- DEG_ADC = (90º)/(60000-22000)
    constant center_current_const : std_logic_vector(FP_WIDTH-1 downto 0)   := "010001110000111010000110001";   -- 36486.206
    constant mA_ADC : std_logic_vector(FP_WIDTH-1 downto 0)                 := "001111111110111011001011111";   -- mA_ADC = 0.0018656*1000

    -- State Machine State Definition
    type   t_state is ( Idle,
                        adc2val_1, adc2val_2, adc2val_3, adc2val_4,
                        Calc_xp_Pp_0, Calc_xp_Pp_1, Calc_xp_Pp_2, Calc_xp_Pp_3, Calc_xp_Pp_4, Calc_xp_Pp_5, 
                        Calc_zp_vp_1, Calc_zp_vp_2, Calc_zp_vp_3, Calc_zp_vp_4, Calc_zp_vp_5, Calc_zp_vp_6, 
                        Calc_P_1, Calc_P_2, Calc_P_3, Calc_P_4, Calc_P_5, Calc_P_6, Calc_P_7);
    signal state : t_state;

    -- Constants
    constant dt : std_logic_vector(FP_WIDTH-1 downto 0) := "001110111010001111010111000";   -- dt = 0.005 
    constant R : std_logic_vector(FP_WIDTH-1 downto 0)   := "001110100101100010111000111";    -- R = 8.2673e-04 
     
     -- nQ = 3 
    constant Q_0 : std_logic_vector(FP_WIDTH-1 downto 0) := "001100000000000011011001010";    -- (nQ*dt^4)/4  
    constant Q_1 : std_logic_vector(FP_WIDTH-1 downto 0) := "001101000100100101010011100";    -- (nQ*dt^3)/2 
    constant Q_2 : std_logic_vector(FP_WIDTH-1 downto 0) := "001101000100100101010011100";    -- (nQ*dt^3)/2  
    constant Q_3 : std_logic_vector(FP_WIDTH-1 downto 0) := "001110001001110101001001010";    --  nQ*dt 
    
    constant b0 : std_logic_vector(FP_WIDTH-1 downto 0)  := "001111001110000101000111101";    --  0.0275 
    constant b1 : std_logic_vector(FP_WIDTH-1 downto 0)  := "001111001110000101000111101";    --  0.0275 
    constant a1 : std_logic_vector(FP_WIDTH-1 downto 0)  := "101111110111000111101011100";    --  -0.9450
        
    -- General signals
    signal my_x_0 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_x_1 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');

    signal xp_0 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal xp_1 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    
    signal P_0 : std_logic_vector(FP_WIDTH-1 downto 0) := "001110100101100010111000111";    -- R = 8.2673e-04(others => '0');
    signal P_1 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal P_2 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal P_3 : std_logic_vector(FP_WIDTH-1 downto 0) := "001110100101100010111000111";    -- R = 8.2673e-04
        
    signal Pp_0 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal Pp_1 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal Pp_2 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal Pp_3 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');

    signal my_z : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal dtP_3 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal P_0_Q_0 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal R_Pp : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal xp_z : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal K_0 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal K_1 : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');

    signal my_x : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_y_p : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal x_ant : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal y_ant : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal b0_x : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    
    
begin

    AddSub_1: addsubfsm_v6
        port map (reset         => reset,
                  clk           => clk,
                  op            => op_as1,
                  op_a          => opA_as1,
                  op_b          => opB_as1,
                  start_i       => start_as1,
                  addsub_out    => out_as1,
                  ready_as      => ready_as1);

    AddSub_2: addsubfsm_v6
        port map (reset         => reset,
                  clk           => clk,
                  op            => op_as2,
                  op_a          => opA_as2,
                  op_b          => opB_as2,
                  start_i       => start_as2,
                  addsub_out    => out_as2,
                  ready_as      => ready_as2);

    Multiplier: multiplierfsm_v2
        port map (reset         => reset,
                  clk           => clk,
                  op_a          => opA_mul,
                  op_b          => opB_mul,
                  start_i       => start_mul,
                  mul_out       => out_mul,
                  ready_mul     => ready_mul);

    Divider: divNR
        port map (reset         => reset,
                  clk           => clk,
                  op_a          => opA_div,
                  op_b          => opB_div,
                  start_i       => start_div,
                  div_out       => out_div,
                  ready_div     => ready_div);

    process(clk,reset) is
    begin
        if rising_edge(clk) then
            if reset='1' then
                state   <= Idle;
                
                start_as1  <= '0';
                op_as1     <= '0';
                opA_as1    <= (others => '0');
                opB_as1    <= (others => '0');
                start_as1  <= '0';
                op_as1     <= '0';
                opA_as1    <= (others => '0');
                opB_as1    <= (others => '0');

                start_mul  <= '0';
                opA_mul    <= (others => '0');
                opB_mul    <= (others => '0');

                start_div  <= '0';
                opA_div    <= (others => '0');
                opB_div    <= (others => '0');

                my_x_0  <= (others => '0');
                my_x_1  <= (others => '0');
                P_0     <= R;
                P_1     <= (others => '0');
                P_2     <= (others => '0');
                P_3     <= R;

                Pp_0    <= (others => '0');
                Pp_1    <= (others => '0');
                Pp_2    <= (others => '0');
                Pp_3    <= (others => '0');

                dtP_3   <= (others => '0');
                P_0_Q_0 <= (others => '0');
                R_Pp    <= (others => '0');
                xp_z    <= (others => '0');
                K_0     <= (others => '0');
                K_1     <= (others => '0');
                
                my_x    <= (others => '0');
                my_y_p  <= (others => '0');
                x_ant   <= (others => '0'); 
                y_ant   <= (others => '0'); 
                b0_x    <= (others => '0'); 

                z_p <= z;
                v_p <= (others => '0');
                y_p <= (others => '0');
            else
                case state is
                    when Idle =>
                        if ( start = '1') then
                            start_mul <= '1';
                            opA_mul <= z;
                            opB_mul <= DEG_ADC;
    
                            start_as2 <= '1';
                            op_as2 <= '1';
                            opA_as2 <= x;
                            opB_as2 <= center_current_const;
                            
                            state <= adc2val_1;
                              
                        else
                            state <= Idle;
                            busy <= '0';
                            ready <= '0';
                        end if; 
                        
                    when adc2val_1 =>
                        start_mul <= '0';
                        start_as2 <= '0';
                        if (ready_mul = '1' and ready_as2 = '1') then
                            my_z <= out_mul;
                            
                            start_mul <= '1';
                            opA_mul <= out_as2;
                            opB_mul <= mA_ADC;
                            
                            state <= adc2val_2;
                        else
                            state <= adc2val_1;
                        end if;
                    
                    when adc2val_2 =>
                        start_mul <= '0';
                        if (ready_mul = '1') then
                            state <= Calc_xp_Pp_0 ;
                            my_x <= out_mul;
                        else
                            state <= adc2val_2;
                        end if;
                    
                    when Calc_xp_Pp_0 =>
                    
                        --xp_1 <= my_x_1;

                        start_mul <= '1';
                        opA_mul <= my_x_1;
                        opB_mul <= dt;

                        start_as1    <= '1';
                        op_as1 <= '0';
                        opA_as1 <= P_0;
                        opB_as1 <= Q_0;

                        start_as2    <= '1';
                        op_as2 <= '0';
                        opA_as2 <= P_3;
                        opB_as2 <= Q_3;

--                            my_z <= z;
--                            my_x <= x;

                        state <= Calc_xp_Pp_1;                            

                    when Calc_xp_Pp_1 =>
                        start_mul <= '0';
                        start_as1 <= '0';
                        start_as2 <= '0';

                        if (ready_as1 = '1' and ready_mul = '1' and ready_as2 = '1') then

                            start_as1 <= '1';
                            op_as1 <= '0';
                            opA_as1 <= out_mul;
                            opB_as1 <= my_x_0;

                            P_0_Q_0 <= out_as1;

                            start_mul <= '1';
                            opA_mul <= P_3;
                            opB_mul <= dt;

                            Pp_3 <= out_as2;

                            start_as2 <= '1';
                            op_as2 <= '0';
                            opA_as2 <= P_1;
                            opB_as2 <= Q_1;

                            state <= Calc_xp_Pp_2;
                        else
                            state <= Calc_xp_Pp_1;
                        end if;

                    when Calc_xp_Pp_2 =>
                        start_mul <= '0';
                        start_as1 <= '0';
                        start_as2 <= '0';
                        if (ready_as1 = '1' and ready_mul = '1' and ready_as2 = '1') then

                            xp_0 <= out_as1;

                            start_as1 <= '1';
                            op_as1 <= '0';
                            opA_as1 <= out_mul;
                            opB_as1 <= P_1;

                            start_mul <= '1';
                            opA_mul <= P_2;
                            opB_mul <= dt;

                            start_as2 <= '1';
                            op_as2 <= '0';
                            opA_as2 <= out_mul;
                            opB_as2 <= out_as2;

                            dtP_3 <= out_mul;

                            state <= Calc_xp_Pp_3;
                        else
                            state <= Calc_xp_Pp_2;    
                        end if; 

                    when Calc_xp_Pp_3 =>
                        start_mul <= '0';
                        start_as1 <= '0';
                        start_as2 <= '0';
                        if (ready_as1 = '1' and ready_mul = '1' and ready_as2 = '1') then

                            start_as1 <= '1';
                            op_as1 <= '0';
                            opA_as1 <= out_mul;
                            opB_as1 <= P_0_Q_0;

                            start_mul <= '1';
                            opA_mul <= out_as1;
                            opB_mul <= dt;

                            Pp_1 <= out_as2;

                            start_as2 <= '1';
                            op_as2 <= '0';
                            opA_as2 <= P_2;
                            opB_as2 <= Q_2;

                            state <= Calc_xp_Pp_4;
                        else
                            state <= Calc_xp_Pp_3;
                        end if;

                    when Calc_xp_Pp_4 =>
                        start_mul <= '0';
                        start_as1 <= '0';
                        start_as2 <= '0';
                        if (ready_as1 = '1' and ready_mul = '1' and ready_as2 = '1') then

                            start_as1 <= '1';
                            op_as1 <= '0';
                            opA_as1 <= out_as1;
                            opB_as1 <= out_mul;

                            start_as2 <= '1';
                            op_as2 <= '0';
                            opA_as2 <= dtP_3;
                            opB_as2 <= out_as2;
                            
                            start_mul <= '1';
                            opA_mul <= my_x;
                            opB_mul <= b0;

                            state <= Calc_xp_Pp_5;
                        else
                            state <= Calc_xp_Pp_4;
                        end if;

                    when Calc_xp_Pp_5 =>
                        start_mul <= '0';
                        start_as1 <= '0';
                        start_as2 <= '0';
                        if (ready_as1 = '1' and ready_as2 = '1' and ready_mul = '1') then
                        
                            b0_x <= out_mul;
                            Pp_0 <= out_as1;
                            Pp_2 <= out_as2;

                            state <= Calc_zp_vp_1;
                        else
                            state <= Calc_xp_Pp_5;
                        end if;

                    when Calc_zp_vp_1 =>
                        
                        start_as1 <= '1';
                        op_as1 <= '0';
                        opA_as1 <= Pp_0;
                        opB_as1 <= R;

                        start_as2 <= '1';
                        op_as2 <= '1';
                        opA_as2 <= my_z;
                        opB_as2 <= xp_0;

                        start_mul <= '1';
                        opA_mul <= x_ant;
                        opB_mul <= b1;
                    
                        state <= Calc_zp_vp_2;

                    when Calc_zp_vp_2 =>
                        start_mul <= '0';
                        start_as1 <= '0';
                        start_as2 <= '0';
                        if (ready_as1 = '1' and ready_as2 = '1' and ready_mul = '1') then

                            start_div <= '1';
                            opA_div <= Pp_0;
                            opB_div <= out_as1;
                            
                            start_as1 <= '1';
                            op_as1 <= '0';
                            opA_as1 <= out_mul;
                            opB_as1 <= b0_x;
                            
                            start_mul <= '1';
                            opA_mul <= y_ant;
                            opB_mul <= a1;
                            
                            R_Pp <= out_as1;

                            xp_z <= out_as2;

                            state <= Calc_zp_vp_3;
                        else
                            state <= Calc_zp_vp_2;
                        end if;

                    when Calc_zp_vp_3 =>
                        start_div <= '0';
                        start_as1 <= '0';
                        start_mul <= '0';
                        if (ready_div = '1') then

                            K_0 <= out_div;

                            start_div <= '1';
                            opA_div <= Pp_2;
                            opB_div <= R_Pp;                            

                            start_mul <= '1';
                            opA_mul <= xp_z;
                            opB_mul <= out_div;
                            
                            start_as1 <= '1';
                            op_as1 <= '1';
                            opA_as1 <= out_as1;
                            opB_as1 <= out_mul;

                            state <= Calc_zp_vp_4;

                        else
                            state <= Calc_zp_vp_3;

                        end if;

                    when Calc_zp_vp_4 =>
                        start_div <= '0';
                        start_mul <= '0';
                        start_as1 <= '0';
                        if (ready_div = '1') then

                            K_1 <= out_div;
                            
                            my_y_p <= out_as1;

                            start_as1 <= '1';
                            op_as1 <= '0';
                            opA_as1 <= xp_0;
                            opB_as1 <= out_mul;

                            start_mul <= '1';
                            opA_mul <= out_div;
                            opB_mul <= xp_z;

                            state <= Calc_zp_vp_5;
                        else
                            state <= Calc_zp_vp_4;
                        end if; 

                    when Calc_zp_vp_5 =>
                        start_as1 <= '0';
                        start_mul <= '0';
                        if (ready_as1 = '1' and ready_mul = '1') then
                            my_x_0 <= out_as1;

                            start_as1 <= '1';
                            op_as1 <= '0';
                            opA_as1 <= my_x_1;
                            opB_as1 <= out_mul;

                            state <= Calc_zp_vp_6;
                        else
                            state <= Calc_zp_vp_5;
                        end if;

                    when Calc_zp_vp_6 =>
                        start_as1 <= '0';
                        if (ready_as1 = '1') then
                        
                            my_x_1 <= out_as1;
                            
                            y_p <= my_y_p;
                            
                            z_p <= my_x_0;
                            v_p <= out_as1;
                            
                            x_ant <= my_x;
                            y_ant <= my_y_p;
                            
                            state <= Calc_P_1;
                        else
                            state <= Calc_zp_vp_6;
                        end if; 

                    when Calc_P_1 =>

                        start_mul <= '1';
                        opA_mul <= K_0;
                        opB_mul <= Pp_0;

                        state <= Calc_P_2;

                    when Calc_P_2 =>
                        start_mul <= '0';
                        if (ready_mul = '1') then

                            start_as1 <= '1';
                            op_As1 <= '1';
                            opA_as1 <= Pp_0;
                            opB_as1 <= out_mul;

                            start_mul <= '1';
                            opA_mul <= K_0;
                            opB_mul <= Pp_1;

                            state <= Calc_P_3;
                        else
                            state <= Calc_P_2;

                        end if;

                    when Calc_P_3 =>
                        start_as1 <= '0';
                        start_mul <= '0';
                        if (ready_as1 = '1' and ready_as1 = '1') then

                            P_0 <= out_as1;

                            start_as1 <= '1';
                            op_as1 <= '1';
                            opA_as1 <= Pp_1;
                            opB_as1 <= out_mul;

                            start_mul <= '1';
                            opA_mul <= K_1;
                            opB_mul <= Pp_0;

                            state <= Calc_P_4;
                        else
                            state <= Calc_P_3;
                        end if; 

                    when Calc_P_4 =>
                        start_as1 <= '0';
                        start_mul <= '0';
                        if (ready_as1 = '1' and ready_mul = '1') then

                            P_1 <= out_as1;

                            start_as1 <= '1';
                            op_as1 <= '1';
                            opA_as1 <= Pp_2;
                            opB_As1 <= out_mul;

                            start_mul <= '1';
                            opA_mul <= K_1;
                            opB_mul <= Pp_1;

                            state <= Calc_P_5;
                        else
                            state <= Calc_P_4;
                        end if; 

                    when Calc_P_5 =>
                        start_as1 <= '0';
                        start_mul <= '0';
                        if (ready_as1 = '1' and ready_mul = '1') then

                            P_2 <= out_as1;

                            start_as1 <= '1';
                            op_as1 <= '1';
                            opA_as1 <= Pp_3;
                            opB_As1 <= out_mul;

                            state <= Calc_P_6;
                        else
                            state <= Calc_P_5;
                        end if; 

                    when Calc_P_6 =>
                        start_as1 <= '0';

                        if (ready_as1 = '1') then
                            P_3 <= out_as1;
                            
                            ready <= '1';
                            busy <= '0';
                            state <= Idle;
                        else
                            state <= Calc_P_6;
                        end if;

                    when others =>
                        state <= Idle;

                end case; 
            end if;
        end if;
    end process;

end Behavioral;
