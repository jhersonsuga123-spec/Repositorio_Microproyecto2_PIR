library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_system.all; 

-- Memoria am sincrona: Registro historico de los codigos asignados a cada evento de deteccion.
entity ram_memory is
    Port (
        clk      : in  std_logic;
        we       : in  std_logic; -- Habilitador de escritura
        addr     : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
        data_in  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity ram_memory;

architecture behavioral of ram_memory is

    -- Inicializacion de la memoria en estado logico bajo
    signal ram : mem_array_t := (others => (others => '0'));

begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- Escritura sincrona controlada por la unidad de control
            if we = '1' then
                ram(to_integer(unsigned(addr))) <= data_in;
            end if;
            -- Asignacion continua de lectura de la direccion apuntada
            data_out <= ram(to_integer(unsigned(addr)));
        end if;
    end process;

end architecture behavioral;