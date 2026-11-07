library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pir_controller is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        pir_signal  : in  std_logic; -- Señal física directa del sensor PIR
        pulse_out   : out std_logic  -- Pulso limpio de 1 ciclo de reloj para la FSM
    );
end entity pir_controller;

architecture rtl of pir_controller is
    -- Señales internas para el sincronizador y el detector de flancos
    signal sync_reg0   : std_logic := '0';
    signal sync_reg1   : std_logic := '0';
    signal edge_detect : std_logic := '0';
begin

-- Sincronizador de dos etapas para evitar ruido físico
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
-- Detector de flanco de subida
    process(clk, reset)
    begin
        if reset = '1' then
            edge_detect <= '0';
            pulse_out   <= '0';
        elsif rising_edge(clk) then
            if (sync_reg1 = '1' and edge_detect = '0') then
                pulse_out <= '1'; -- Genera un pulso exacto de 1 ciclo
            else
                pulse_out <= '0';
            end if;
            edge_detect <= sync_reg1;
        end if;
    end process;
	 
end architecture rtl;