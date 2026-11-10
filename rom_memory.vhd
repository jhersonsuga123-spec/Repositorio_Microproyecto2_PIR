library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_system.all; 

entity rom_memory is
    Port (
        clk      : in  std_logic;
        enable   : in  std_logic;
        addr     : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
        data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity rom_memory;

architecture behavioral of rom_memory is
    signal rom : mem_array_t;

    attribute ram_init_file : string;
    attribute ram_init_file of rom : signal is "codigo_pir.mif";

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                data_out <= rom(to_integer(unsigned(addr)));
            end if;
        end if;
    end process;

end architecture behavioral;