library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_rsa_sca is
    Generic (
        G_MSG : integer := 5
    );
end tb_rsa_sca;

architecture Behavioral of tb_rsa_sca is

    -- Component Declarations
    component rsa_16bit is
        Port ( clk      : in  STD_LOGIC;
               reset    : in  STD_LOGIC;
               start    : in  STD_LOGIC;
               msg_in   : in  STD_LOGIC_VECTOR (15 downto 0);
               key      : in  STD_LOGIC_VECTOR (15 downto 0);
               modulus  : in  STD_LOGIC_VECTOR (15 downto 0);
               data_out : out STD_LOGIC_VECTOR (15 downto 0);
               ready    : out STD_LOGIC);
    end component;

    component lfsr_3 is
        Port ( clk    : in  STD_LOGIC;
               reset  : in  STD_LOGIC;
               en     : in  STD_LOGIC;
               q      : out STD_LOGIC_VECTOR (2 downto 0));
    end component;

    -- Signals
    signal clk      : std_logic := '0';
    signal reset    : std_logic := '0';
    signal start    : std_logic := '0';
    signal msg_in   : std_logic_vector(15 downto 0) := (others => '0');
    signal key      : std_logic_vector(15 downto 0) := (others => '0');
    signal modulus  : std_logic_vector(15 downto 0) := (others => '0');
    signal data_out : std_logic_vector(15 downto 0);
    signal ready    : std_logic;
    
    signal lfsr_en  : std_logic := '0';
    signal lfsr_q   : std_logic_vector(2 downto 0);

    constant clk_period : time := 10 ns;

begin

    -- Instantiate RSA Top
    uut_rsa: rsa_16bit
        port map (
            clk      => clk,
            reset    => reset,
            start    => start,
            msg_in   => msg_in,
            key      => key,
            modulus  => modulus,
            data_out => data_out,
            ready    => ready
        );

    -- Instantiate LFSR
    uut_lfsr: lfsr_3
        port map (
            clk   => clk,
            reset => reset,
            en    => lfsr_en,
            q     => lfsr_q
        );

    -- Clock Process
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus Process
    stim_proc: process
    begin
        -- Hold reset state
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 10 ns;
        
        -- Start LFSR
        lfsr_en <= '1';

        -- Test Vector Setup (Example values)
        -- Test Vector
        -- key = 3, mod = 17, msg is parameterized
        key     <= x"0003"; 
        modulus <= x"0011"; 
        msg_in  <= std_logic_vector(to_unsigned(G_MSG, 16));
        
        wait for clk_period;
        start <= '1';
        wait for clk_period;
        start <= '0';

        -- Wait for computation to finish
        wait until ready = '1';
        
        wait for 50 ns;
        
        -- Stop simulation
        assert false report "Simulation Finished" severity failure;
    end process;

end Behavioral;
