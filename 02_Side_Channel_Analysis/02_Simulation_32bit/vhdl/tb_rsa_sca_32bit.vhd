library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_rsa_sca_32bit is
    Generic (
        G_MSG : integer := 305419896 -- 0x12345678
    );
end tb_rsa_sca_32bit;

architecture Behavioral of tb_rsa_sca_32bit is

    component rsa_32bit is
        Port ( clk      : in  STD_LOGIC;
               reset    : in  STD_LOGIC;
               start    : in  STD_LOGIC;
               msg_in   : in  STD_LOGIC_VECTOR (31 downto 0);
               key      : in  STD_LOGIC_VECTOR (31 downto 0);
               modulus  : in  STD_LOGIC_VECTOR (31 downto 0);
               data_out : out STD_LOGIC_VECTOR (31 downto 0);
               ready    : out STD_LOGIC);
    end component;

    component lfsr_32 is
        Port ( clk    : in  STD_LOGIC;
               reset  : in  STD_LOGIC;
               en     : in  STD_LOGIC;
               q      : out STD_LOGIC_VECTOR (31 downto 0));
    end component;

    signal clk      : std_logic := '0';
    signal reset    : std_logic := '0';
    signal start    : std_logic := '0';
    signal msg_in   : std_logic_vector(31 downto 0) := (others => '0');
    signal key      : std_logic_vector(31 downto 0) := (others => '0');
    signal modulus  : std_logic_vector(31 downto 0) := (others => '0');
    signal data_out : std_logic_vector(31 downto 0);
    signal ready    : std_logic;
    
    signal lfsr_en  : std_logic := '0';
    signal lfsr_q   : std_logic_vector(31 downto 0);

    constant clk_period : time := 10 ns;

begin

    uut_rsa: rsa_32bit
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

    uut_lfsr: lfsr_32
        port map (
            clk   => clk,
            reset => reset,
            en    => lfsr_en,
            q     => lfsr_q
        );

    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait for 10 ns;
        
        lfsr_en <= '1';

        -- 32-bit test vectors
        -- e.g. K=0x00000003, N=0x7FFFFFFF (prime)
        msg_in  <= std_logic_vector(to_unsigned(G_MSG, 32)); 
        key     <= x"00000003"; 
        modulus <= x"7FFFFFFF"; 
        
        wait for clk_period;
        start <= '1';
        wait for clk_period;
        start <= '0';

        wait until ready = '1';
        wait for 50 ns;
        
        assert false report "Simulation Finished" severity failure;
    end process;

end Behavioral;
