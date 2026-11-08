library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Testbench para probar el sistema completo de deteccion PIR
entity tb_top_system is
    -- El testbench no tiene puertos de entrada ni salida
end entity tb_top_system;

architecture sim of tb_top_system is

    -- Componente principal a probar (UUT)
    component top_system is
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            pir_sensor   : in  std_logic;
            leds_ram_out : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Senales de estimulo y monitoreo
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal pir_sensor   : std_logic := '0';
    signal leds_ram_out : std_logic_vector(7 downto 0);

    -- Periodo de reloj de 20 ns (equivalente a los 50 MHz de la Cyclone III)
    constant CLK_PERIOD : time := 20 ns;
    
    -- Bandera para detener el reloj al terminar la simulacion
    signal fin_sim      : boolean := false;

begin

    -- Conexion del modulo principal
    uut : top_system
        port map (
            clk          => clk,
            reset        => reset,
            pir_sensor   => pir_sensor,
            leds_ram_out => leds_ram_out
        );

    -- Generador de reloj continuo a 50 MHz
    reloj_proc : process
    begin
        while not fin_sim loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Proceso de pruebas (simulacion de persona pasando frente al PIR)
    estimulos_proc : process
    begin
        -- 1. Reinicio inicial del sistema
        reset <= '1';
        pir_sensor <= '0';
        wait for 60 ns;
        reset <= '0';
        wait for 60 ns;

        -- 2. Primera deteccion: debe leer direccion 00 de la ROM y mostrar A1
        pir_sensor <= '1';
        wait for 200 ns; -- La FSM lee ROM, escribe RAM y espera a que baje el sensor
        pir_sensor <= '0';
        wait for 100 ns;

        -- 3. Segunda deteccion (mas larga para verificar que no guarde doble): debe mostrar B2
        pir_sensor <= '1';
        wait for 400 ns; -- Aunque el sensor dure mucho en '1', solo registra un evento
        pir_sensor <= '0';
        wait for 100 ns;

        -- 4. Tercera deteccion: debe mostrar C3
        pir_sensor <= '1';
        wait for 200 ns;
        pir_sensor <= '0';
        wait for 100 ns;

        -- 5. Cuarta deteccion: debe mostrar D4
        pir_sensor <= '1';
        wait for 200 ns;
        pir_sensor <= '0';
        wait for 100 ns;

        -- 6. Quinta deteccion: direccion 04 de la ROM (rellena con 00)
        pir_sensor <= '1';
        wait for 200 ns;
        pir_sensor <= '0';
        wait for 100 ns;

        -- 7. Prueba de boton Reset a mitad de operacion
        reset <= '1';
        wait for 60 ns;
        reset <= '0';
        wait for 60 ns;

        -- 8. Deteccion despues del Reset: los punteros vuelven a 00 y muestra A1 otra vez
        pir_sensor <= '1';
        wait for 200 ns;
        pir_sensor <= '0';
        wait for 100 ns;

        -- Fin de la prueba
        fin_sim <= true;
        wait;
    end process;

end architecture sim;