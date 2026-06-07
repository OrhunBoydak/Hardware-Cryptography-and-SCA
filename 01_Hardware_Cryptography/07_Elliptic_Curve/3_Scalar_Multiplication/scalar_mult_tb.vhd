library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity scalar_mult_tb is
-- Testbench port içermez
end scalar_mult_tb;

architecture Behavioral of scalar_mult_tb is

    -- Bileşen Tanımı
    component scalar_mult is
        Generic ( WIDTH : integer := 32 );
        Port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            start    : in  std_logic;
            k        : in  std_logic_vector(31 downto 0);
            p_x, p_y : in  std_logic_vector(31 downto 0);
            a_param  : in  std_logic_vector(31 downto 0);
            modulus  : in  std_logic_vector(31 downto 0);
            res_x, res_y : out std_logic_vector(31 downto 0);
            done     : out std_logic
        );
    end component;

    -- Sinyaller
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '0';
    signal start    : std_logic := '0';
    signal k        : std_logic_vector(31 downto 0) := (others => '0');
    signal p_x, p_y : std_logic_vector(31 downto 0) := (others => '0');
    signal a_param  : std_logic_vector(31 downto 0) := (others => '0');
    signal modulus  : std_logic_vector(31 downto 0) := (others => '0');
    signal res_x, res_y : std_logic_vector(31 downto 0);
    signal done     : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- UUT Bağlantısı
    uut: scalar_mult
        generic map (WIDTH => 32)
        port map (
            clk => clk, rst => rst, start => start,
            k => k, p_x => p_x, p_y => p_y,
            a_param => a_param, modulus => modulus,
            res_x => res_x, res_y => res_y,
            done => done
        );

    -- Saat Üretimi
    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Test Senaryosu
    stim_proc: process
    begin
        -- 1. Reset
        rst <= '1';
        wait for 50 ns;
        rst <= '0';
        wait for 50 ns;

        -- 2. Parametreleri Yükle (k=3, P=(5,1), a=2, p=17)
        -- Beklenen Sonuç: 2P=(6,3) -> 3P = 2P+P = (10,6)
        k <= std_logic_vector(to_unsigned(3, 32));
        p_x <= std_logic_vector(to_unsigned(5, 32));
        p_y <= std_logic_vector(to_unsigned(1, 32));
        a_param <= std_logic_vector(to_unsigned(2, 32));
        modulus <= std_logic_vector(to_unsigned(17, 32));
        
        -- 3. Başlat
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        -- 4. Bitişi Bekle (Bu işlem birkaç yüz saat vuruşu sürebilir)
        wait until done = '1';
        
        -- 5. Gözlem
        wait for 100 ns;
        
        assert false report "Simülasyon Bitti. Sonuç (10, 6) olmalı!" severity failure;
    end process;

end Behavioral;