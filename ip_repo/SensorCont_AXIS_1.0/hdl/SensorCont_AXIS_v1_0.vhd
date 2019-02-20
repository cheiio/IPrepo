library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fpupack.all;

entity SensorCont_AXIS_v1_0 is
	generic (
		-- Users to add parameters here
        C_AXIS_TDATA_WIDTH	: integer	:= 32;
        NUMBER_OF_DOF : integer := 3;
        FULL_CONTROL : boolean := true;
        -- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXIS
		C_S00_AXIS_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Master Bus Interface M00_AXIS
		C_M00_AXIS_TDATA_WIDTH	: integer	:= 32;
		C_M00_AXIS_START_COUNT	: integer	:= 32
	);
	port (
		-- Users to add ports here
        modMaster_aclk :in std_logic;
        modMaster_aresetn :in std_logic;
        
        modMaster_ready : out std_logic;
        modMaster_busy : out std_logic;
        modMaster_busy_vector : out std_logic_vector(NUMBER_OF_DOF-1 downto 0);
        
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_aclk	: in std_logic;
		s00_axis_aresetn	: in std_logic;
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast	: in std_logic;
		s00_axis_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_aclk	: in std_logic;
		m00_axis_aresetn	: in std_logic;
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast	: out std_logic;
		m00_axis_tready	: in std_logic
	);
end SensorCont_AXIS_v1_0;

architecture arch_imp of SensorCont_AXIS_v1_0 is


-- function called clogb2 that returns an integer which has the 
-- value of the ceiling of the log base 2.
function clogb2 (bit_depth : integer) return integer is 
variable depth  : integer := bit_depth;
  begin
    if (depth = 0) then
      return(0);
    else
      for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
        if(depth <= 1) then 
          return(clogb2);      
        else
          depth := depth / 2;
        end if;
      end loop;
    end if;
end;    

-- function calculates number of inputs and outputs deppending on the used modules
function n_words (NDOF: integer ; FCONT: boolean) return integer is
    begin
        if FCONT = true then    
            return(NDOF*4);  
        else  
            return(NDOF*3);  
        end if;
end;

-- function calculates or logic to a bit array
function or_gate (word: std_logic_vector) return std_logic is
    variable res : std_logic := '0';
    begin 
    for I in word'length-1 downto 0 loop
        res := res or word(I);
    end loop;
    return(res);        
