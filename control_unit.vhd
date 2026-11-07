library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_unit is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        pulse_in     : in  std_logic;
        pir_level    : in  std_logic;
        rom_enable   : out std_logic; 
        we_ram       : out std_logic; 
        inc_pointer  : out std_logic  
    );
end entity control_unit;

architecture rtl of control_unit is
    type state_type is (IDLE, READ_ROM, WRITE_RAM, INC_POINTERS, WAIT_RELEASE);
    signal current_state : state_type := IDLE;
begin

    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            case current_state is
                
                when IDLE =>
                    if pulse_in = '1' then
                        current_state <= READ_ROM;
                    else
                        current_state <= IDLE;
                    end if;

                when READ_ROM =>
                    current_state <= WRITE_RAM;

                when WRITE_RAM =>
                    current_state <= INC_POINTERS;

                when INC_POINTERS =>
                    current_state <= WAIT_RELEASE;

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
	 
    process(current_state, pir_level)
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