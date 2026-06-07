library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mon_pro is
    Generic (
        DATA_WIDTH : integer := 32
    );
    Port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        
        -- Girdiler
        a_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        b_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        n_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        
        -- Çıktı
        result  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        done    : out std_logic
    );
end mon_pro;

architecture Behavioral of mon_pro is

    type state_type is (IDLE, ADD_SHIFT, FIX_RESULT, FINISH);
    signal state : state_type;

    -- Registers
    signal r_a    : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal r_b    : unsigned(DATA_WIDTH downto 0);
    signal r_n    : unsigned(DATA_WIDTH downto 0);
    
    -- Toplama işleminin yapıldığı yer
    signal r_acc  : unsigned(DATA_WIDTH+2 downto 0);
    
    -- Sayaç
    signal bit_cnt : integer range 0 to DATA_WIDTH;

begin

    process(clk, rst)
        variable v_sum : unsigned(DATA_WIDTH+2 downto 0);
    begin
        if rst = '1' then
            state <= IDLE;
            r_acc <= (others => '0');
            done  <= '0';
            result <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        r_a <= a_in;
                        r_b <= resize(unsigned(b_in), DATA_WIDTH + 1);
                        r_n <= resize(unsigned(n_in), DATA_WIDTH + 1);
                        r_acc <= (others => '0');
                        bit_cnt <= 0;
                        state <= ADD_SHIFT;
                    end if;

                when ADD_SHIFT =>
                    v_sum := r_acc;
                    
                    if r_a(bit_cnt) = '1' then
                        v_sum := v_sum + r_b;
                    end if;
                    
                    if v_sum(0) = '1' then
                        v_sum := v_sum + r_n;
                    end if;
                    
                    r_acc <= v_sum srl 1; 
                    
                    if bit_cnt = DATA_WIDTH - 1 then
                        state <= FIX_RESULT;
                    else
                        bit_cnt <= bit_cnt + 1;
                    end if;

                when FIX_RESULT =>
                    if r_acc >= r_n then
                        r_acc <= r_acc - r_n;
                    end if;
                    state <= FINISH;

                when FINISH =>
                    result <= std_logic_vector(resize(r_acc, DATA_WIDTH));
                    done <= '1';
                    state <= IDLE;
                    
            end case;
        end if;
    end process;

end Behavioral;