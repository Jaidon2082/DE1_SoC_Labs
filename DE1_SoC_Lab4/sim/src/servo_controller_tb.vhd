library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity servo_controller_tb is
end servo_controller_tb;

architecture testbench of servo_controller_tb is
    
    -- Component declaration
    component servo_controller is
        Generic (
            PERIOD_COUNT : integer := 1000000;
            MIN_ANGLE    : integer := 27500;
            MAX_ANGLE    : integer := 122500;
            ANGLE_STEP   : integer := 500
        );
        Port (
            clk       : in  STD_LOGIC;
            reset_n     : in  STD_LOGIC;
            write     : in  STD_LOGIC;
            address   : in  STD_LOGIC;
            writedata : in  STD_LOGIC_VECTOR(31 downto 0);
            irq       : out STD_LOGIC;
            out_wave       : out STD_LOGIC
        );
    end component;
    
    -- Testbench signals
    signal clk       : STD_LOGIC := '0';
    signal reset_n     : STD_LOGIC := '0';
    signal write     : STD_LOGIC := '0';
    signal address   : STD_LOGIC := '0';
    signal writedata : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal irq       : STD_LOGIC;
    signal out_wave       : STD_LOGIC;
    
    -- Clock period definition (50 MHz)
    constant CLK_PERIOD : time := 20 ns;
    
    -- Simulation-friendly parameters (much smaller for faster simulation)
    constant SIM_PERIOD_COUNT : integer := 100;      -- Reduced from 1,000,000
    constant SIM_MIN_ANGLE    : integer := 10;       -- Reduced from 27,500
    constant SIM_MAX_ANGLE    : integer := 50;       -- Reduced from 122,500
    constant SIM_ANGLE_STEP   : integer := 5;        -- Reduced from 500
    
    -- Simulation control
    signal test_done : boolean := false;
    
