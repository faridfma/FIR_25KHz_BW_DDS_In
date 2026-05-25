library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity DDS_Sweep is
port (
   clk             : in std_logic := '0';  --system cock running at 399.68MHz
   reset           : in std_logic; 

   DDS_data_tvalid : OUT STD_LOGIC;
   DDS_data_tdata  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
); 
end DDS_Sweep;

architecture Behavioral of DDS_Sweep is

signal s_axis_phase_tvalid_sig : std_logic :='0'; 
signal s_axis_phase_tdata_Sig  : STD_LOGIC_VECTOR(31 DOWNTO 0):="00000000000000000000000000000000"; 
signal m_axis_data_tready_Sig  : std_logic:='0'; 
signal m_axis_data_tvalid_Sig  : std_logic; 

--------------------------------------------------------------------
-- Sweep Parameters
--------------------------------------------------------------------
constant FTW_STEP       : unsigned(29 downto 0):= to_unsigned(10737,30);
constant MAX_FREQ_STEP  : integer := 41;
constant DWELL_COUNT    : integer := 100000; -- 1ms @ 100 MHz
--------------------------------------------------------------------
-- Sweep Registers
--------------------------------------------------------------------
signal dwell_counter : integer range 0 to DWELL_COUNT := 0;
signal freq_step     : integer range 1 to MAX_FREQ_STEP := 1;
signal current_ftw   : unsigned(29 downto 0):= to_unsigned(10737,30);



signal state : integer := 0;
 
 -- Declare signals instead of variables
signal PhaseIncrConstant : integer := 10737;       -- Initialize PhaseIncrConstant
signal freq_phase_incr   : integer := 0;           -- Initialize freq_phase_incr
signal FreqSweepCnt      : integer := 1;           -- Initialize FreqSweepCnt
signal period_wait_cnt   : integer := 0;           -- Initialize period_wait_cnt
signal chirp_loop_cntr   : integer := 0;           -- Initialize chirp_loop_cntr
signal freq_period       : integer := 100000;      -- Initialize Dwell Time is 1ms. 


------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT dds_compiler_0
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_phase_tvalid : IN STD_LOGIC;
    s_axis_phase_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;
    
begin

DDS_Sweep : dds_compiler_0
  PORT MAP (
    aclk => clk,
    s_axis_phase_tvalid => s_axis_phase_tvalid_sig,
    s_axis_phase_tdata =>  s_axis_phase_tdata_sig,
    m_axis_data_tvalid => m_axis_data_tvalid_Sig,
    m_axis_data_tdata =>  DDS_data_tdata
    
  );

--------------------------------------------------------------------
-- Sweep Generator
--------------------------------------------------------------------

process(clk)

begin

    if rising_edge(clk) then

        if reset = '1' then
            dwell_counter    <= 0;
            freq_step        <= 1;
            current_ftw      <= FTW_STEP;
            phase_tvalid_sig <= '0';
            phase_tdata_sig  <= std_logic_vector(FTW_STEP);
        else
            phase_tvalid_sig <= '0';
            
            if dwell_counter = DWELL_COUNT-1 then
                dwell_counter <= 0;
                phase_tdata_sig <= std_logic_vector(current_ftw);

                phase_tvalid_sig <= '1';
                if freq_step = MAX_FREQ_STEP then
                    freq_step   <= 1;
                    current_ftw <= FTW_STEP;
                else
                    freq_step   <= freq_step + 1;
                    current_ftw <= current_ftw + FTW_STEP;
                end if;
            else
                dwell_counter <= dwell_counter + 1;
            end if;

        end if;

    end if;

end process;

end Behavioral;
