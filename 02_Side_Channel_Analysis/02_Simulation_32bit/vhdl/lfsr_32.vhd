library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lfsr_32 is
    Port ( clk    : in  STD_LOGIC;
           reset  : in  STD_LOGIC;
           en     : in  STD_LOGIC;
           q      : out STD_LOGIC_VECTOR (31 downto 0));
end lfsr_32;

architecture Behavioral of lfsr_32 is
    signal lfsr_reg : std_logic_vector(31 downto 0);
    signal feedback : std_logic;
begin
    -- Polynomial: x^32 + x^22 + x^2 + x + 1 
    -- Taps (zero-indexed): 31, 21, 1, 0
    feedback <= lfsr_reg(31) xor lfsr_reg(21) xor lfsr_reg(1) xor lfsr_reg(0);

    process(clk, reset)
    begin
        if reset = '1' then
            lfsr_reg <= x"00000001"; -- Non-zero initial state
        elsif rising_edge(clk) then
            if en = '1' then
                lfsr_reg <= lfsr_reg(30 downto 0) & feedback;
            end if;
        end if;
    end process;

    q <= lfsr_reg;
end Behavioral;
