library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mod_exp is
    Generic (
        DATA_WIDTH : integer := 32  -- 32 bit
    );
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
end mod_exp;

architecture Behavioral of mod_exp is

    type state_type is (IDLE, SQUARE, MULTIPLY, FINISH);
    signal state : state_type;

    signal r_base    : unsigned(DATA_WIDTH-1 downto 0);
    signal r_exp     : unsigned(DATA_WIDTH-1 downto 0);
    signal r_mod     : unsigned(DATA_WIDTH-1 downto 0);
    signal r_result  : unsigned(DATA_WIDTH-1 downto 0);
    
    -- Bit sayacı
    signal bit_count : integer range 0 to DATA_WIDTH-1;

begin

    process(clk, rst)
        variable v_product : unsigned(2*DATA_WIDTH-1 downto 0);
    begin
        if rst = '1' then
            state <= IDLE;
            r_result <= (others => '0');
            done <= '0';
            bit_count <= DATA_WIDTH - 1;
        
        elsif rising_edge(clk) then
            case state is
                
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        r_base   <= unsigned(base);
                        r_exp    <= unsigned(exp);
                        r_mod    <= unsigned(modulus);
                        r_result <= to_unsigned(1, DATA_WIDTH);
                        bit_count <= DATA_WIDTH - 1;
                        state <= SQUARE;
                    end if;

                when SQUARE =>
                    v_product := r_result * r_result;
                    r_result  <= resize(v_product mod r_mod, DATA_WIDTH);
                    
                    state <= MULTIPLY;

                when MULTIPLY =>
                    if r_exp(bit_count) = '1' then
                        v_product := r_result * r_base;
                        r_result  <= resize(v_product mod r_mod, DATA_WIDTH);
                    end if;
                    
                    if bit_count = 0 then
                        state <= FINISH;
                    else
                        bit_count <= bit_count - 1;
                        state <= SQUARE;
                    end if;

                when FINISH =>
                    done <= '1';
                    state <= IDLE;

            end case;
        end if;
    end process;
    
    result <= std_logic_vector(r_result);

end Behavioral;