end;

    -- Total number of input/output data.
    constant NUMBER_OF_INPUT_WORDS  : integer := n_words(NUMBER_OF_DOF, FULL_CONTROL); -- Every DoF receives 4 data (pos, curr, volt, | setpoint)
    constant NUMBER_OF_OUTPUT_WORDS : integer := n_words(NUMBER_OF_DOF, FULL_CONTROL); -- Every DoF returns 4 data (pos, vel, curr,   | impOut)
    constant N_DATA_MOD : integer := NUMBER_OF_INPUT_WORDS/NUMBER_OF_DOF; -- Every DoF returns 4 data (pos, vel, curr,   | impOut)
    
    -- bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
    constant bit_num  : integer := clogb2(NUMBER_OF_INPUT_WORDS-1);
    -- Define the states of state machine
    -- The control state machine oversees the writing of input streaming data to the FIFO,
    -- and outputs the streaming data from the FIFO
    type state_s is ( IDLE,        -- This is the initial/idle state 
                    WRITE_FIFO); -- In this state FIFO is written with the
                                 -- input stream data S00_AXIS_TDATA 
    type state_m is ( IDLE,        -- This is the initial/idle state                    
                    INIT_COUNTER,  -- This state initializes the counter, once        
                                 -- the counter reaches C_M_START_COUNT count,     
                                 -- the state machine changes state to SEND_STREAM  
                    SEND_STREAM);  -- In this state the                               
                                  -- stream data is output through M00_AXIS_TDATA       
    signal axis_tready	: std_logic;
    -- State variable
    signal  msts_exec_state : state_s;                                                  
    signal  mstm_exec_state : state_m;    
    -- FIFO implementation signals
    signal  byte_index : integer;    
    -- FIFO write enable
    signal fifo_wren : std_logic;
    -- FIFO full flag
    signal fifo_full_flag : std_logic;
    -- FIFO write pointer
    signal write_pointer : integer range 0 to bit_num-1 ;
    -- sink has accepted all the streaming data and stored in FIFO
    signal writes_done : std_logic;
    
    -- WAIT_COUNT_BITS is the width of the wait counter.                       
	constant  WAIT_COUNT_BITS  : integer := clogb2(C_M00_AXIS_START_COUNT-1);               
	                                                                                  
	-- In this example, Depth of FIFO is determined by the greater of                 
	-- the number of input words and output words.                                    
	constant depth : integer := NUMBER_OF_OUTPUT_WORDS;                               
	                                                                                  
	-- Example design FIFO read pointer                                               
	signal read_pointer : integer range 0 to bit_num-1;                               

	-- AXI Stream internal signals
	--wait counter. The master waits for the user defined number of clock cycles before initiating a transfer.
	signal count	: std_logic_vector(WAIT_COUNT_BITS-1 downto 0);
	--streaming data valid
	signal axis_tvalid	: std_logic;
	--streaming data valid delayed by one clock cycle
	signal axis_tvalid_delay	: std_logic;
	--Last of the streaming data 
	signal axis_tlast	: std_logic;
	--Last of the streaming data delayed by one clock cycle
	signal axis_tlast_delay	: std_logic;
	--FIFO implementation signals
	signal stream_data_out	: std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
	signal tx_en	: std_logic;
	--The master has issued all the streaming data stored in FIFO
	signal tx_done	: std_logic;
	
	signal my_modMaster_ready : std_logic;
	signal my_modMaster_busy : std_logic;

    type BYTE_FIFO_TYPE_IN is array (0 to NUMBER_OF_INPUT_WORDS-1) of std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
    type BYTE_FIFO_TYPE_OUT is array (0 to NUMBER_OF_OUTPUT_WORDS-1) of std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
    signal stream_data_fifo_in : BYTE_FIFO_TYPE_IN := (others => "00000000000000000000000000000000");
    signal stream_data_fifo_out : BYTE_FIFO_TYPE_OUT := (others => "00000000000000000000000000000000");
    
    -- User Signals
    signal countStart : integer range 0 to N_DATA_MOD-1;
    signal countMod : integer range 0 to NUMBER_OF_DOF-1;
    
    signal modMaster_areset : std_logic ;
    signal SensorMod_start : std_logic_vector(NUMBER_OF_DOF-1 downto 0) ;
    signal impCont_start : std_logic_vector(NUMBER_OF_DOF-1 downto 0) ;
    signal SensorMod_ready : std_logic_vector(NUMBER_OF_DOF-1 downto 0) ;
    signal impCont_ready : std_logic_vector(NUMBER_OF_DOF-1 downto 0) ;
    signal SensorMod_busy : std_logic_vector(NUMBER_OF_DOF-1 downto 0) := (others => '0');
    signal impCont_busy : std_logic_vector(NUMBER_OF_DOF-1 downto 0) := (others => '0');
    
    signal my_outMax   :  std_logic_vector(FP_WIDTH-1 downto 0) := "010000010000000000000000000"; --
    signal my_outMin   :  std_logic_vector(FP_WIDTH-1 downto 0) := "110000010000000000000000000"; --
    signal my_M        :  std_logic_vector(FP_WIDTH-1 downto 0) := "001111111111001000111101000"; -- 1/0.5284
    signal my_K        :  std_logic_vector(FP_WIDTH-1 downto 0) := "010000101011000100111100000"; -- 88.6173
    signal my_B        :  std_logic_vector(FP_WIDTH-1 downto 0) := "010000010001100101001000001"; -- 9.5801
    signal my_P        :  std_logic_vector(FP_WIDTH-1 downto 0) := "001111110000000100100000010"; -- 0.504
    signal my_dt       :  std_logic_vector(FP_WIDTH-1 downto 0) := "001110111010001111010111000";   -- dt = 0.005 
    signal my_dt_half  :  std_logic_vector(FP_WIDTH-1 downto 0) := "001110110010001111010111000";   -- dt/2
        
    
