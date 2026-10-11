library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity servo_controller is
    Generic (
        PERIOD_COUNT : integer := 1000000;  -- 20ms at 50MHz (default for synthesis)
        MIN_ANGLE    : integer := 27500;    -- 0.55ms for 45 degrees (default for synthesis)
        MAX_ANGLE    : integer := 122500;   -- 2.45ms for 135 degrees (default for synthesis)
        ANGLE_STEP   : integer := 500       -- Increment/decrement step
    );
    Port (
        clk       : in  STD_LOGIC;
        reset_n   : in  STD_LOGIC;
        write     : in  STD_LOGIC;
        address   : in  STD_LOGIC;
        writedata : in  STD_LOGIC_VECTOR(31 downto 0);
        irq       : out STD_LOGIC;
        out_wave       : out STD_LOGIC
    );
end servo_controller;

architecture Behavioral of servo_controller is
    -- State machine type
    type state_type is (SWEEP_RIGHT, INT_RIGHT, SWEEP_LEFT, INT_LEFT);
    signal current_state, next_state : state_type;
    
    -- Internal registers (32-bit)
    signal min_angle_count : unsigned(31 downto 0);
    signal max_angle_count : unsigned(31 downto 0);
    
    -- Counters
    signal period_counter : integer range 0 to PERIOD_COUNT-1;
    signal angle_counter  : unsigned(31 downto 0);
    
    -- Control signals
    signal irq_signal : STD_LOGIC;
    signal write_occurred : STD_LOGIC;
    
begin
    -- Register Write Logic
    process(clk, reset_n)
    begin
        if reset_n = '1' then
            min_angle_count <= to_unsigned(MIN_ANGLE, 32);
            max_angle_count <= to_unsigned(MAX_ANGLE, 32);
            write_occurred <= '0';
        elsif rising_edge(clk) then
            write_occurred <= '0';  -- Default
            if write = '1' then
                write_occurred <= '1';
                if address = '0' then
                    min_angle_count <= unsigned(writedata);
                else
                    max_angle_count <= unsigned(writedata);
                end if;
            end if;
        end if;
    end process;
    
    -- State Machine: State Register
    process(clk, reset_n)
    begin
        if reset_n = '1' then
            current_state <= SWEEP_RIGHT;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    -- State Machine: Next State Logic
    process(current_state, angle_counter, min_angle_count, max_angle_count, 
            period_counter, write_occurred)
    begin
        next_state <= current_state;  -- Default: stay in current state
        
        case current_state is
            when SWEEP_RIGHT =>
                if period_counter = PERIOD_COUNT-1 then
                    if angle_counter >= max_angle_count - ANGLE_STEP then
                        next_state <= INT_RIGHT;
                    end if;
                end if;
                
            when INT_RIGHT =>
                if write_occurred = '1' then
                    next_state <= SWEEP_LEFT;
                end if;
                
            when SWEEP_LEFT =>
                if period_counter = PERIOD_COUNT-1 then
                    if angle_counter <= min_angle_count + ANGLE_STEP then
                        next_state <= INT_LEFT;
                    end if;
                end if;
                
            when INT_LEFT =>
                if write_occurred = '1' then
                    next_state <= SWEEP_RIGHT;
                end if;
        end case;
    end process;
    
    -- State Machine: Output Logic (IRQ)
    process(current_state)
    begin
        case current_state is
            when INT_RIGHT | INT_LEFT =>
                irq_signal <= '1';
            when others =>
                irq_signal <= '0';
        end case;
    end process;
    
    -- Period Counter (20ms period)
    process(clk, reset_n)
    begin
        if reset_n = '1' then
            period_counter <= 0;
        elsif rising_edge(clk) then
            if period_counter = PERIOD_COUNT-1 then
                period_counter <= 0;
            else
                period_counter <= period_counter + 1;
            end if;
        end if;
    end process;
    
    -- Angle Counter (controls pulse width and sweeping)
    process(clk, reset_n)
    begin
        if reset_n = '1' then
            angle_counter <= to_unsigned(MIN_ANGLE, 32);
        elsif rising_edge(clk) then
            -- Update angle at the end of each period
            if current_state = INT_RIGHT and next_state = SWEEP_LEFT then
                angle_counter <= max_angle_count;
            elsif current_state = INT_LEFT and next_state = SWEEP_RIGHT then
                angle_counter <= min_angle_count; 
            elsif period_counter = PERIOD_COUNT-1 then 
                case current_state is
                    when SWEEP_RIGHT =>
                        if angle_counter + ANGLE_STEP <= max_angle_count then
                            angle_counter <= angle_counter + ANGLE_STEP;
                        else 
                          angle_counter <= max_angle_count; 
                        end if;
                        
                    when SWEEP_LEFT =>
                        if angle_counter > min_angle_count then
                            angle_counter <= angle_counter - ANGLE_STEP;
                        else 
                          angle_counter <= min_angle_count; 
                        end if;
                        
                    when INT_RIGHT =>
                        angle_counter <= max_angle_count;
                    when INT_LEFT =>
                        angle_counter <= min_angle_count;
                end case;
            end if;
        end if;
    end process;
    
    -- PWM Output Generation
    process(clk, reset_n)
    begin
        if reset_n = '1' then
            out_wave <= '0';
        elsif rising_edge(clk) then
            if period_counter < to_integer(angle_counter) then
                out_wave <= '1';
            else
                out_wave <= '0';
            end if;
        end if;
    end process;
    
    -- Output assignments
    irq <= irq_signal;
    
end Behavioral;