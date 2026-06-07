library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mod_exp_tb is
end mod_exp_tb;

architecture Behavioral of mod_exp_tb is
    
    -- Bileşen Tanımı
    component mod_exp is
        Generic ( DATA_WIDTH : integer := 16 ); -- 16 bit
        Port (
            clk     : in  std_logic;
            rst     : in  std_logic;
            start   : in  std_logic;
            base    : in  std_logic_vector(15 downto 0);
            exp     : in  std_logic_vector(15 downto 0);
            modulus : in  std_logic_vector(15 downto 0);
            result  : out std_logic_vector(15 downto 0);
            done    : out std_logic
        );
    end component;

    -- Sinyaller
    signal clk     : std_logic := '0';
    signal rst     : std_logic := '0';
    signal start   : std_logic := '0';
    signal base    : std_logic_vector(15 downto 0) := (others => '0');
    signal exp     : std_logic_vector(15 downto 0) := (others => '0');
    signal modulus : std_logic_vector(15 downto 0) := (others => '0');
    signal result  : std_logic_vector(15 downto 0);
    signal done    : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- UUT (Unit Under Test) Bağlantısı
    uut: mod_exp 
        generic map (DATA_WIDTH => 16)
        port map (
            clk => clk,
            rst => rst,
            start => start,
            base => base,
            exp => exp,
            modulus => modulus,
            result => result,
            done => done
        );

    -- Clock Üretimi
    process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Test Senaryosu
    process
    begin
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 10 ns;

        base    <= std_logic_vector(to_unsigned(4, 16));
        exp     <= std_logic_vector(to_unsigned(13, 16));
        modulus <= std_logic_vector(to_unsigned(497, 16));
        
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        wait until done = '1';
        
        wait for 20 ns;
        

        assert false report "Simülasyon Bitti" severity failure;
    end process;

end Behavioral;