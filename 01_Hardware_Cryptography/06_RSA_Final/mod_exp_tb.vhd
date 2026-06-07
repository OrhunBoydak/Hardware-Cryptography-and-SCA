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
            start_value : in  std_logic_vector(DATA_WIDTH-1 downto 0);
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
    signal start_value : std_logic_vector(31 downto 0) := (others => '0');
    
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
            start_value => start_value,
            base => base,
            exp => exp,
            modulus => modulus,
            result => result,
            done => done
        );

    -- Clock Process
    process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Test Senaryosu
    process
    begin
        -- 1. Reset
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 10 ns;

        -- 2. Verileri Yükle (32 Bit Hex)
        start_value <= x"543210FF";
        base    <= x"7130D396";
        exp     <= x"00010001";  -- 65537
        modulus <= x"ABCDEF01";
        
        -- 3. Başlat
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        -- 4. Bitişi Bekle
        wait until done = '1';
        
        -- 5. Sonucu Kontrol Et
        wait for 20 ns;
        
        if result = x"05BA8EE8" then
            report "BASARILI: 32-bit RSA islemi dogru calisti! (Final Version)" severity note;
        else
            report "HATA: Sonuc beklenen deger degil!" severity error;
        end if;
        
        -- Simülasyonu Durdur
        assert false report "Simulasyon Tamamlandi." severity failure;
    end process;

end Behavioral;