begin
    
-- I/O Connections assignments

S00_AXIS_TREADY	<= axis_tready;

M00_AXIS_TVALID	<= axis_tvalid_delay;
M00_AXIS_TDATA    <= stream_data_out;
M00_AXIS_TLAST    <= axis_tlast_delay;
M00_AXIS_TSTRB    <= (others => '1');

-- I/O Assignements for modules
    
busy_ready_full: if FULL_CONTROL = true generate
    modMaster_busy <= or_gate(SensorMod_busy & impCont_busy) ;
    my_modMaster_ready <= impCont_ready(NUMBER_OF_DOF-1);
end generate busy_ready_full;
busy_ready_single: if FULL_CONTROL = false generate
    modMaster_busy <= or_gate(SensorMod_busy) ;
    my_modMaster_ready <= SensorMod_ready(NUMBER_OF_DOF-1);
end generate busy_ready_single;
    
impCont_start <= SensorMod_ready;
modMaster_areset <= not modMaster_aresetn;
modMaster_ready <= my_modMaster_ready ;

GEN_MOD: 
for I in 0 to NUMBER_OF_DOF-1 generate

    SensorMod: entity work.SensorMod port map(
        clk =>          modMaster_aclk,
        rst =>          modMaster_areset,
        start =>        SensorMod_start( I ),
        positionSen =>  stream_data_fifo_in( I*N_DATA_MOD ),
        currentSen =>   stream_data_fifo_in( I*N_DATA_MOD+1 ),
        volts =>        stream_data_fifo_in( I*N_DATA_MOD+2 ),
        
        busy =>         SensorMod_busy( I ),
        ready =>        SensorMod_ready( I ),
        
        position =>     stream_data_fifo_out( I*N_DATA_MOD ),  
        velocity  =>    stream_data_fifo_out( I*N_DATA_MOD+1 ),
        current  =>     stream_data_fifo_out( I*N_DATA_MOD+2 )
    );
    
    imp : if  FULL_CONTROL = true generate
        Cont : entity work.ImpedanceCont
          port map(
              clk         =>  modMaster_aclk,
              rst         =>  modMaster_areset,
              start       =>  impCont_start( I ),
              
              outMax      => my_outMax  ,   
              outMin      => my_outMin  ,   
              M           => my_M       ,
              K           => my_K       ,
              B           => my_B       ,
              P           => my_P       ,
              dt          => my_dt      ,
              dt_half     => my_dt_half ,
              
              input       => stream_data_fifo_out( I*N_DATA_MOD+2 ),
              setpoint    => stream_data_fifo_in ( I*N_DATA_MOD+3 ),
              
              x           => stream_data_fifo_out( I*N_DATA_MOD ),
              xp          => stream_data_fifo_out( I*N_DATA_MOD+1 ),
              
              ready       => impCont_ready( I ),
              busy        => impCont_busy( I ),
              output      => stream_data_fifo_out( I*N_DATA_MOD+3 )
          );
          
          modMaster_busy_vector(I) <= impCont_busy( I ) or SensorMod_busy( I );
    end generate imp;
    
    imp_not: if FULL_CONTROL = false generate
        modMaster_busy_vector(I) <= SensorMod_busy( I );
    end generate imp_not; 
    
end generate GEN_MOD;
----------------------------AXI Slave--------------------------------

