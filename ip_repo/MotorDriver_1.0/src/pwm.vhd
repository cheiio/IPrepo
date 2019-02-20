LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY pwm IS
  GENERIC(
      sys_clk         : INTEGER := 100_000_000; --system clock frequency in Hz
      pwm_freq        : INTEGER := 5_000;    --PWM switching frequency in Hz
      bits_resolution : INTEGER := 10;          --bits of resolution setting the duty cycle
      phases          : INTEGER := 7         --number of output pwms and phases
      );
  PORT(
      clk       : IN  STD_LOGIC;                                    --system clock
      reset_n   : IN  STD_LOGIC;                                    --asynchronous reset
      ena       : IN  STD_LOGIC;                                    --latches in new duty cycle
      duty      : IN  STD_LOGIC_VECTOR(bits_resolution-1 DOWNTO 0); --duty cycle
      phase     : IN  integer range 0 to phases-1;                       --pwm outputs
      pwm_out   : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0);          --pwm outputs
      pwm_n_out : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0));         --pwm inverse outputs
END pwm;

ARCHITECTURE logic OF pwm IS
--component clk_wiz_0 is
--    port(
--             resetn     : in std_logic;
--             clk_in1    : in std_logic;
--             clk_out1   : out std_logic;
----             clk_out2   : out std_logic;
--             locked     : out std_logic
--         );
--end component; 

--  CONSTANT  period     :  INTEGER := sys_clk/pwm_freq;                      --number of clocks in one pwm period
  CONSTANT  pwm_period     :  INTEGER := sys_clk/(pwm_freq*(2**bits_resolution));                      --number of clocks in one pwm period
  CONSTANT  pwm_half_period     :  INTEGER := sys_clk/(2*pwm_freq*(2**bits_resolution));                      --number of clocks in one pwm period
  CONSTANT  period          :  INTEGER := 2**bits_resolution;                      --number of clocks in one pwm period
  CONSTANT  half_period          :  INTEGER := 2**bits_resolution/2;                      --number of clocks in one pwm period
  --TYPE      counters IS ARRAY (0 TO phases-1) OF INTEGER RANGE 0 TO period - 1;  --data type for array of period counters
  TYPE      half_duties IS ARRAY (0 TO phases-1) OF INTEGER RANGE 0 TO period/2; --data type for array of half duty values

--  SIGNAL    count          :  counters := (OTHERS => 0);                        --array of period counters
  SIGNAL    pwm_count      :  integer range 0 to sys_clk/pwm_freq - 1;
  SIGNAL    count          :  integer range 0 to period-1;
  signal    half_duty_new  :  half_duties := (others => 0);                     --number of clocks in 1/2 duty cycle
  SIGNAL    half_duty      :  half_duties := (OTHERS => 0);                     --array of half duty values (for each phase)
  
  SIGNAL    pwm_clk  :  std_logic:='0' ;                     --array of half duty values (for each phase)
  SIGNAL    flag_end_of_period  :  std_logic:='0' ;                     --array of half duty values (for each phase)
  
  type t_state is (IDLE, work, pass);
  signal state: t_state := IDLE;
  
BEGIN

PROCESS(clk, reset_n)
    BEGIN
        IF(reset_n = '0') then              --asynchronous reset
            half_duty_new <= (others => 0);
            pwm_count <= 0;
            pwm_clk <= '0';
            flag_end_of_period <= '0';
          
        ELSIF rising_edge(clk) THEN --rising system clock edge
          
            if (ena = '1') then
                half_duty_new(phase) <= conv_integer(duty(bits_resolution-1 DOWNTO 1));   -- 1/2 duty cycle
            END IF;
          
            IF (pwm_count = pwm_period - 1) then    --end of period reached
                pwm_clk <= '1';
                pwm_count <= 0;                           --reset counter
            else    
                pwm_clk <= '0';
                pwm_count <= pwm_count + 1;                   --increment counter
            END IF;
            
            if (pwm_clk = '1') then
            
                IF(count = period - 1) then    --end of period reached
                    count <= 0;                           --reset counter
                    flag_end_of_period <= '1';
                else 
                    flag_end_of_period <= '0';
                    count <= count + 1;                   --increment counter            
                END IF;
                
                FOR i IN 0 to phases-1 LOOP                     --control outputs for each phase
                    IF(count = half_duty(i)) THEN               --phase's falling edge reached
                        pwm_out(i) <= '0';                        --deassert the pwm output
                        pwm_n_out(i) <= '1';                      --assert the pwm inverse output
                    ELSIF(count = period - half_duty(i)) THEN   --phase's rising edge reached
                        pwm_out(i) <= '1';                        --assert the pwm output
                        pwm_n_out(i) <= '0';                      --deassert the pwm inverse output
                    END IF;
                END LOOP;
                
            END IF;
            
            if (flag_end_of_period = '1' and ena = '0') then
                for ii in 0 to phases-1 loop
                    half_duty(ii) <= half_duty_new(ii);
                end loop;
            end if;
            
        END IF;
    END PROCESS;
