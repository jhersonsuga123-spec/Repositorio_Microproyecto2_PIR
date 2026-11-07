library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Memoria RAM para guardar los eventos que llegan desde la ROM
entity ram_memory is
    Port (
        clk      : in  std_logic;                    -- Reloj del sistema (50 MHz)
        we       : in  std_logic;                    -- Habilitador de escritura (pulso de la FSM)
        addr     : in  std_logic_vector(7 downto 0); -- Puntero de direccion (hasta 256 posiciones)
        data_in  : in  std_logic_vector(7 downto 0); -- Dato que entra directo desde la ROM
        data_out : out std_logic_vector(7 downto 0)  -- Salida del dato almacenado
    );
end entity ram_memory;

architecture rtl of ram_memory is
    -- Bloque de memoria de 256 bytes inicializado en cero
    type ram_type is array (0 to 255) of std_logic_vector(7 downto 0);
    signal ram_block : ram_type := (others => (others => '0'));
begin

    -- Proceso sincrono para lectura y escritura
    process(clk)
    begin
        if rising_edge(clk) then
            -- Guardamos el dato solo cuando la FSM activa el pulso de escritura
            if we = '1' then
                ram_block(to_integer(unsigned(addr))) <= data_in;
            end if;

            -- Mantiene disponible a la salida el dato de la direccion apuntada
            data_out <= ram_block(to_integer(unsigned(addr)));
        end if;
    end process;

end architecture rtl;