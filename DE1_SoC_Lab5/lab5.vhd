-------------------------------------------------------------------------
-- Jaidon Rodriguez
-- Embedded System Design 1
-- Lab 5
-- October 15th 2025
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab5 is
    port (
        clk       : in  std_logic;
        reset_n        : in  std_logic;
        write_enable   : in  std_logic;
        write_address  : in  std_logic;
        write_data     : in  std_logic_vector(31 downto 0);
        pwm_out        : out std_logic;
        irq_signal     : out std_logic
    );
end entity Lab5;

architecture Behavioral of Lab5 is
    -- State machine
    constant SWEEP_LEFT   : std_logic_vector(1 downto 0) := "00";
    constant SWEEP_RIGHT  : std_logic_vector(1 downto 0) := "01";
    constant INT_LEFT     : std_logic_vector(1 downto 0) := "10";
    constant INT_RIGHT    : std_logic_vector(1 downto 0) := "11";

    -- Internal signals
    signal state_reg      : std_logic_vector(1 downto 0);
    signal state_next     : std_logic_vector(1 downto 0);
    signal period_counter : unsigned(19 downto 0) := b"00000000000000000000";
    signal angle_count    : unsigned(31 downto 0) := x"0000C350"; -- 50 000
    signal min_angle_reg  : unsigned(31 downto 0) := x"0000C350"; -- 50 000
    signal max_angle_reg  : unsigned(31 downto 0) := x"000186A0"; -- 100 000
    
    constant ANGLE_STEP   : unsigned(31 downto 0) := x"000001F4";  -- 500
    
begin
    -- State Register
    state_reg_proc: process(clk, reset_n)
    begin
        if reset_n = '0' then
            state_reg <= SWEEP_RIGHT;
        elsif rising_edge(clk) then
            state_reg <= state_next;
        end if;
    end process;

    -- Next State Logic
    next_state_proc: process(state_reg, angle_count, min_angle_reg, max_angle_reg, write_enable)
    begin
        state_next <= state_reg; -- Default
        
        case state_reg is
            when SWEEP_RIGHT =>
                if angle_count >= max_angle_reg then
                    state_next <= INT_RIGHT;
                end if;
                
            when INT_RIGHT =>
                if write_enable = '1' then
                    state_next <= SWEEP_LEFT;
                end if;
                
            when SWEEP_LEFT =>
                if angle_count <= min_angle_reg then
                    state_next <= INT_LEFT;
                end if;
                
            when INT_LEFT =>
                if write_enable = '1' then
                    state_next <= SWEEP_RIGHT;
                end if;
                
            when others =>
                state_next <= SWEEP_RIGHT;
        end case;
    end process;

    -- Register Logic
    register_proc: process(clk, reset_n)
    begin
        if reset_n = '0' then
            min_angle_reg <= x"0000C350"; -- 50 000
            max_angle_reg <= x"000186A0"; -- 100 000
        elsif rising_edge(clk) then
            if write_enable = '1' then
                if write_address = '0' then
                    min_angle_reg <= unsigned(write_data);
                else
                    max_angle_reg <= unsigned(write_data);
                end if;
            end if;
        end if;
    end process;

    -- Period Counter (20ms)
    period_counter_proc: process(clk, reset_n)
    begin
        if reset_n = '0' then
            period_counter <= (others => '0');
        elsif rising_edge(clk) then
            if period_counter >= x"000F4240" then -- 1 000 000
                period_counter <= (others => '0');
            else
                period_counter <= period_counter + 1;
            end if;
        end if;
    end process;

    -- Angle Counter
    angle_counter_proc: process(clk, reset_n)
    begin
        if reset_n = '0' then
            angle_count <= min_angle_reg;
        elsif rising_edge(clk) then
            case state_reg is
                when SWEEP_RIGHT =>
                    if period_counter = 0 then
                        angle_count <= angle_count + ANGLE_STEP;
                    end if;
                when SWEEP_LEFT =>
                    if period_counter = 0 then
                        angle_count <= angle_count - ANGLE_STEP;
                    end if;
                when others =>
                    angle_count <= angle_count;
            end case;
        end if;
    end process;

    -- IRQ
    irq_proc: process(clk, reset_n, state_reg)
    begin
		if reset_n = '0' then
			irq_signal <= '0';
		elsif rising_edge(clk) then
			if state_reg = INT_LEFT or state_reg = INT_RIGHT then
				irq_signal <= '1';
			else
				irq_signal <= '0';
			end if;
		end if;
    end process;

    -- PWM Output
    pwm_proc: process(clk, reset_n, period_counter, angle_count)
    begin
		if reset_n = '0' then
			pwm_out <= '0';
		elsif rising_edge(clk) then
			if period_counter < angle_count then
				pwm_out <= '1';
			else
				pwm_out <= '0';
			end if;
		end if;
    end process;

end Behavioral;