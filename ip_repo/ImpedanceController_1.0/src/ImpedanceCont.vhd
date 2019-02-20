library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.numeric_std.all;

    use work.entities.all;
    use work.fpupack.all;

entity ImpedanceCont is
    --generic (
     --   volt2pwm : std_logic_vector(FP_WIDTH-1 downto 0) := "010000110000000000000000000" -- 1024/8
    --);
    port (
        clk: in  std_logic;
        rst: in  std_logic;
        start: in std_logic;
        
        outMax   : in std_logic_vector(FP_WIDTH-1 downto 0) := "010001000111111111000000000"; -- 
        outMin   : in std_logic_vector(FP_WIDTH-1 downto 0) := "110001000111111111000000000"; -- 
        
        M        : in std_logic_vector(FP_WIDTH-1 downto 0) := "001111111111001000111101000"; -- 1/0.5284
        K        : in std_logic_vector(FP_WIDTH-1 downto 0) := "010000101011000100111100000"; -- 88.6173
        B        : in std_logic_vector(FP_WIDTH-1 downto 0) := "010000010001100101001000001"; -- 9.5801
        --P        : in std_logic_vector(FP_WIDTH-1 downto 0) := "001111110000000100100000010"; -- 0.504
        P        : in std_logic_vector(FP_WIDTH-1 downto 0) := "010000110010100011101100010"; -- 0.504*1023/8
        dt       : in std_logic_vector(FP_WIDTH-1 downto 0) := "001110111010001111010111000";   -- dt = 0.005 
        dt_half  : in std_logic_vector(FP_WIDTH-1 downto 0) := "001110110010001111010111000";   -- dt/2
        
        input: in std_logic_vector(FP_WIDTH-1 downto 0);
        setpoint: in std_logic_vector(FP_WIDTH-1 downto 0);
        
        x: in std_logic_vector(FP_WIDTH-1 downto 0);
        xp: in std_logic_vector(FP_WIDTH-1 downto 0);
        
        ready: out std_logic;
        busy: out std_logic;
        output: out std_logic_vector(FP_WIDTH-1 downto 0)
    );
end entity;

architecture behavioral of ImpedanceCont is
    -- AddSub signals
    signal opA_as   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal opB_as   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal op_as    : std_logic;
    signal start_as : std_logic;
    signal out_as   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal ready_as : std_logic;

    -- Multiplier signals
    signal start_mul: std_logic := '0';
    signal opA_mul  : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal opB_mul  : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal out_mul  : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal ready_mul: std_logic := '0';
    
    -- Signals
    signal my_x         : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_xp         : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_input     : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_setPoint  : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    
    signal last_x   : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal last_xp  : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal last_xpp : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    --signal x        : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    --signal xp       : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    --signal xpp      : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal my_outMax   : std_logic_vector(FP_WIDTH-1 downto 0) ; -- 
    signal my_outMin   : std_logic_vector(FP_WIDTH-1 downto 0) ; -- 
    --signal f_error  : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal x_error  : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    
    signal myM      : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal myB      : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal myK      : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal myP      : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal mydt      : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    signal mydt_half      : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    
    signal myK_x    : std_logic_vector(FP_WIDTH-1 downto 0) := (others => '0');
    
    -- Constants
    type t_state is (Idle, state_1, state_2, state_3, state_4, state_5, state_6, state_7,
                           state_8, state_9, state_10, state_11, state_12, state_13, state_14, state_15, state_16);
    signal state : t_state;
    
