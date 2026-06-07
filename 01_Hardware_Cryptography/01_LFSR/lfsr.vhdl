library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lfsr is
    Generic (
        WIDTH : integer := 64;           -- LFSR bit genişliği
        TAP_MASK : std_logic_vector      -- Polinom Tap noktaları (Maske)
    );
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        out_bit : out STD_LOGIC          -- LFSR'den çıkan tek bit (MSB)
    );
end lfsr;

architecture Behavioral of lfsr is
    -- Başlangıç değeri (Seed) sıfır olmamalıdır!
    signal r_reg : std_logic_vector(WIDTH-1 downto 0) := (0 => '1', others => '0');
    signal feedback : std_logic;
begin

    -- Geri besleme (Feedback) mantığı:
    -- Maskelenmiş bitlerin hepsini XOR işlemine tabi tutar.
    process(r_reg)
        variable v_xor : std_logic;
    begin
        v_xor := '0';
        for i in 0 to WIDTH-1 loop
            if TAP_MASK(i) = '1' then
                v_xor := v_xor xor r_reg(i);
            end if;
        end loop;
        feedback <= v_xor;
    end process;

    process(clk, rst)
    begin
        if rst = '1' then
            r_reg <= (0 => '1', others => '0'); -- Reset durumunda seed yükle
        elsif rising_edge(clk) then
            -- Fibonacci LFSR: Sola kaydır, en sağa feedback'i koy
            r_reg <= r_reg(WIDTH-2 downto 0) & feedback;
        end if;
    end process;

    -- Çıkış olarak en soldaki biti (MSB) veriyoruz
    out_bit <= r_reg(WIDTH-1);

end Behavioral;