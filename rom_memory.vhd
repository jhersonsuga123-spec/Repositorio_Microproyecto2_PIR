library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Memoria ROM 
entity rom_memory is
    Port (
        clk      : in  std_logic;                    -- Reloj del sistema (50 MHz)
        enable   : in  std_logic;                    -- Señal rom_enable enviada por la FSM
        addr     : in  std_logic_vector(7 downto 0); -- Direccion de memoria (256 posiciones)
        data_out : out std_logic_vector(7 downto 0)  -- Bus de salida hacia la RAM
    );
end entity rom_memory;

architecture rtl of rom_memory is
    -- Arreglo de 256 palabras de 8 bits
    type rom_type is array (0 to 255) of std_logic_vector(7 downto 0);
    signal rom_block : rom_type;

    -- Atributo de síntesis para que Quartus asocie el archivo .mif
    attribute ram_init_file : string;
    attribute ram_init_file of rom_block : signal is "codigo_pir.mif";

begin

    -- Lectura síncrona requerida por los bloques M9K (latencia de 1 ciclo)
    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                data_out <= rom_block(to_integer(unsigned(addr)));
            end if;
        end if;
    end process;

end architecture rtl;