--pwm_clk_gen: clk_wiz_0
--        port map(
--            resetn => reset_n,
--            clk_in1 => clk,
--            clk_out1 => pwm_clk,
----            clk_out2 => flag_end_of_period,
--            locked => open
--        );
        
--new_period:
--    process(flag_end_of_period, reset_n)
--    begin
--        if reset_n = '0' then
--            half_duty <= (others => 0); 
----        elsif (flag_end_of_period'event and flag_end_of_period = '1') then
--        elsif rising_edge(flag_end_of_period) then
--            for ii in 0 to phases-1 loop
--                half_duty(ii) <= half_duty_new(ii);
--            end loop;
--        end if;
--    end process new_period;

--pwm_counter_process:
--    PROCESS(pwm_clk, reset_n)
--    BEGIN
--        if reset_n = '0' then
--            count <= 0;                       --clear counter            
--            pwm_out <= (OTHERS => '0');       --clear pwm outputs
--            pwm_n_out <= (OTHERS => '1');     --clear pwm inverse outputs
--            --
            
----        elsif(pwm_clk'EVENT AND pwm_clk = '1') THEN --rising system clock edge
--        elsif rising_edge(pwm_clk) then
          
--            IF(count = period - 1) then    --end of period reached
--                count <= 0;                           --reset counter
--                flag_end_of_period <= '1';
----                flag_end_of_period <= '1';            --set most recent duty cycle value
----            elsif (count < half_period) then                 --half of period not reached
----                flag_end_of_period <= '1';
----                count <= count + 1;                   --increment counter

----            elsif (count > half_period-1) then                 --half of period 
--            else 
--                flag_end_of_period <= '0';
--                count <= count + 1;                   --increment counter            
--            END IF;
            
----            for ii in 0 to phases-1 loop
----                if (flag_end_of_period = '1' and ena = '0') then
----                    half_duty(ii) <= half_duty_new(ii);
----                end if;
----            end loop;
            
--            if (count < phases) and ena = '0' then
--                half_duty(count) <= half_duty_new(count);
--            end if;
            
--            FOR i IN 0 to phases-1 LOOP                     --control outputs for each phase
--                IF(count = half_duty(i)) THEN               --phase's falling edge reached
--                    pwm_out(i) <= '0';                        --deassert the pwm output
--                    pwm_n_out(i) <= '1';                      --assert the pwm inverse output
--                ELSIF(count = period - half_duty(i)) THEN   --phase's rising edge reached
--                    pwm_out(i) <= '1';                        --assert the pwm output
--                    pwm_n_out(i) <= '0';                      --deassert the pwm inverse output
--                END IF;
--            END LOOP;
            
--        end if;
--    END PROCESS pwm_counter_process;

--clk_pwm_counter_process:
--    PROCESS(clk, reset_n)
--    BEGIN
--        IF(reset_n = '0') then              --asynchronous reset
--            half_duty_new <= (others => 0);
----            pwm_count <= 0;
----            pwm_clk <= '0';
--            --flag_end_of_period <= '0';
          
--        ELSIF rising_edge(clk) THEN --rising system clock edge
          
--            IF(ena = '1') THEN 
----                half_duty_new(phase) <= conv_integer(duty)*period/(2**bits_resolution)/2;   --determine clocks in 1/2 duty cycle
--                half_duty_new(phase) <= conv_integer(duty(bits_resolution-1 DOWNTO 1));   -- 1/2 duty cycle
--            END IF;
          
----            IF (pwm_count = pwm_period - 1) then    --end of period reached
----                pwm_clk <= '1';
----                pwm_count <= 0;                           --reset counter
----                --pwm_clk <= '1';            --set most recent duty cycle value
----            elsif (pwm_count < pwm_half_period) then   
----            --counter less than half
----                pwm_clk <= '1';
----                pwm_count <= pwm_count + 1;                   --increment counter
------            elsif (pwm_count > pwm_half_period-1) then
----            else    
----            --counter more than half
----                pwm_clk <= '0';
----                pwm_count <= pwm_count + 1;                   --increment counter
----            END IF;
            
--        END IF;
--    END PROCESS clk_pwm_counter_process;

END logic;