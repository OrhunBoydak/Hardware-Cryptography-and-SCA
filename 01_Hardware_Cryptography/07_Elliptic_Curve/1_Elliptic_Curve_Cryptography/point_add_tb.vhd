library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity point_add_tb is
-- Testbench'in portu olmaz
end point_add_tb;

architecture Behavioral of point_add_tb is

    -- Bileşen Tanımı (UUT)
    component point_add is
        Generic ( WIDTH : integer := 32 );
        Port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            start    : in  std_logic;
            p1_x, p1_y : in  std_logic_vector(31 downto 0);
            p2_x, p2_y : in  std_logic_vector(31 downto 0);
            modulus    : in  std_logic_vector(31 downto 0);
            res_x, res_y : out std_logic_vector(31 downto 0);
            done       : out std_logic
        );
    end component;

    -- Sinyaller
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '0';
    signal start    : std_logic := '0';
    signal p1_x     : std_logic_vector(31 downto 0) := (others => '0');
    signal p1_y     : std_logic_vector(31 downto 0) := (others => '0');
    signal p2_x     : std_logic_vector(31 downto 0) := (others => '0');
    signal p2_y     : std_logic_vector(31 downto 0) := (others => '0');
    signal modulus  : std_logic_vector(31 downto 0) := (others => '0');
    signal res_x    : std_logic_vector(31 downto 0);
    signal res_y    : std_logic_vector(31 downto 0);
    signal done     : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- UUT Bağlantısı
    uut: point_add
        generic map (WIDTH => 32)
        port map (
            clk => clk, rst => rst, start => start,
            p1_x => p1_x, p1_y => p1_y,
            p2_x => p2_x, p2_y => p2_y,
            modulus => modulus,
            res_x => res_x, res_y => res_y,
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
        -- 1. Reset
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 10 ns;

        -- 2. Verileri Yükle (P(5,1) + Q(6,3) mod 17)
        p1_x <= std_logic_vector(to_unsigned(5, 32));
        p1_y <= std_logic_vector(to_unsigned(1, 32));
        p2_x <= std_logic_vector(to_unsigned(6, 32));
        p2_y <= std_logic_vector(to_unsigned(3, 32));
        modulus <= std_logic_vector(to_unsigned(17, 32));
        
        -- 3. Başlat
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        -- 4. Bitişi Bekle
        wait until done = '1';
        
        -- 5. Sonucu Gözlemle
        wait for 20 ns;
        
        -- Simülasyonu bitir
        assert false report "Simülasyon Bitti. WaveTrace'den (10, 6) sonucunu kontrol et!" severity failure;
    end process;

end Behavioral;