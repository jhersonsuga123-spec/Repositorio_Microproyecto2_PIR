library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ram_memory is
    Port (
        clk      : in  std_logic;
        we       : in  std_logic;
        addr     : in  std_logic_vector(7 downto 0);
        data_in  : in  std_logic_vector(15 downto 0);
        data_out : out std_logic_vector(15 downto 0)
    );
end entity ram_memory;

architecture syn of ram_memory is
    type ram_type is array (0 to 255) of std_logic_vector(15 downto 0);
    signal ram : ram_type := (others => (others => '0'));
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
end architecture syn;