library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package pkg_system is
    constant DATA_WIDTH : integer := 4;
    constant ADDR_WIDTH : integer := 4; 
    constant MEM_DEPTH  : integer := 2**ADDR_WIDTH;

    type mem_array_t is array (0 to MEM_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
end package pkg_system;