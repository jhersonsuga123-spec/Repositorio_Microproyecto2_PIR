library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Banco de pruebas para ver los flancos de subida y bajada del sistema
entity tb_top_system is
end entity tb_top_system;

architecture sim of tb_top_system is

    -- Declaramos el bloque principal tal como esta en top_system
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

    -- Senales para inyectar valores y ver las respuestas en la grafica
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0'; -- Inicia en 0 porque el boton de la placa es activo en bajo
    signal pir_sensor : std_logic := '0';
    signal led_detect : std_logic;
    signal hex0       : std_logic_vector(6 downto 0);
    signal hex1       : std_logic_vector(6 downto 0);
    signal hex2       : std_logic_vector(6 downto 0);
    signal hex3       : std_logic_vector(6 downto 0);

    -- Reloj de 50 MHz (un ciclo cada 20 ns)
    constant CLK_PERIOD : time := 20 ns;
    signal fin_prueba   : boolean := false;

begin

    -- Conectamos las senales de prueba con el modulo principal
    uut : top_system
        port map (
            clk        => clk,
            reset      => reset,
            pir_sensor => pir_sensor,
            led_detect => led_detect,
            hex0       => hex0,
            hex1       => hex1,
            hex2       => hex2,
            hex3       => hex3
        );

    -- Proceso que genera los flancos de subida y bajada del reloj todo el tiempo
    reloj_proc : process
    begin
        while not fin_prueba loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Proceso donde simulamos el movimiento frente al sensor PIR
    estimulos_proc : process
    begin
        -- 1. Empezamos presionando el reset (en '0') y luego lo soltamos (sube a '1')
        reset      <= '0';
        pir_sensor <= '0';
        wait for 60 ns;
        reset      <= '1'; -- Flanco de subida: el sistema arranca a funcionar
        wait for 80 ns;

        -- 2. Primera persona detectada: flanco de subida en el sensor
        pir_sensor <= '1';
        wait for 300 ns;   -- Se mantiene arriba para activar el LED y guardar en RAM
        pir_sensor <= '0'; -- Flanco de bajada: la persona se retira
        wait for 200 ns;

        -- 3. Ruido corto (sube y baja muy rapido para ver como el filtro lo ignora)
        pir_sensor <= '1';
        wait for 40 ns;
        pir_sensor <= '0';
        wait for 160 ns;

        -- 4. Segunda persona detectada (dura mas tiempo frente al sensor)
        pir_sensor <= '1';
        wait for 400 ns;
        pir_sensor <= '0'; -- Flanco de bajada
        wait for 200 ns;

        -- 5. Tercera persona detectada
        pir_sensor <= '1';
        wait for 300 ns;
        pir_sensor <= '0'; -- Flanco de bajada
        wait for 200 ns;

        -- 6. Presionamos el boton de reset (baja a '0') para limpiar todo
        reset <= '0';
        wait for 60 ns;
        reset <= '1';      -- Sube de nuevo a '1'
        wait for 80 ns;

        -- 7. Cuarta deteccion despues del reinicio
        pir_sensor <= '1';
        wait for 300 ns;
        pir_sensor <= '0';
        wait for 200 ns;

        -- Terminamos la simulacion
        fin_prueba <= true;
        wait;
    end process;

end architecture sim;