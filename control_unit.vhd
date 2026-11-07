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