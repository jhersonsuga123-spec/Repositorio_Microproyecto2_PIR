library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_system.all; 

entity ram_memory is
    Port (
        clk      : in  std_logic;
        we       : in  std_logic;
        addr     : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
        data_in  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity ram_memory;

architecture behavioral of ram_memory is

    signal ram : mem_array_t := (others => (others => '0'));

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(to_integer(unsigned(addr))) <= data_in;
            end if;
            data_out <= ram(to_integer(unsigned(addr)));
        end if;
    end process;

end architecture behavioral;