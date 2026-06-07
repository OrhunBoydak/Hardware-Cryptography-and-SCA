library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity shrinking_gen is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        stream_out : out STD_LOGIC; -- Üretilen şifreli bit
        valid_out  : out STD_LOGIC  -- Çıktının geçerli olduğu anı gösterir
    );
end shrinking_gen;

architecture Behavioral of shrinking_gen is

    component lfsr is
        Generic ( WIDTH : integer; TAP_MASK : std_logic_vector );
        Port ( clk, rst : in STD_LOGIC; out_bit : out STD_LOGIC );
    end component;

    signal bit_A_select : std_logic; -- 64-bit LFSR çıktısı (Seçici)
    signal bit_B_data   : std_logic; -- 63-bit LFSR çıktısı (Veri)

    -- TAP MASKELERİ (Polinom Ayarları)
    -- 64-bit Polinom: x^64 + x^4 + x^3 + x + 1 -> Tapler: 63, 3, 2, 0 (0-indexli)
    constant TAPS_64 : std_logic_vector(63 downto 0) := (63|3|2|0 => '1', others => '0');
    
    -- 63-bit Polinom: x^63 + x + 1 -> Tapler: 62, 0 (0-indexli)
    constant TAPS_63 : std_logic_vector(62 downto 0) := (62|0 => '1', others => '0');

begin

    -- LFSR A (64-Bit) - Seçici (Selector)
    LFSR_A: lfsr 
    generic map ( WIDTH => 64, TAP_MASK => TAPS_64 )
    port map ( clk => clk, rst => rst, out_bit => bit_A_select );

    -- LFSR B (63-Bit) - Veri (Generator)
    LFSR_B: lfsr 
    generic map ( WIDTH => 63, TAP_MASK => TAPS_63 )
    port map ( clk => clk, rst => rst, out_bit => bit_B_data );

    -- SHRINKING GENERATOR MANTIĞI
    process(clk, rst)
    begin
        if rst = '1' then
            stream_out <= '0';
            valid_out <= '0';
        elsif rising_edge(clk) then
            if bit_A_select = '1' then
                stream_out <= bit_B_data; -- A '1' ise B'yi geçir
                valid_out <= '1';         -- Bu veri geçerlidir
            else
                valid_out <= '0';         -- A '0' ise çıktı üretme (Shrink et)
            end if;
        end if;
    end process;

end Behavioral;