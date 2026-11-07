library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Modulo principal que enlaza el sensor PIR, la FSM y las memorias ROM y RAM
entity top_system is
    Port (
        clk          : in  std_logic;                    -- Reloj de 50 MHz de la FPGA
        reset        : in  std_logic;                    -- Boton de reinicio general
        pir_sensor   : in  std_logic;                    -- Entrada fisica del sensor PIR
        leds_ram_out : out std_logic_vector(7 downto 0)  -- Salida a los 8 LEDs con el dato guardado
    );
end entity top_system;

architecture structural of top_system is

    -- 1. Componente del controlador del sensor PIR
    component pir_controller is
        Port (
            clk            : in  std_logic;
            reset          : in  std_logic;
            pir_signal     : in  std_logic;
            pulse_out      : out std_logic;
            pir_stable_out : out std_logic
        );
    end component;

    -- 2. Componente de la maquina de estados (FSM)
    component control_unit is
        Port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            pulse_in    : in  std_logic;
            pir_level   : in  std_logic;
            rom_enable  : out std_logic;
            we_ram      : out std_logic;
            inc_pointer : out std_logic
        );
    end component;

    -- 3. Componente de la memoria ROM (datos precargados en .mif)
    component rom_memory is
        Port (
            clk      : in  std_logic;
            enable   : in  std_logic;
            addr     : in  std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0)
        );
    end component;

    -- 4. Componente de la memoria RAM (registro de eventos)
    component ram_memory is
        Port (
            clk      : in  std_logic;
            we       : in  std_logic;
            addr     : in  std_logic_vector(7 downto 0);
            data_in  : in  std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Cables internos para conectar el sensor y la FSM
    signal s_pir_pulse   : std_logic;
    signal s_pir_stable  : std_logic;
    signal s_rom_enable  : std_logic;
    signal s_we_ram      : std_logic;
    signal s_inc_pointer : std_logic;

    -- Bus de datos que lleva el codigo desde la ROM hasta la RAM
    signal s_bus_rom_ram : std_logic_vector(7 downto 0);

    -- Punteros de direcciones para recorrer las memorias
    signal rom_addr_ptr  : std_logic_vector(7 downto 0) := (others => '0');
    signal ram_write_ptr : std_logic_vector(7 downto 0) := (others => '0');
    signal ram_read_ptr  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_ram_addr    : std_logic_vector(7 downto 0);

begin

    -- Mientras se escribe usamos el puntero de escritura; el resto del tiempo
    -- mostramos en los LEDs la ultima posicion que fue guardada
    s_ram_addr <= ram_write_ptr when s_we_ram = '1' else ram_read_ptr;

    -- Instancia 1: Filtro y detector de flanco del PIR
    u_pir : pir_controller
        port map (
            clk            => clk,
            reset          => reset,
            pir_signal     => pir_sensor,
            pulse_out      => s_pir_pulse,
            pir_stable_out => s_pir_stable
        );

    -- Instancia 2: Unidad de control que coordina los tiempos
    u_fsm : control_unit
        port map (
            clk         => clk,
            reset       => reset,
            pulse_in    => s_pir_pulse,
            pir_level   => s_pir_stable,
            rom_enable  => s_rom_enable,
            we_ram      => s_we_ram,
            inc_pointer => s_inc_pointer
        );

    -- Instancia 3: Lectura del codigo en la ROM
    u_rom : rom_memory
        port map (
            clk      => clk,
            enable   => s_rom_enable,
            addr     => rom_addr_ptr,
            data_out => s_bus_rom_ram
        );

    -- Instancia 4: Escritura y visualizacion del evento en la RAM
    u_ram : ram_memory
        port map (
            clk      => clk,
            we       => s_we_ram,
            addr     => s_ram_addr,
            data_in  => s_bus_rom_ram,
            data_out => leds_ram_out
        );

    -- Contador sincrono que avanza las direcciones despues de cada registro
    process(clk, reset)
    begin
        if reset = '1' then
            rom_addr_ptr  <= (others => '0');
            ram_write_ptr <= (others => '0');
            ram_read_ptr  <= (others => '0');
        elsif rising_edge(clk) then
            if s_inc_pointer = '1' then
                ram_read_ptr  <= ram_write_ptr;
                rom_addr_ptr  <= std_logic_vector(unsigned(rom_addr_ptr) + 1);
                ram_write_ptr <= std_logic_vector(unsigned(ram_write_ptr) + 1);
            end if;
        end if;
    end process;

end architecture;