library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.all;

entity tb_FIR_TopLevel is
end tb_FIR_TopLevel;

architecture sim of tb_FIR_TopLevel is

--------------------------------------------------------------------
-- DUT Signals
--------------------------------------------------------------------
signal clk        : std_logic := '0';
signal reset      : std_logic := '1';

signal fir_out    : std_logic_vector(15 downto 0);
signal fir_valid  : std_logic;

--------------------------------------------------------------------
-- Clock Period
--------------------------------------------------------------------
constant CLK_PERIOD : time := 10 ns; -- 100 MHz

--------------------------------------------------------------------
-- Output File
--------------------------------------------------------------------
file fir_file : text open write_mode is "fir_output.txt";

begin

--------------------------------------------------------------------
-- DUT
--------------------------------------------------------------------
DUT : entity work.FIR_TopLevel
port map (
    clk       => clk,
    reset     => reset,
    fir_out   => fir_out,
    fir_valid => fir_valid
);

--------------------------------------------------------------------
-- Clock Generation
--------------------------------------------------------------------
clk_process : process
begin

    while true loop

        clk <= '0';
        wait for CLK_PERIOD / 2;

        clk <= '1';
        wait for CLK_PERIOD / 2;

    end loop;

end process;

--------------------------------------------------------------------
-- Reset Generation
--------------------------------------------------------------------
reset_process : process
begin

    reset <= '1';

    wait for 100 ns;

    reset <= '0';

    wait;

end process;

--------------------------------------------------------------------
-- Write FIR Output Samples
--------------------------------------------------------------------
write_process : process(clk)

    variable line_var : line;
    variable fir_int  : integer;

begin

    if rising_edge(clk) then

        if reset = '0' and fir_valid = '1' then

            fir_int := to_integer(signed(fir_out));

            write(line_var, fir_int);

            writeline(fir_file, line_var);

            flush(fir_file);

        end if;

    end if;

end process;

--------------------------------------------------------------------
-- Stop Simulation
--------------------------------------------------------------------
stop_process : process
begin

    wait for 30 ms;

    report "Simulation Finished";

    file_close(fir_file);

    std.env.stop;

    wait;

end process;

end sim;