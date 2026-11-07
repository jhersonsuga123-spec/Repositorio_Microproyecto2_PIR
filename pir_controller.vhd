library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Controlador para sincronizar el sensor PIR y generar un pulso de 1 ciclo
entity pir_controller is
    Port (
        clk            : in  std_logic; -- Reloj del sistema (50 MHz)
        reset          : in  std_logic; -- Reset asíncrono global
        pir_signal     : in  std_logic; -- Entrada física del sensor PIR
        pulse_out      : out std_logic; -- Pulso de 1 ciclo para la FSM
        pir_stable_out : out std_logic  -- Nivel filtrado para WAIT_RELEASE
    );
end entity pir_controller;

architecture rtl of pir_controller is
    signal sync_reg0   : std_logic := '0';
    signal sync_reg1   : std_logic := '0';
    signal edge_detect : std_logic := '0';
begin

    -- Sincronizador de 2 flip-flops para evitar metaestabilidad
    process(clk, reset)
    begin
        if reset = '1' then
            sync_reg0 <= '0';
            sync_reg1 <= '0';
        elsif rising_edge(clk) then
            sync_reg0 <= pir_signal;
            sync_reg1 <= sync_reg0;
        end if;
    end process;

    -- Salida de nivel estable hacia la FSM
    pir_stable_out <= sync_reg1;

    -- Detector de flanco de subida (genera pulso de 1 ciclo)
    process(clk, reset)
    begin
        if reset = '1' then
            edge_detect <= '0';
            pulse_out   <= '0';
        elsif rising_edge(clk) then
            if (sync_reg1 = '1' and edge_detect = '0') then
                pulse_out <= '1';
            else
                pulse_out <= '0';
            end if;
            edge_detect <= sync_reg1;
        end if;
    end process;

end architecture rtl;