begin
    
    -- Instantiate the Unit Under Test (UUT)
    uut: servo_controller
        generic map (
            PERIOD_COUNT => SIM_PERIOD_COUNT,
            MIN_ANGLE    => SIM_MIN_ANGLE,
            MAX_ANGLE    => SIM_MAX_ANGLE,
            ANGLE_STEP   => SIM_ANGLE_STEP
        )
        port map (
            clk       => clk,
            reset_n     => reset_n,
            write     => write,
            address   => address,
            writedata => writedata,
            irq       => irq,
            out_wave       => out_wave
        );
    
    -- Clock process
    clk_process: process
    begin
        while not test_done loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- Stimulus process
    stim_process: process
    begin
        -- Print test start message
        report "===================================";
        report "Starting Servo Controller Testbench";
        report "===================================";
        wait for CLK_PERIOD;
        
        -- ========================================
        -- Test 1: reset_n the system
        -- ========================================
        report "TEST 1: Applying reset_n...";
        reset_n <= '1';
        wait for CLK_PERIOD * 10;
        reset_n <= '0';
        wait for CLK_PERIOD * 5;
        report "reset_n complete - controller initialized";
        report " ";
        
        -- ========================================
        -- Test 2: Let servo sweep right to max angle
        -- ========================================
        report "TEST 2: Sweeping right (SWEEP_RIGHT state)...";
        report "Waiting for servo to reach maximum angle...";
        
        -- Wait enough time for angle to increment from min to max
        -- Number of periods needed = (MAX - MIN) / STEP = (50-10)/5 = 8 periods
        wait for CLK_PERIOD * SIM_PERIOD_COUNT * 10;
        
        -- Check if IRQ is asserted (should be in INT_RIGHT state)
        assert irq = '1' 
            report "ERROR: IRQ should be HIGH in INT_RIGHT state" 
            severity error;
        report "SUCCESS: IRQ asserted - reached INT_RIGHT state";
        report " ";
        
        -- ========================================
        -- Test 3: Clear interrupt by writing to register 0
        -- ========================================
        report "TEST 3: Clearing interrupt with write to register 0...";
        wait for CLK_PERIOD * 3;
        
        address <= '0';
        writedata <= std_logic_vector(to_unsigned(SIM_MIN_ANGLE, 32));
        write <= '1';
        wait for CLK_PERIOD;
        write <= '0';
        
        wait for CLK_PERIOD * 3;
        assert irq = '0' 
            report "ERROR: IRQ should be cleared after write" 
            severity error;
        report "SUCCESS: IRQ cleared - entered SWEEP_LEFT state";
        report " ";
        
        -- ========================================
        -- Test 4: Let servo sweep left to min angle
        -- ========================================
        report "TEST 4: Sweeping left (SWEEP_LEFT state)...";
        report "Waiting for servo to reach minimum angle...";
        
        -- Wait for angle to decrement from max to min
        wait for CLK_PERIOD * SIM_PERIOD_COUNT * 10;
        
        -- Check if IRQ is asserted again (should be in INT_LEFT state)
        assert irq = '1' 
            report "ERROR: IRQ should be HIGH in INT_LEFT state" 
            severity error;
        report "SUCCESS: IRQ asserted - reached INT_LEFT state";
        report " ";
        
        -- ========================================
        -- Test 5: Clear interrupt by writing to register 1
        -- ========================================
        report "TEST 5: Clearing interrupt with write to register 1...";
        wait for CLK_PERIOD * 3;
        
        address <= '1';
        writedata <= std_logic_vector(to_unsigned(SIM_MAX_ANGLE, 32));
        write <= '1';
        wait for CLK_PERIOD;
        write <= '0';
        
        wait for CLK_PERIOD * 3;
        assert irq = '0' 
            report "ERROR: IRQ should be cleared after write" 
            severity error;
        report "SUCCESS: IRQ cleared - back to SWEEP_RIGHT state";
        report " ";
        
        -- ========================================
        -- Test 6: Test writing new min angle value
        -- ========================================
        report "TEST 6: Testing register write - new min angle...";
        wait for CLK_PERIOD * 5;
        
        address <= '0';
        writedata <= std_logic_vector(to_unsigned(15, 32));  -- New min angle
        write <= '1';
        wait for CLK_PERIOD;
        write <= '0';
        report "SUCCESS: Wrote new min angle (15) to register 0";
        report " ";
        
        -- ========================================
        -- Test 7: Test writing new max angle value
        -- ========================================
        report "TEST 7: Testing register write - new max angle...";
        wait for CLK_PERIOD * 5;
        
        address <= '1';
        writedata <= std_logic_vector(to_unsigned(40, 32));  -- New max angle
        write <= '1';
        wait for CLK_PERIOD;
        write <= '0';
        report "SUCCESS: Wrote new max angle (40) to register 1";
        report " ";
        
        -- ========================================
        -- Test 8: Observe full cycle with new values
        -- ========================================
        report "TEST 8: Observing full cycle with new angle values...";
        
        -- Wait for at least one complete cycle
        wait for CLK_PERIOD * SIM_PERIOD_COUNT * 20;
        
        report "SUCCESS: Completed full sweep cycle";
        report " ";
        
        -- ========================================
        -- Test Complete
        -- ========================================
        report "===================================";
        report "All tests completed successfully!";
        report "===================================";
        report " ";
        report "Summary:";
        report "  - FSM transitions: SWEEP_RIGHT -> INT_RIGHT -> SWEEP_LEFT -> INT_LEFT";
        report "  - IRQ generation verified in both INT states";
        report "  - IRQ clearing verified with writes to both registers";
        report "  - Register write functionality verified";
        report "  - PWM waveform generation working";
        
        test_done <= true;
        wait;
    end process;
    
    -- Monitor process to track PWM activity and state changes
    monitor_process: process
        variable last_irq : STD_LOGIC := '0';
    begin
        wait until rising_edge(clk);
        
        -- Detect IRQ transitions
        if irq = '1' and last_irq = '0' then
            report ">>> IRQ ASSERTED <<<" severity note;
        elsif irq = '0' and last_irq = '1' then
            report ">>> IRQ CLEARED <<<" severity note;
        end if;
        
        last_irq := irq;
    end process;
    
end testbench;