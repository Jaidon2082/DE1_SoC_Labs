library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Lab3 is
  port (
    CLOCK_50 : in  std_logic;
    KEY      : in  std_logic_vector(3 downto 0);
    SW       : in  std_logic_vector(7 downto 0);
    HEX0     : out std_logic_vector(6 downto 0)
  );
end entity Lab3;

architecture arch of Lab3 is

  -- nios_system component
  component nios_system is
    port (
      switches_export    : in  std_logic_vector(7 downto 0) := (others => 'X');
      pushbuttons_export : in  std_logic_vector(3 downto 0) := (others => 'X');
      hex0_export        : out std_logic_vector(6 downto 0);
      clk_clk            : in  std_logic                    := 'X';
      reset_reset_n      : in  std_logic                    := 'X'
    );
  end component;

  -- signal declarations
  signal reset_n : std_logic;
  signal key0_d1 : std_logic;
  signal key0_d2 : std_logic;
  signal key0_d3 : std_logic;

begin

  ----- Synchronize the PBs and create reset
  synchReset_proc : process (CLOCK_50) begin
    if (rising_edge(CLOCK_50)) then
      key0_d1 <= KEY(0);
      key0_d2 <= key0_d1;
      key0_d3 <= key0_d2;
    end if;
  end process synchReset_proc;
  reset_n <= key0_d3;

  -- Instantiate the Platform Designer system
  u0 : nios_system
    port map (
      switches_export    => SW(7 downto 0),  
      pushbuttons_export => KEY,             
      hex0_export        => HEX0,        
      clk_clk            => CLOCK_50,
      reset_reset_n      => reset_n
    );

end arch;