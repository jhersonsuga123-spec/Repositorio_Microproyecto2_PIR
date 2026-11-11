library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Paquete de configuracion global: Define constantes y tipos de datos para parametrizar el sistema.
package pkg_system is

    constant DATA_WIDTH : integer := 16; -- Ancho de palabra de los datos (16 bits)
    constant ADDR_WIDTH : integer := 8;  -- Ancho del bus de direcciones
    constant MEM_DEPTH  : integer := 2**ADDR_WIDTH; -- Profundidad de memoria (256 posiciones)
    
    -- Definicion del tipo de dato matricial para la instanciacion de memorias RAM y ROM
    type mem_array_t is array (0 to MEM_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);

end package pkg_system;