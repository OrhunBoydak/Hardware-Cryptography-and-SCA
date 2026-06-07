library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mon_pro_tb is
end mon_pro_tb;

architecture Behavioral of mon_pro_tb is

    component mon_pro is
        Generic ( DATA_WIDTH : integer );
        Port (
            clk     : in  std_logic;
            rst     : in  std_logic;
            start   : in  std_logic;
            a_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            b_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            n_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            result  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            done    : out std_logic
        );
    end component;

    constant WIDTH : integer := 32;
    
    signal clk   : std_logic := '0';
    signal rst   : std_logic := '0';
    signal start : std_logic := '0';
    signal a_in, b_in, n_in : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal result : std_logic_vector(WIDTH-1 downto 0);
    signal done   : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    uut: mon_pro
        generic map (DATA_WIDTH => WIDTH)
        port map (
            clk => clk, rst => rst, start => start,
            a_in => a_in, b_in => b_in, n_in => n_in,
            result => result, done => done
        );

    process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    process
    begin
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;
        
        a_in <= x"00000004"; 
        b_in <= x"00000008"; 
        n_in <= x"0000001D";
        

        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        
        wait until done = '1';
        wait for 20 ns;
        
        assert false report "Simulasyon Bitti" severity failure;
    end process;

end Behavioral;