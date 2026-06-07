library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mod_exp_tb is
end mod_exp_tb;

architecture Behavioral of mod_exp_tb is
    
    component mod_exp is
        Generic ( DATA_WIDTH : integer );
        Port (
            clk     : in  std_logic;
            rst     : in  std_logic;
            start   : in  std_logic;
            base    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            exp     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            modulus : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            result  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            done    : out std_logic
        );
    end component;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '0';
    signal start   : std_logic := '0';
    
    signal base    : std_logic_vector(31 downto 0) := (others => '0');
    signal exp     : std_logic_vector(31 downto 0) := (others => '0');
    signal modulus : std_logic_vector(31 downto 0) := (others => '0');
    signal result  : std_logic_vector(31 downto 0);
    
    signal done    : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    uut: mod_exp 
        generic map (DATA_WIDTH => 32)
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
        wait for 10 ns;
        base    <= x"12345678";
        exp     <= x"00010001";
        modulus <= x"ABCDEF01";
        
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        wait until done = '1';
        
        wait for 20 ns;
        
        -- Python ile hesaplanan beklenen değer: 05BA8EE8
        if result = x"05BA8EE8" then
            report "BASARILI: 32-bit RSA islemi dogru calisti!" severity note;
        else
            report "HATA: Sonuc yanlis! Beklenen: 05BA8EE8, Gelen: " & integer'image(to_integer(unsigned(result))) severity error;
        end if;
        
        assert false report "Simülasyon Tamamlandi." severity failure;
    end process;

end Behavioral;