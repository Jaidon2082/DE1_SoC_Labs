-------------------------------------------------------------------------
-- Jaidon Rodriguez
-- Embedded System Design 1
-- Lab5 Top Level
-- October 15th 2025
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab5_top_level is
    port (
      CLOCK_50       : in  std_logic;
      KEY       	   : in std_logic_vector(3 downto 0);
		SW			      : in std_logic_vector(7 downto 0);
      GPIO_0         : out std_logic_vector(6 downto 0);
		HEX0		       : out std_logic_vector(6 downto 0);
		HEX1		       : out std_logic_vector(6 downto 0);
		HEX2		       : out std_logic_vector(6 downto 0);
		HEX4		       : out std_logic_vector(6 downto 0);
		HEX5		       : out std_logic_vector(6 downto 0)
    );
end entity Lab5_top_level;

architecture Behavioral of Lab5_top_level is

signal reset_n		  :  std_logic;

	component nios_system is
		port (
			clk_clk          : in  std_logic                    := 'X';             -- clk
			reset_reset_n    : in  std_logic                    := 'X';             -- reset_n
			switches_export  : in  std_logic_vector(7 downto 0) := (others => 'X'); -- export
			keys_export      : in  std_logic_vector(3 downto 0) := (others => 'X'); -- export
			hex5_export      : out std_logic_vector(6 downto 0);                    -- export
			hex4_export      : out std_logic_vector(6 downto 0);                    -- export
			hex2_export      : out std_logic_vector(6 downto 0);                    -- export
			hex1_export      : out std_logic_vector(6 downto 0);                    -- export
			hex0_export      : out std_logic_vector(6 downto 0);                    -- export
			conduit_out_wave : out std_logic                                        -- out_wave
		);
	end component nios_system;

begin

	reset_n <= KEY(0);
		
	u0 : component nios_system
		port map (
			clk_clk          => CLOCK_50,  --      clk.clk
			conduit_out_wave => GPIO_0(0), --  conduit.out_wave
			hex0_export      => HEX0,    	 --     hex0.export
			hex1_export      => HEX1,    	 --     hex1.export
			hex2_export      => HEX2,      --     hex2.export
			hex4_export      => HEX4,      --     hex4.export
			hex5_export      => HEX5,      --     hex5.export
			keys_export      => KEY,       --      key.export
			reset_reset_n    => reset_n,   --  reset_n.reset_n
			switches_export  => SW   		   -- switches.export
		);
		
end Behavioral;