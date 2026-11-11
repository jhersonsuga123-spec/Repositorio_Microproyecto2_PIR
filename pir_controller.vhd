library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Modulo de acondicionamiento de señal: Sincronizador, filtro digital y detector de flanco para el sensor pir
entity pir_controller is
    Port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        pir_signal     : in  std_logic; -- Señal asincrona proveniente del sensor
        pulse_out      : out std_logic; -- Pulso de un ciclo de reloj ante flanco de subida validado
        pir_stable_out : out std_logic  -- Nivel logico estabilizado y filtrado
    );
end entity pir_controller;

architecture behavioral of pir_controller is
    signal sync1, sync2       : std_logic := '0';
    signal pir_debounced      : std_logic := '0';
    signal pir_debounced_prev : std_logic := '0';
    
    -- Contador de retardo para filtrado de transitorios, es decir el debounce
    signal debounce_counter   : unsigned(19 downto 0) := (others => '0');
begin

    process(clk, reset)
    begin
        if reset = '1' then
            sync1              <= '0';
            sync2              <= '0';
            pir_debounced      <= '0';
            pir_debounced_prev <= '0';
            debounce_counter   <= (others => '0');
            pulse_out          <= '0';
        elsif rising_edge(clk) then
            
            -- Sincronizador de 2 etapas para mitigar metaestabilidad en el cruce de dominios
            sync1 <= pir_signal;
            sync2 <= sync1;

            -- Filtro digital: Valida el cambio logico solo tras 5 ciclos de estabilidad continua
            if sync2 /= pir_debounced then
                debounce_counter <= debounce_counter + 1;
                if debounce_counter = 5 then
                    pir_debounced    <= sync2;
                    debounce_counter <= (others => '0');
                end if;
            else
                debounce_counter <= (others => '0');
            end if;

            -- Detector de flanco de subida sobre la señal acondicionada
            pir_debounced_prev <= pir_debounced;
            if (pir_debounced = '1' and pir_debounced_prev = '0') then
                pulse_out <= '1';
            else
                pulse_out <= '0';
            end if;
        end if;
    end process;

    -- Asignacion continua del nivel logico estable
    pir_stable_out <= pir_debounced;

end architecture behavioral;