-- Control state machine implementation for slave AXI stream
process(S00_AXIS_ACLK)
begin
  if (rising_edge (S00_AXIS_ACLK)) then
    if(S00_AXIS_ARESETN = '0') then
      -- Synchronous reset (active low)
      msts_exec_state      <= IDLE;
      
    else
      case (msts_exec_state) is
        when IDLE     => 
          -- The sink starts accepting tdata when 
          -- there tvalid is asserted to mark the
          -- presence of valid streaming data 
          if (S00_AXIS_TVALID = '1')then
            msts_exec_state <= WRITE_FIFO;
          else
            msts_exec_state <= IDLE;
          end if;
      
        when WRITE_FIFO => 
          -- When the sink has accepted all the streaming input data,
          -- the interface swiches functionality to a streaming master
          if (writes_done = '1') then
            msts_exec_state <= IDLE;
          else
            -- The sink accepts and stores tdata 
            -- into FIFO
            msts_exec_state <= WRITE_FIFO;
          end if;
        
        when others    => 
          msts_exec_state <= IDLE;
        
      end case;
    end if;  
  end if;
end process;
-- AXI Streaming Sink 
-- 
-- The example design sink is always ready to accept the S00_AXIS_TDATA  until
-- the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
axis_tready <= '1' when ((msts_exec_state = WRITE_FIFO) and (write_pointer <= NUMBER_OF_INPUT_WORDS-1)) else '0';

process(S00_AXIS_ACLK)
begin
  if (rising_edge (S00_AXIS_ACLK)) then
    if(S00_AXIS_ARESETN = '0') then
      write_pointer <= 0;
      writes_done <= '0';
    else
      if (write_pointer <= NUMBER_OF_INPUT_WORDS-1) then
        if (fifo_wren = '1') then
          -- write pointer is incremented after every write to the FIFO
          -- when FIFO write signal is enabled.
          write_pointer <= write_pointer + 1;
          writes_done <= '0';
          
          -- start computing SensorMods
          if (countStart <= N_DATA_MOD-2) then 
            countStart <= countStart+1;
            SensorMod_start <= (others => '0');
          else
            SensorMod_start(countMod) <= '1';
            countMod <= countMod+1; 
            countStart <= 0;
          end if;
        
        elsif (write_pointer = 0) then
          SensorMod_start <= (others => '0');
      
        end if;
        if ((write_pointer = NUMBER_OF_INPUT_WORDS-1) or S00_AXIS_TLAST = '1') then
          -- reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
          -- has been written to the FIFO which is also marked by S00_AXIS_TLAST(kept for optional usage).
          writes_done <= '1';
          countStart <= 0;
          countMod <= 0;
          SensorMod_start(NUMBER_OF_DOF-1) <= '1';
          write_pointer <= 0;
        end if;
      end  if;
    end if;
  end if;
end process;

-- FIFO write enable generation
fifo_wren <= S00_AXIS_TVALID and axis_tready;
--fifo_wren <= S00_AXIS_TVALID;

-- FIFO Implementation
-- Streaming input data is stored in FIFO
process(S00_AXIS_ACLK)
begin
    if (rising_edge (S00_AXIS_ACLK)) then
      if (fifo_wren = '1') then
        stream_data_fifo_in(write_pointer) <= S00_AXIS_TDATA;
      end if;  
    end  if;
end process;

----------------------------AXI Master--------------------------------

-- Control state machine implementation for master AXI stream 
process(M00_AXIS_ACLK)                                                                        
begin                                                                                       
  if (rising_edge (M00_AXIS_ACLK)) then                                                       
    if(M00_AXIS_ARESETN = '0') then
      -- Synchronous reset (active low)
      mstm_exec_state      <= IDLE;
      count <= (others => '0');
    else                                                                                    
      case (mstm_exec_state) is                                                              
        when IDLE     =>                                                                    
          -- The slave starts accepting tdata when                                          
          -- there tvalid is asserted to mark the                                           
          -- presence of valid streaming data                                               
          if (my_modMaster_ready = '1')then                                                            
            mstm_exec_state <= SEND_STREAM;                                                 
          else                                                                              
            mstm_exec_state <= IDLE;                                                         
          end if;                                                                           
                                                                                            
