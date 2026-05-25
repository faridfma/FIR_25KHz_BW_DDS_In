library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

entity tb_FIR_TopLevel is
end tb_FIR_TopLevel;

architecture sim of tb_FIR_TopLevel is

--------------------------------------------------------------------
-- DUT signals
--------------------------------------------------------------------
signal clk      : std_logic := '0';
signal reset    : std_logic := '1';

signal fir_out  : std_logic_vector(15 downto 0);

--------------------------------------------------------------------
-- Clock period
--------------------------------------------------------------------
constant CLK_PERIOD : time := 10 ns;  -- 100 MHz

--------------------------------------------------------------------
-- File handling
--------------------------------------------------------------------
file fir_file : text open write_mode is "fir_output.txt";

begin

--------------------------------------------------------------------
-- DUT
--------------------------------------------------------------------
DUT : entity work.FIR_TopLevel
port map (
    clk     => clk,
    reset   => reset,
    fir_out => fir_out
);

--------------------------------------------------------------------
-- Clock generation
--------------------------------------------------------------------
clk_process : process
begin
    while true loop
        clk <= '0';
        wait for CLK_PERIOD/2;

        clk <= '1';
        wait for CLK_PERIOD/2;
    end loop;
end process;

--------------------------------------------------------------------
-- Reset generation
--------------------------------------------------------------------
reset_process : process
begin
    reset <= '1';

    wait for 100 ns;

    reset <= '0';

    wait;
end process;

--------------------------------------------------------------------
-- Capture FIR output to file
--------------------------------------------------------------------
write_process : process(clk)

    variable line_var : line;
    variable fir_int  : integer;

begin

    if rising_edge(clk) then

        if reset = '0' then

            -- convert FIR output to signed integer
            fir_int := to_integer(signed(fir_out));

            -- write value to file
            write(line_var, fir_int);

            writeline(fir_file, line_var);

        end if;

    end if;

end process;

--------------------------------------------------------------------
-- Stop simulation
--------------------------------------------------------------------
stop_process : process
begin

    wait for 20 ms;

    assert false
    report "Simulation Finished"
    severity failure;

end process;

end sim;