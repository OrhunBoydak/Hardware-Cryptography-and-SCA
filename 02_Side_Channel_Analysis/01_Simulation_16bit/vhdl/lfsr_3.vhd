library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lfsr_3 is
    Port ( clk    : in  STD_LOGIC;
           reset  : in  STD_LOGIC;
           en     : in  STD_LOGIC;
           q      : out STD_LOGIC_VECTOR (2 downto 0));
end lfsr_3;

architecture Behavioral of lfsr_3 is
    signal lfsr_reg : std_logic_vector(2 downto 0);
    signal feedback : std_logic;
begin
    -- Feedback polynomial: x^3 + x^2 + 1 -> Taps at 2 and 1
    feedback <= lfsr_reg(2) xor lfsr_reg(1);

    process(clk, reset)
    begin
        if reset = '1' then
            lfsr_reg <= "001"; -- Initial state must be non-zero
        elsif rising_edge(clk) then
            if en = '1' then
                lfsr_reg <= lfsr_reg(1 downto 0) & feedback;
            end if;
        end if;
    end process;

    q <= lfsr_reg;
end Behavioral;
