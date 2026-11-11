library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Testbench: Banco de pruebas para validacion logica y analisis temporal en ModelSim.
entity tb_top_system is
end entity tb_top_system;

architecture sim of tb_top_system is

    -- Declaracion del modulo bajo prueba (DUT)
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

    -- Senales de estimulo y monitoreo
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '0'; -- Inicializacion logica baja (pulsador Pull-Up)
    signal pir_sensor : std_logic := '0';
    signal led_detect : std_logic;
    signal hex0       : std_logic_vector(6 downto 0);
    signal hex1       : std_logic_vector(6 downto 0);
    signal hex2       : std_logic_vector(6 downto 0);
    signal hex3       : std_logic_vector(6 downto 0);

    -- Parametrizacion del reloj de sistema a 50 MHz
    constant CLK_PERIOD : time := 20 ns;
    signal fin_prueba   : boolean := false;

begin

    -- Instanciacion del DUT
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

    -- Generador de señal de reloj continuo
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

    -- Proceso principal: Aplicacion de vectores de prueba y estimulos al sensor
    estimulos_proc : process
    begin
        -- Secuencia de inicializacion y reset del sistema
        reset      <= '0';
        pir_sensor <= '0';
        wait for 60 ns;
        reset      <= '1'; 
        wait for 80 ns;

        -- Vector de prueba 1: Deteccion estandar y evaluacion de la retencion WAIT_RELEASE
        pir_sensor <= '1';
        wait for 300 ns;   
        pir_sensor <= '0'; 
        wait for 200 ns;

        -- Vector de prueba 2: Inyeccion de transitorio de 40 ns para verificar rechazo del filtro
        pir_sensor <= '1';
        wait for 40 ns;
        pir_sensor <= '0';
        wait for 160 ns;

        -- Vector de prueba 3: Segundo pulso valido con retencion extendida
        pir_sensor <= '1';
        wait for 400 ns;
        pir_sensor <= '0'; 
        wait for 200 ns;

        -- Vector de prueba 4: Tercer pulso valido
        pir_sensor <= '1';
        wait for 300 ns;
        pir_sensor <= '0'; 
        wait for 200 ns;

        -- Prueba de integridad tras reset asincrono en tiempo de ejecucion
        reset <= '0';
        wait for 60 ns;
        reset <= '1';      
        wait for 80 ns;

        -- Vector de prueba 5: Deteccion post-reset
        pir_sensor <= '1';
        wait for 300 ns;
        pir_sensor <= '0';
        wait for 200 ns;

        -- Finalizacion controlada de la simulacion
        fin_prueba <= true;
        wait;
    end process;

end architecture sim;