--              when INIT_COUNTER =>                                                              
--                -- This state is responsible to wait for user defined C_M_START_COUNT           
--                -- number of clock cycles.                                                      
--                if ( count = std_logic_vector(to_unsigned((C_M_START_COUNT - 1), WAIT_COUNT_BITS))) then
--                  mstm_exec_state  <= SEND_STREAM;                                               
--                else                                                                            
--                  count <= std_logic_vector (unsigned(count) + 1);                              
--                  mstm_exec_state  <= INIT_COUNTER;                                              
--                end if;                                                                         
                                                                                            
        when SEND_STREAM  =>                                                                
          -- The example design streaming master functionality starts                       
          -- when the master drives output tdata from the FIFO and the slave                
          -- has finished storing the S00_AXIS_TDATA                                          
          if (tx_done = '1') then                                                           
            mstm_exec_state <= IDLE;                                                         
          else                                                                              
            mstm_exec_state <= SEND_STREAM;                                                  
          end if;                                                                           
                                                                                            
        when others    =>                                                                   
          mstm_exec_state <= IDLE;                                                           
                                                                                            
      end case;                                                                             
    end if;                                                                                 
  end if;                                                                                   
end process;

--tvalid generation
--axis_tvalid is asserted when the control state machine's state is SEND_STREAM and
--number of output streaming data is less than the NUMBER_OF_OUTPUT_WORDS.
axis_tvalid <= '1' when ((mstm_exec_state = SEND_STREAM) and (read_pointer < NUMBER_OF_OUTPUT_WORDS)) else '0';
                                                                                               
-- AXI tlast generation                                                                        
-- axis_tlast is asserted number of output streaming data is NUMBER_OF_OUTPUT_WORDS-1          
-- (0 to NUMBER_OF_OUTPUT_WORDS-1)                                                             
axis_tlast <= '1' when (read_pointer = NUMBER_OF_OUTPUT_WORDS-1) else '0';                     
                                                                                               
-- Delay the axis_tvalid and axis_tlast signal by one clock cycle                              
-- to match the latency of M00_AXIS_TDATA                                                        
process(M00_AXIS_ACLK)                                                                           
begin                                                                                          
  if (rising_edge (M00_AXIS_ACLK)) then                                                          
    if(M00_AXIS_ARESETN = '0') then                                                              
      axis_tvalid_delay <= '0';                                                                
      axis_tlast_delay <= '0';                                                                 
    else                                                                                       
      axis_tvalid_delay <= axis_tvalid;                                                        
      axis_tlast_delay <= axis_tlast;                                                          
    end if;                                                                                    
  end if;                                                                                      
end process;                                                                                   

--read_pointer pointer

process(M00_AXIS_ACLK)                                                       
begin                                                                            
  if (rising_edge (M00_AXIS_ACLK)) then                                            
    if(M00_AXIS_ARESETN = '0') then                                                
      read_pointer <= 0;                                                         
      tx_done  <= '0';                                                           
    else                                                                         
      if (read_pointer <= NUMBER_OF_OUTPUT_WORDS-1) then                         
        if (tx_en = '1') then                                                    
          -- read pointer is incremented after every read from the FIFO          
          -- when FIFO read signal is enabled.                                   
          read_pointer <= read_pointer + 1;                                      
          tx_done <= '0';                                                        
        end if;                                                                  
      elsif (read_pointer = NUMBER_OF_OUTPUT_WORDS) then                         
        -- tx_done is asserted when NUMBER_OF_OUTPUT_WORDS numbers of streaming data
        -- has been out.                                                         
        tx_done <= '1';                                                          
      end  if;                                                                   
    end  if;                                                                     
  end  if;                                                                       
end process;                         

--FIFO read enable generation 

tx_en <= M00_AXIS_TREADY and axis_tvalid;                                   
                                                                                
-- FIFO Implementation                                                          
                                                                                
-- Streaming output data is read from FIFO                                      
  process(M00_AXIS_ACLK)                                             
  begin                                                                         
    if (rising_edge (M00_AXIS_ACLK)) then                                         
      if(M00_AXIS_ARESETN = '0') then                                             
        stream_data_out <= (others => '0');  
      elsif (tx_en = '1') then -- && M00_AXIS_TSTRB(byte_index)                   
        stream_data_out <= stream_data_fifo_out(read_pointer);
      end if;                                                                   
     end if;                                                                    
   end process;
       

end arch_imp;
