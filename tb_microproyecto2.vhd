library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pkg_system.all;

entity tb_microproyecto2 is
-- Entidad vacía sin puertos externos para simulación
end entity tb_microproyecto2;

architecture sim of tb_microproyecto2 is

    -- 1. Declaración de la Unidad Bajo Prueba (UUT)
    component top_system is
        Port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            pir_sensor : in  std_logic;
            led_detect : out std_logic;
            hex0       : out std_logic_vector(6 downto 0);
            hex1       : out std_logic_vector(6 downto 0);
            hex2       : out std_logic_vector(6 downto 0);
            hex3       : out std_logic_vector(6 downto 0)
        );
    end component;

    -- 2. Señales de estímulo locales
    signal tb_clk        : std_logic := '0';
    signal tb_reset      : std_logic := '1'; -- Reposo en alto (lógica activa en bajo)
    signal tb_pir_sensor : std_logic := '0';

    -- Señales de monitoreo de salidas
    signal tb_led_detect : std_logic;
    signal tb_hex0       : std_logic_vector(6 downto 0);
    signal tb_hex1       : std_logic_vector(6 downto 0);
    signal tb_hex2       : std_logic_vector(6 downto 0);
    signal tb_hex3       : std_logic_vector(6 downto 0);

    -- Base de tiempo para reloj de 50 MHz (T = 20 ns)
    constant CLK_PERIOD : time := 20 ns;

    -- Bandera de parada del generador de reloj
    signal sim_finished : boolean := false;

begin

    -- 3. Instanciación estructural del módulo principal
    uut: top_system
        port map (
            clk        => tb_clk,
            reset      => tb_reset,
            pir_sensor => tb_pir_sensor,
            led_detect => tb_led_detect,
            hex0       => tb_hex0,
            hex1       => tb_hex1,
            hex2       => tb_hex2,
            hex3       => tb_hex3
        );

    -- 4. Generador de reloj continuo a 50 MHz
    clk_process : process
    begin
        while not sim_finished loop
            tb_clk <= '0';
            wait for CLK_PERIOD / 2; -- 10 ns
            tb_clk <= '1';
            wait for CLK_PERIOD / 2; -- 10 ns
        end loop;
        wait;
    end process;

    -- 5. Secuencia de estímulos temporales para simulación rápida
    stim_process : process
    begin
        -- Estado inicial
        tb_reset      <= '1';
        tb_pir_sensor <= '0';
        wait for 100 ns;

        -- Pulso de reset inicial (activo en bajo)
        tb_reset <= '0';
        wait for 100 ns;
        tb_reset <= '1';
        wait for 200 ns;

        -- Evento 1: Primera detección (400 ns supera el filtro de 10 ciclos = 200 ns)
        tb_pir_sensor <= '1';
        wait for 400 ns;
        
        -- Retiro del objetivo térmico (el sensor vuelve a 0)
        tb_pir_sensor <= '0';
        wait for 200 ns;

        -- Evento 2: Segunda detección (para verificar incremento de dirección en RAM)
        tb_pir_sensor <= '1';
        wait for 400 ns;
        
        -- Retiro del objetivo térmico
        tb_pir_sensor <= '0';
        wait for 200 ns;

        -- Detención controlada del reloj y fin de simulación
        sim_finished <= true;
        wait;
    end process;

end architecture sim;