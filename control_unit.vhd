library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Maquina de estados que coordina la lectura de ROM y escritura en RAM
entity control_unit is
    Port (
        clk         : in  std_logic; -- Reloj del sistema (50 MHz)
        reset       : in  std_logic; -- Reset asíncrono global
        pulse_in    : in  std_logic; -- Pulso de detección del PIR
        pir_level   : in  std_logic; -- Nivel estable del PIR
        rom_enable  : out std_logic; -- Habilitador de lectura para la ROM
        we_ram      : out std_logic; -- Habilitador de escritura para la RAM
        inc_pointer : out std_logic  -- Incremento de puntero para la RAM
    );
end entity control_unit;

architecture rtl of control_unit is
    -- 5 estados de la FSM
    type state_type is (IDLE, READ_ROM, WRITE_RAM, INC_POINTERS, WAIT_RELEASE);
    signal current_state : state_type := IDLE;
begin

    -- Proceso síncrono: transiciones de estado
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            case current_state is
                
                -- Espera activación del sensor
                when IDLE =>
                    if pulse_in = '1' then
                        current_state <= READ_ROM;
                    else
                        current_state <= IDLE;
                    end if;

                -- Solicita dato a la ROM (latencia de 1 ciclo)
                when READ_ROM =>
                    current_state <= WRITE_RAM;

                -- Guarda dato en RAM
                when WRITE_RAM =>
                    current_state <= INC_POINTERS;

                -- Incrementa dirección de RAM
                when INC_POINTERS =>
                    current_state <= WAIT_RELEASE;

                -- Espera a que el sensor baje a '0'
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

    -- Proceso combinacional: señales de control sin latches
    process(current_state)
    begin
        -- Valores por defecto
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