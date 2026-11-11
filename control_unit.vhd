library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Maquina de Estados Finitos tipo Moore para orquestar la ruta de datos y control de memorias
entity control_unit is
    Port (
        clk         : in  std_logic; 
        reset       : in  std_logic; 
        pulse_in    : in  std_logic; -- Pulso de activacion proveniente del detector de flanco
        pir_level   : in  std_logic; -- Nivel de presencia para la logica de retencion
        rom_enable  : out std_logic; -- Señal de habilitacion de lectura de la rom
        we_ram      : out std_logic; -- Señal de habilitacion de escritura de la ram 
        inc_pointer : out std_logic  -- Señal de control para actualizacion de punteros
    );
end entity control_unit;

architecture rtl of control_unit is
    -- Definicion de los 5 estados secuenciales de la FSM
    type state_type is (IDLE, READ_ROM, WRITE_RAM, INC_POINTERS, WAIT_RELEASE);
    signal current_state : state_type := IDLE;
begin

    -- Proceso sincrono: Logica de transicion de estados
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            case current_state is
                
                -- Estado de reposo: a la espera del flanco de activacion del sensor
                when IDLE =>
                    if pulse_in = '1' then
                        current_state <= READ_ROM;
                    else
                        current_state <= IDLE;
                    end if;

                -- Habilita la lectura de la rom (requiere 1 ciclo de latencia)
                when READ_ROM =>
                    current_state <= WRITE_RAM;

                -- Ejecuta la escritura sincrona en la ram
                when WRITE_RAM =>
                    current_state <= INC_POINTERS;

                -- Incrementa las direcciones de memoria
                when INC_POINTERS =>
                    current_state <= WAIT_RELEASE;

                -- Estado de retencion: Desacopla la velocidad de operacion de la FPGA respecto a la latencia fisica del sensor para evitar sobreescritura de datos
                when WAIT_RELEASE =>
                    if pir_level = '1' then
                        current_state <= WAIT_RELEASE;
                    else
                        current_state <= IDLE;
                    end if;

                when others =>
                    current_state <= IDLE;
            end case;
        end if;
    end process;

    -- Proceso combinacional: Logica de salidas (valores por defecto para evitar inferencia de cerrojos o latches)
    process(current_state)
    begin
        rom_enable  <= '0';
        we_ram      <= '0';
        inc_pointer <= '0';

        case current_state is
            when IDLE =>
                null;

            when READ_ROM =>
                rom_enable <= '1';

            when WRITE_RAM =>
                we_ram <= '1';

            when INC_POINTERS =>
                inc_pointer <= '1';

            when WAIT_RELEASE =>
                null;

            when others =>
                null;
        end case;
    end process;

end architecture rtl;