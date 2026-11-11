library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Entidad top level (en este caso top system): Integracion jerarquica de la FSM, datapath, memorias y perifericos.
entity top_system is
    Port (
        clk        : in  std_logic;                    -- Reloj principal del sistema (50 MHz)
        reset      : in  std_logic;                    -- Reset global asincrono
        pir_sensor : in  std_logic;                    -- Entrada fisica del modulo PIR
        led_detect : out std_logic;                    -- Indicador visual de presencia en estado activo
        hex0       : out std_logic_vector(6 downto 0); -- Salidas codificadas hacia los 4 displays
        hex1       : out std_logic_vector(6 downto 0); 
        hex2       : out std_logic_vector(6 downto 0); 
        hex3       : out std_logic_vector(6 downto 0)  
    );
end entity top_system;

architecture structural of top_system is

    -- Declaracion de componentes internos
    component pir_controller is
        Port (
            clk            : in  std_logic;
            reset          : in  std_logic;
            pir_signal     : in  std_logic;
            pulse_out      : out std_logic;
            pir_stable_out : out std_logic
        );
    end component;

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

    component rom_memory is
        Port (
            clk      : in  std_logic;
            enable   : in  std_logic;
            addr     : in  std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(15 downto 0)
        );
    end component;

    component ram_memory is
        Port (
            clk      : in  std_logic;
            we       : in  std_logic;
            addr     : in  std_logic_vector(7 downto 0);
            data_in  : in  std_logic_vector(15 downto 0);
            data_out : out std_logic_vector(15 downto 0)
        );
    end component;

    component dec_7seg is
        Port (
            hex_digit : in  std_logic_vector(3 downto 0);
            seg       : out std_logic_vector(6 downto 0)
        );
    end component;

    -- Señales de interconexion logica y control de FSM
    signal s_reset        : std_logic;
    signal s_pir_pulse    : std_logic;
    signal s_pir_stable   : std_logic;
    signal s_rom_enable   : std_logic;
    signal s_we_ram       : std_logic;
    signal s_inc_pointer  : std_logic;

    -- Bus de datos compartido entre la salida de la rom y la entrada de la ram
    signal s_bus_rom_ram  : std_logic_vector(15 downto 0);
    signal s_ram_data_out : std_logic_vector(15 downto 0);

    -- Punteros y registros de direcciones de memoria
    signal rom_addr_ptr   : std_logic_vector(7 downto 0) := (others => '0');
    signal ram_write_ptr  : std_logic_vector(7 downto 0) := (others => '0');
    signal ram_read_ptr   : std_logic_vector(7 downto 0) := (others => '0');
    signal s_ram_addr     : std_logic_vector(7 downto 0);

    -- Oscilador libre para la seleccion aleatoria de vectores
    signal free_running_counter : unsigned(7 downto 0) := (others => '0');

    -- Señal de acoplamiento hacia los decodificadores de display
    signal codigo_display : std_logic_vector(15 downto 0);

begin

    -- Acondicionamiento de logica negada para pulsadores pull-up
    s_reset <= not reset;

    -- Indicacion de retencion fisica del sensor
    led_detect <= s_pir_stable;

    -- Multiplexor de direcciones: alterna el acceso a ram entre el ciclo de escritura y la retencion de lectura
    s_ram_addr <= ram_write_ptr when s_we_ram = '1' else ram_read_ptr;

    -- Inhibicion visual (Blanking) durante el estado de reset inicial
    codigo_display <= s_ram_data_out when ram_write_ptr /= "00000000" else (others => '0');

    -- Instanciacion del acondicionador del sensor pir
    u_pir : pir_controller
        port map (
            clk            => clk,
            reset          => s_reset,
            pir_signal     => pir_sensor,
            pulse_out      => s_pir_pulse,
            pir_stable_out => s_pir_stable
        );

    -- Instanciacion de la Unidad de Control (FSM)
    u_fsm : control_unit
        port map (
            clk         => clk,
            reset       => s_reset,
            pulse_in    => s_pir_pulse,
            pir_level   => s_pir_stable,
            rom_enable  => s_rom_enable,
            we_ram      => s_we_ram,
            inc_pointer => s_inc_pointer
        );

    -- Instanciacion de la memoria de solo lectura (rom)
    u_rom : rom_memory
        port map (
            clk      => clk,
            enable   => s_rom_enable,
            addr     => rom_addr_ptr,
            data_out => s_bus_rom_ram
        );

    -- Instanciacion de la memoria de acceso aleatorio (ram)
    u_ram : ram_memory
        port map (
            clk      => clk,
            we       => s_we_ram,
            addr     => s_ram_addr,
            data_in  => s_bus_rom_ram,
            data_out => s_ram_data_out
        );

    -- Asignacion paralela del bus de datos a la etapa de decodificacion visual
    u_hex0 : dec_7seg port map (hex_digit => codigo_display(3 downto 0),   seg => hex0);
    u_hex1 : dec_7seg port map (hex_digit => codigo_display(7 downto 4),   seg => hex1);
    u_hex2 : dec_7seg port map (hex_digit => codigo_display(11 downto 8),  seg => hex2);
    u_hex3 : dec_7seg port map (hex_digit => codigo_display(15 downto 12), seg => hex3);

    -- Proceso 1: Generador aleatorio basado en un contador de alta velocidad
    process(clk, s_reset)
    begin
        if s_reset = '1' then
            free_running_counter <= (others => '0');
        elsif rising_edge(clk) then
            if free_running_counter = 11 then
                free_running_counter <= (others => '0');
            else
                free_running_counter <= free_running_counter + 1;
            end if;
        end if;
    end process;

    -- Proceso 2: Gestion de punteros y captura del vector de direccion aleatoria
    process(clk, s_reset)
    begin
        if s_reset = '1' then
            rom_addr_ptr  <= (others => '0');
            ram_write_ptr <= (others => '0');
            ram_read_ptr  <= (others => '0');
        elsif rising_edge(clk) then
            -- Actualizacion secuencial condicionada por la señal de control de la FSM
            if s_inc_pointer = '1' then
                ram_read_ptr  <= ram_write_ptr;
                ram_write_ptr <= std_logic_vector(unsigned(ram_write_ptr) + 1);

                -- Retencion de la direccion (Latch) derivada del contador libre
                rom_addr_ptr  <= std_logic_vector(free_running_counter);
            end if;
        end if;
    end process;

end architecture structural;