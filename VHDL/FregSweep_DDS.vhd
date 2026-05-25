library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity DDS_Sweep is
port (
   clk             : in  std_logic := '0';  -- 100 MHz system clock
   reset           : in  std_logic;

   DDS_data_tvalid : out std_logic;
   DDS_data_tdata  : out std_logic_vector(15 downto 0)
);
end DDS_Sweep;

architecture Behavioral of DDS_Sweep is

--------------------------------------------------------------------
-- DDS interface signals
--------------------------------------------------------------------
signal s_axis_phase_tvalid_sig : std_logic := '0';
signal s_axis_phase_tdata_sig   : std_logic_vector(31 downto 0) := (others => '0');
signal m_axis_data_tvalid_sig   : std_logic;

--------------------------------------------------------------------
-- Sweep parameters (30-bit DDS phase accumulator)
--------------------------------------------------------------------
constant PH_INC_STEP   : unsigned(29 downto 0) := to_unsigned(10737, 30);
constant MAX_STEP      : integer := 41;
constant DWELL_COUNT   : integer := 100000; -- 1 ms @ 100 MHz

--------------------------------------------------------------------
-- Sweep registers
--------------------------------------------------------------------
signal dwell_counter   : integer range 0 to DWELL_COUNT := 0;
signal step_count      : integer range 1 to MAX_STEP := 1;
signal current_ph_inc  : unsigned(29 downto 0) := to_unsigned(10737, 30);

--------------------------------------------------------------------
-- DDS IP
--------------------------------------------------------------------
component dds_compiler_0
  port (
    aclk                  : in  std_logic;
    s_axis_phase_tvalid   : in  std_logic;
    s_axis_phase_tdata    : in  std_logic_vector(31 downto 0);
    m_axis_data_tvalid    : out std_logic;
    m_axis_data_tdata     : out std_logic_vector(15 downto 0)
  );
end component;

begin

--------------------------------------------------------------------
-- DDS instance
--------------------------------------------------------------------
DDS_Sweep : dds_compiler_0
port map (
    aclk                => clk,
    s_axis_phase_tvalid => s_axis_phase_tvalid_sig,
    s_axis_phase_tdata  => s_axis_phase_tdata_sig,
    m_axis_data_tvalid  => m_axis_data_tvalid_sig,
    m_axis_data_tdata   => DDS_data_tdata
);

-- Output valid passthrough
DDS_data_tvalid <= m_axis_data_tvalid_sig;

--------------------------------------------------------------------
-- Sweep generator
--------------------------------------------------------------------
process(clk)
begin
    if rising_edge(clk) then

        if reset = '1' then
            dwell_counter          <= 0;
            step_count             <= 1;
            current_ph_inc         <= PH_INC_STEP;

            s_axis_phase_tvalid_sig <= '0';
            s_axis_phase_tdata_sig  <= (others => '0');

        else
            s_axis_phase_tvalid_sig <= '0';

            if dwell_counter = DWELL_COUNT - 1 then
                dwell_counter <= 0;

                -- send new FTW to DDS
                s_axis_phase_tdata_sig <= std_logic_vector(resize(current_ph_inc, 32));
                s_axis_phase_tvalid_sig <= '1';

                -- update sweep
                if step_count = MAX_STEP then
                    step_count     <= 1;
                    current_ph_inc <= PH_INC_STEP;
                else
                    step_count     <= step_count + 1;
                    current_ph_inc <= current_ph_inc + PH_INC_STEP;
                end if;

            else
                dwell_counter <= dwell_counter + 1;
            end if;

        end if;

    end if;
end process;

end Behavioral;