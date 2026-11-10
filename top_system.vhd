library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Modulo principal: asignacion aleatoria de codigos de 16 bits con registro en RAM y salida a 4 displays
entity top_system is
    Port (
        clk        : in  std_logic;                    -- Reloj de 50 MHz
        reset      : in  std_logic;                    -- Boton 2 (activo en bajo)
        pir_sensor : in  std_logic;                    -- Switch o entrada fisica del sensor PIR
        led_detect : out std_logic;                    -- LED indicador de deteccion en vivo
        hex0       : out std_logic_vector(6 downto 0); -- Display 0: Bits [3..0]
        hex1       : out std_logic_vector(6 downto 0); -- Display 1: Bits [7..4]
        hex2       : out std_logic_vector(6 downto 0); -- Display 2: Bits [11..8]
        hex3       : out std_logic_vector(6 downto 0)  -- Display 3: Bits [15..12]
    );
end entity top_system;

architecture structural of top_system is

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

    signal s_reset        : std_logic;
    signal s_pir_pulse    : std_logic;
    signal s_pir_stable   : std_logic;
    signal s_rom_enable   : std_logic;
    signal s_we_ram       : std_logic;
    signal s_inc_pointer  : std_logic;

    -- Bus de 16 bits para transferir los codigos alfanumericos
    signal s_bus_rom_ram  : std_logic_vector(15 downto 0);
    signal s_ram_data_out : std_logic_vector(15 downto 0);

    -- Punteros de memoria
    signal rom_addr_ptr   : std_logic_vector(7 downto 0) := (others => '0');
    signal ram_write_ptr  : std_logic_vector(7 downto 0) := (others => '0');
    signal ram_read_ptr   : std_logic_vector(7 downto 0) := (others => '0');
    signal s_ram_addr     : std_logic_vector(7 downto 0);

    -- Contador libre a 50 MHz para seleccion aleatoria (oscila entre 0 y 11)
    signal free_running_counter : unsigned(7 downto 0) := (others => '0');

    -- Codigo actual a mostrar en los displays
    signal codigo_display : std_logic_vector(15 downto 0);

begin

    -- Adaptacion para BUTTON[2] de la DE0 (activo en bajo)
    s_reset <= not reset;

    -- LED testigo activo mientras la persona este frente al sensor
    led_detect <= s_pir_stable;

    -- Multiplexado de direccion de RAM (escritura vs lectura del ultimo registro)
    s_ram_addr <= ram_write_ptr when s_we_ram = '1' else ram_read_ptr;

    -- En reposo inicial muestra ceros; tras el primer registro muestra el codigo asignado
    codigo_display <= s_ram_data_out when ram_write_ptr /= "00000000" else (others => '0');

    -- Instancia 1: Filtro antirrebote y sincronizador del sensor PIR
    u_pir : pir_controller
        port map (
            clk            => clk,
            reset          => s_reset,
            pir_signal     => pir_sensor,
            pulse_out      => s_pir_pulse,
            pir_stable_out => s_pir_stable
        );

    -- Instancia 2: FSM de control
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

    -- Instancia 3: Banco de codigos precargados (ROM de 16 bits)
    u_rom : rom_memory
        port map (
            clk      => clk,
            enable   => s_rom_enable,
            addr     => rom_addr_ptr,
            data_out => s_bus_rom_ram
        );

    -- Instancia 4: Registro historico de codigos asignados (RAM de 16 bits)
    u_ram : ram_memory
        port map (
            clk      => clk,
            we       => s_we_ram,
            addr     => s_ram_addr,
            data_in  => s_bus_rom_ram,
            data_out => s_ram_data_out
        );

    -- Instancias 5 a 8: Decodificacion a los 4 displays HEX
    u_hex0 : dec_7seg port map (hex_digit => codigo_display(3 downto 0),   seg => hex0);
    u_hex1 : dec_7seg port map (hex_digit => codigo_display(7 downto 4),   seg => hex1);
    u_hex2 : dec_7seg port map (hex_digit => codigo_display(11 downto 8),  seg => hex2);
    u_hex3 : dec_7seg port map (hex_digit => codigo_display(15 downto 12), seg => hex3);

    -- Proceso 1: Contador libre que oscila continuamente a 50 MHz (cada 20 ns)
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

    -- Proceso 2: Punteros de memoria con muestreo aleatorio en cada deteccion
    process(clk, s_reset)
    begin
        if s_reset = '1' then
            rom_addr_ptr  <= (others => '0');
            ram_write_ptr <= (others => '0');
            ram_read_ptr  <= (others => '0');
        elsif rising_edge(clk) then
            if s_inc_pointer = '1' then
                ram_read_ptr  <= ram_write_ptr;
                ram_write_ptr <= std_logic_vector(unsigned(ram_write_ptr) + 1);

                -- Captura instantanea de la posicion aleatoria del contador libre
                rom_addr_ptr  <= std_logic_vector(free_running_counter);
            end if;
        end if;
    end process;

end architecture structural;