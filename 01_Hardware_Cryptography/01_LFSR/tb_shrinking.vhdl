library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_shrinking is
end tb_shrinking;

architecture Behavioral of tb_shrinking is
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal stream_out : std_logic;
    signal valid_out : std_logic;
    
    constant CLK_PERIOD : time := 10 ns;
begin

    -- Ana modülü çağır
    uut: entity work.shrinking_gen
        port map (
            clk => clk,
            rst => rst,
            stream_out => stream_out,
            valid_out => valid_out
        );

    -- Saat Sinyali Üretimi
    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Stimulus (Test Senaryosu)
    stim_proc: process
    begin
        rst <= '1'; -- Resetle başla
        wait for 20 ns;
        rst <= '0'; -- Çalıştır
        
        wait for 5000 ns; -- 5 mikrosaniye simüle et
        wait;
    end process;

end Behavioral;