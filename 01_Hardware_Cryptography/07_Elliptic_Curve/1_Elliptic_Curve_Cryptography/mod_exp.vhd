library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mod_exp is
    Generic (
        DATA_WIDTH : integer := 32
    );
    Port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        start_value : in std_logic_vector(DATA_WIDTH-1 downto 0);
        base    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        exp     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        modulus : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        result  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        done    : out std_logic
    );
end mod_exp;

architecture Behavioral of mod_exp is

    component mon_pro is
        Generic ( DATA_WIDTH : integer );
        Port (
            clk     : in  std_logic;
            rst     : in  std_logic;
            start   : in  std_logic;
            a_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            b_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            n_in    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            result  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            done    : out std_logic
        );
    end component;

    type state_type is (IDLE, PREPARE, 
                        START_SQUARE, WAIT_SQUARE, 
                        START_MULT, WAIT_MULT, 
                        START_FINAL, WAIT_FINAL,
                        FINISH);
    signal state : state_type;

    signal r_base    : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal r_exp     : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal r_mod     : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal r_result  : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    signal bit_count : integer range 0 to DATA_WIDTH-1;

    signal mp_start  : std_logic := '0';
    signal mp_a      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mp_b      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mp_result : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mp_done   : std_logic;

begin

    inst_mon_pro: mon_pro
        generic map (DATA_WIDTH => DATA_WIDTH)
        port map (
            clk     => clk,
            rst     => rst,
            start   => mp_start,
            a_in    => mp_a,
            b_in    => mp_b,
            n_in    => r_mod,
            result  => mp_result,
            done    => mp_done
        );

    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            r_result <= (others => '0');
            done <= '0';
            mp_start <= '0';
            
        elsif rising_edge(clk) then
            case state is
                
                when IDLE =>
                    done <= '0';
                    mp_start <= '0';
                    if start = '1' then
                        r_base   <= base;
                        r_exp    <= exp;
                        r_mod    <= modulus;
                        
                        -- NOT: Tam RSA implementasyonunda buraya da bir ön işlem (Pre-Computation) gerekir.
                        -- Girdileri Montgomery domain'e çevirmek için (A * R^2 mod N) yapılır.
                        -- Basitlik adına şimdilik R mod N varsayımıyla devam ediyoruz.
                        r_result <= start_value;
                        
                        bit_count <= DATA_WIDTH - 1; 
                        state <= START_SQUARE;
                    end if;

                when START_SQUARE =>
                    mp_a <= r_result;
                    mp_b <= r_result;
                    mp_start <= '1'; 
                    state <= WAIT_SQUARE;

                when WAIT_SQUARE =>
                    mp_start <= '0'; 
                    if mp_done = '1' then
                        r_result <= mp_result; 
                        
                        if r_exp(bit_count) = '1' then
                            state <= START_MULT;
                        else
                            if bit_count = 0 then
                                state <= START_FINAL;
                            else
                                bit_count <= bit_count - 1;
                                state <= START_SQUARE;
                            end if;
                        end if;
                    end if;

                when START_MULT =>
                    mp_a <= r_result;
                    mp_b <= r_base;
                    mp_start <= '1';
                    state <= WAIT_MULT;

                when WAIT_MULT =>
                    mp_start <= '0';
                    if mp_done = '1' then
                        r_result <= mp_result;
                        
                        if bit_count = 0 then
                            state <= START_FINAL;
                        else
                            bit_count <= bit_count - 1;
                            state <= START_SQUARE;
                        end if;
                    end if;

                -- İşlem: Result = MonPro(Result, 1)
                when START_FINAL =>
                    mp_a <= r_result;
                    mp_b <= std_logic_vector(to_unsigned(1, DATA_WIDTH));
                    mp_start <= '1';
                    state <= WAIT_FINAL;

                when WAIT_FINAL =>
                    mp_start <= '0';
                    if mp_done = '1' then
                        r_result <= mp_result;
                        state <= FINISH;
                    end if;

                when FINISH =>
                    done <= '1';
                    state <= IDLE;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;
    
    result <= r_result;

end Behavioral;