begin
    AddSub: addsubfsm_v6
        port map (reset         => rst,
                  clk           => clk,
                  op            => op_as,
                  op_a          => opA_as,
                  op_b          => opB_as,
                  start_i       => start_as,
                  addsub_out    => out_as,
                  ready_as      => ready_as);

    Multiplier: multiplierfsm_v2
        port map (reset         => rst,
                  clk           => clk,
                  op_a          => opA_mul,
                  op_b          => opB_mul,
                  start_i       => start_mul,
                  mul_out       => out_mul,
                  ready_mul     => ready_mul);
    
    process(clk,rst)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                state <= Idle;
                busy <= '0';
                output <= (others => '0');
                ready <= '0';
                
                start_as    <= '0';
                op_as       <= '0';
                opA_as      <= (others => '0');
                opB_as      <= (others => '0');

                start_mul   <= '0';
                opA_mul     <= (others => '0');
                opB_mul     <= (others => '0');
                
                myM <= M;
                myB <= B;
                myK <= K;
                myP <= P;
                mydt <= dt;
                mydt_half <= dt_half;
                my_outMax <= outMax;
                my_outMin <= outMin;
                
                last_x <= (others => '0');
                last_xp <= (others => '0');
                last_xpp <= (others => '0');
                
                x_error     <= (others => '0');
            else
                case state is
                    when Idle =>
                        if (start = '1') then
                            
                            start_as <= '1';
                            op_as <= '1';
                            opA_as <= last_x;
                            opB_as <= x;
                            
                            my_x <= x;
                            my_xp <= xp;
                            
                            state <= state_1;
                            
                            busy <= '1';
                            ready <= '0';
                        else
                            busy <= '0';
                            ready <= '0';
                            
                            state <= Idle;

                        end if;
                    when state_1 => 
                        start_as <= '0';
                        if (ready_as = '1') then

                            start_mul <= '1';
                            opA_mul <= myK;
                            opB_mul <= out_as;
                            
                            start_as <= '1';
                            op_as <= '1';
                            opA_as <= last_xp;
                            opB_as <= my_xp;
                            
                            state <= state_2;
                            
                        else
                            state <= state_1;

                        end if;
                        
                    when state_2 => 
                        start_mul <= '0';
                        start_as <= '0';
                        if (ready_mul = '1' and ready_as = '1') then
                            
                            start_as <= '1';
                            op_as <= '1';
                            opA_as <= setpoint;
                            opB_as <= input;

                            x_error <= out_mul;
                            
                            start_mul <= '1';
                            opA_mul <= out_as;
                            opB_mul <= myB;

                            state <= state_3;
                            
                        else
                            state <= state_2;

                        end if;

                    when state_3 => 
                        start_as <= '0';
                        start_mul <= '0';
                        if (ready_mul = '1' and ready_as = '1') then
                            
                            start_as <= '1';
                            op_as <= '1'; 
                            opA_as <= out_as;
                            opB_as <= out_mul;

                            state <= state_4;
                        else
                            state <= state_3;

                        end if;

                    when state_4 => 
                        start_as <= '0';
                        if (ready_as = '1') then
                            
                            start_as <= '1';
                            op_as <= '1';
                            opA_as <= out_as;
                            opB_as <= x_error;
                            
                            state <= state_5;
                            
                        else
                            state <= state_4;

                        end if;

                    when state_5 => 
                        start_as <= '0';
                        if (ready_as = '1') then
                            
                            start_mul <= '1';
                            opA_mul <= myM;
                            opB_mul <= out_as;
                            
                            state <= state_6;
                            
                        else
                            state <= state_5;

                        end if;

                    when state_6 => 
                        start_mul <= '0';
                        if (ready_mul = '1') then
                            
                            start_as <=  '1';
                            op_as <= '0';
                            opA_as <= last_xpp;
                            opB_as <= out_mul;
                            
                            last_xpp <= out_mul;
                            
                            state <= state_7;
                        else
                            state <= state_6;
                        end if;

                    when state_7 => 
                        start_as <= '0';
                        if (ready_as = '1') then
                            
                            start_mul <= '1';
                            opA_mul <= mydt_half;
                            opB_mul <= out_mul;
                            
                            state <= state_8;
                            
                        else
                            state <= state_7;

                        end if; 

                    when state_8 => 
                        start_mul <= '0';
                        if (ready_mul = '1') then
                            
                            start_as <= '1';
                            op_as <= '0';
                            opA_as <= last_xp;
                            opB_as <= out_mul;
                                                        
                            state <= state_9;
                            
                        else
                            state <= state_8;

                        end if;

                    when state_9 => 
                        start_as <= '0';
                        if (ready_as = '1') then
                            last_xp <= out_as;
                            
                            start_as <= '1';
                            op_as <= '0';
                            opA_as <= out_as;
                            opB_as <= last_xp;
                            
                            state <= state_10;
                        else
                            state <= state_9;

                        end if;

                    when state_10 => 
                        start_as <= '0';
                        if (ready_as = '1') then
                            
                            start_mul <= '1';
                            opA_mul <= mydt_half;
                            opB_mul <= out_as;
                            
                            state <= state_11;
                        else
                            state <= state_10;
                          
                        end if;

                    when state_11 => 
                        start_mul <= '0';
                        if (ready_mul = '1') then
                            
                            start_as <= '1';
                            op_as <= '0';
                            opA_as <= out_mul;
                            opB_as <= last_x;
                            
                            state <= state_12;

                        else
                            state <= state_11;

                        end if;

                    when state_12 =>
                        start_as <= '0';
                        if (ready_as = '1') then
                            
                            start_as <= '1';
                            op_as <= '1';
                            opA_as <= out_as;
                            opB_as <= my_x;
                            
                            last_x <= out_as;
                            state <= state_13;
                            
                        else
                            state <= state_12;

                        end if;  
                    when state_13 =>
                        start_as <= '0';
                        if ready_as = '1' then
                            start_mul <= '1';
                            opA_mul <= out_as;
                            opB_mul <= myP;
                            
                            state <= state_14;
                            
                        else
                            state <= state_13;
                        end if;
                    
                    when state_14 => 
                        start_mul <= '0';
                        if ready_mul = '1' then
                            if out_mul(FP_WIDTH-1)='0' and (out_mul(FP_WIDTH-2 downto 0)> my_outMax(FP_WIDTH-2 downto 0)) then
                                output <= my_outMax;
                            elsif out_mul(FP_WIDTH-1) = '1' and (out_mul(FP_WIDTH-2 downto 0)  > my_outMin(FP_WIDTH-2 downto 0)) then
                                output <= my_outMin;
                            else
                                output <= out_mul;
                            end if;
                            
                            state <= state_15;
                        else
                            state <= state_14;
                        end if;
                        
                    when state_15 =>
                        busy <= '0';
                        output <= out_mul;
                        ready <= '1';
                        state <= Idle;
                        
                    when others => state <= Idle;
                end case;
                
            end if;

        end if; 
    end process;
    
end architecture;